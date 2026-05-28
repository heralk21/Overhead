import Foundation
import Combine

class FlightService: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var isLoading = false
    @Published var lastUpdate: Date?
    @Published var errorMessage: String?
    @Published var locationName: String = "Your Location"

    func fetchFlights(latitude: Double, longitude: Double, radiusKm: Double = 50.0) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let latOffset = radiusKm / 111.0
        let lonOffset = radiusKm / (111.0 * cos(latitude * .pi / 180))
        let lamin = latitude - latOffset
        let lamax = latitude + latOffset
        let lomin = longitude - lonOffset
        let lomax = longitude + lonOffset

        let urlString = "https://opensky-network.org/api/states/all?lamin=\(lamin)&lamax=\(lamax)&lomin=\(lomin)&lomax=\(lomax)"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let states = json["states"] as? [[Any]] {
                        var newFlights: [Flight] = []
                        for state in states {
                            guard state.count > 10,
                                  let callsign = state[1] as? String,
                                  !callsign.trimmingCharacters(in: .whitespaces).isEmpty,
                                  let lat = state[6] as? Double,
                                  let lon = state[5] as? Double,
                                  let altitude = state[7] as? Double,
                                  let velocity = state[9] as? Double,
                                  let heading = state[10] as? Double,
                                  let icao24 = state[0] as? String else { continue }
                            newFlights.append(Flight(
                                callsign: callsign.trimmingCharacters(in: .whitespaces),
                                latitude: lat,
                                longitude: lon,
                                altitude: Int(altitude),
                                velocity: velocity,
                                heading: heading,
                                icao24: icao24
                            ))
                        }
                        self.flights = newFlights.sorted { $0.altitude > $1.altitude }
                        self.lastUpdate = Date()
                    } else {
                        self.errorMessage = "Unexpected data format"
                    }
                } catch {
                    self.errorMessage = "Parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
