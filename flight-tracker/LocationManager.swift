import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var onLocation: ((CLLocation) -> Void)?
    private var onError: ((String) -> Void)?

    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authStatus = manager.authorizationStatus
    }

    /// Last system location if it is recent enough to use without waiting for GPS.
    func recentLocation(maxAge: TimeInterval = 900) -> CLLocation? {
        guard let loc = manager.location else { return nil }
        guard abs(loc.timestamp.timeIntervalSinceNow) < maxAge else { return nil }
        return loc
    }

    func requestOnce(
        onLocation: @escaping (CLLocation) -> Void,
        onError: @escaping (String) -> Void
    ) {
        self.onLocation = onLocation
        self.onError = onError

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            onError("Location access denied. Enable it in Settings to use your position.")
            self.onLocation = nil
            self.onError = nil
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            onError("Unknown location status.")
            self.onLocation = nil
            self.onError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        SharedWidgetLocation.save(location)
        onLocation?(location)
        onLocation = nil
        onError = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?("Location error: \(error.localizedDescription)")
        onLocation = nil
        onError = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if onLocation != nil {
                manager.requestLocation()
            }
        case .denied, .restricted:
            if let onError {
                onError("Location access denied. Enable it in Settings to use your position.")
                self.onLocation = nil
                self.onError = nil
            }
        default:
            break
        }
    }
}
