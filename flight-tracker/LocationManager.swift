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
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // low accuracy = faster + less battery
        authStatus = manager.authorizationStatus
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
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation() // one-shot, stops automatically
        @unknown default:
            onError("Unknown location status.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        onLocation?(location)
        onLocation = nil
        onError = nil
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?("Location error: \(error.localizedDescription)")
        onLocation = nil
        onError = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            if onLocation != nil {
                manager.requestLocation()
            }
        }
    }
}
