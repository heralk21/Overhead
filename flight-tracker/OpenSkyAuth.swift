import Foundation

/// OAuth2 client-credentials tokens for OpenSky `/flights/*` (4,000 credits/day when configured).
/// Credentials: `Config/Secrets.xcconfig` → OPEN_SKY_CLIENT_ID / OPEN_SKY_CLIENT_SECRET
actor OpenSkyAuth {
    static let shared = OpenSkyAuth()

    private static let tokenURL = URL(string:
        "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token")!

    private var accessToken: String?
    private var expiresAt: Date?

    /// Bearer token when credentials are set; `nil` when empty (anonymous fallback).
    func bearerToken() async throws -> String? {
        let id = APIConfiguration.openSkyClientID
        let secret = APIConfiguration.openSkyClientSecret
        guard !id.isEmpty, !secret.isEmpty else { return nil }

        if let token = accessToken, let expiry = expiresAt, Date() < expiry {
            return token
        }

        var req = URLRequest(url: Self.tokenURL, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "grant_type=client_credentials&client_id=\(id)&client_secret=\(secret)"
        req.httpBody = body.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            accessToken = nil
            expiresAt = nil
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else { return nil }

        let lifetime = (json["expires_in"] as? Double) ?? 1800
        accessToken = token
        expiresAt = Date().addingTimeInterval(lifetime - 60) // refresh 1 min early

        return token
    }
}
