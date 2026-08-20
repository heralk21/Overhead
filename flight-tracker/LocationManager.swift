import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var onLocation: ((CLLocation) -> Void)?
    private var onError: ((String) -> Void)?
    private var timeoutWork: DispatchWorkItem?
    private var didDeliver = false

    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
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
        timeoutWork?.cancel()
        didDeliver = false
        self.onLocation = onLocation
        self.onError = onError

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            onError("Location access denied. Enable it in Settings to use your position.")
            finish()
        case .authorizedWhenInUse, .authorizedAlways:
            startFix()
        @unknown default:
            onError("Unknown location status.")
            finish()
        }
    }

    private func startFix() {
        if let loc = manager.location {
            deliver(loc, stop: false)
        }
        manager.startUpdatingLocation()
        manager.requestLocation()
        timeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.timedOut()
        }
        timeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: work)
    }

    private func deliver(_ location: CLLocation, stop: Bool) {
        SharedWidgetLocation.save(location)
        onLocation?(location)
        didDeliver = true
        if stop {
            finish()
        }
    }

    private func timedOut() {
        manager.stopUpdatingLocation()
        if didDeliver {
            finish()
            return
        }
        onError?("Couldn’t find your location. Try again.")
        finish()
    }

    private func finish() {
        timeoutWork?.cancel()
        timeoutWork = nil
        manager.stopUpdatingLocation()
        onLocation = nil
        onError = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        deliver(location, stop: true)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let ns = error as NSError
        if ns.domain == kCLErrorDomain {
            switch ns.code {
            case CLError.locationUnknown.rawValue, CLError.network.rawValue:
                return
            default:
                break
            }
        }
        if didDeliver { return }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if onLocation != nil {
                startFix()
            }
        case .denied, .restricted:
            if let onError {
                onError("Location access denied. Enable it in Settings to use your position.")
                finish()
            }
        default:
            break
        }
    }
}
