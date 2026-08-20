import Combine
import CoreLocation
import CoreMotion
import Foundation

/// Live camera look direction: true azimuth (0 = north) and elevation (0 = horizon, 90 = zenith).
final class CameraLookTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var azimuth: Double?
    @Published var elevation: Double?
    @Published var headingAccuracy: CLLocationDirection = -1

    private let motion = CMMotionManager()
    private let location = CLLocationManager()
    private let queue = OperationQueue()

    override init() {
        super.init()
        queue.name = "overhead.camera.motion"
        queue.maxConcurrentOperationCount = 1
        location.delegate = self
        location.headingFilter = 1
        location.headingOrientation = .portrait
    }

    func start() {
        location.startUpdatingHeading()
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        let frame: CMAttitudeReferenceFrame = CMMotionManager.availableAttitudeReferenceFrames()
            .contains(.xTrueNorthZVertical) ? .xTrueNorthZVertical : .xMagneticNorthZVertical
        motion.startDeviceMotionUpdates(using: frame, to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            let look = Self.cameraLook(from: data.attitude.rotationMatrix)
            DispatchQueue.main.async {
                self.azimuth = look.azimuth
                self.elevation = look.elevation
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        location.stopUpdatingHeading()
    }

    /// Back-camera look vector in a Z-up, X-north (or magnetic north) frame.
    private static func cameraLook(from r: CMRotationMatrix) -> (azimuth: Double, elevation: Double) {
        let dx = 0.0, dy = 0.0, dz = -1.0
        let wx = r.m11 * dx + r.m12 * dy + r.m13 * dz
        let wy = r.m21 * dx + r.m22 * dy + r.m23 * dz
        let wz = r.m31 * dx + r.m32 * dy + r.m33 * dz
        let horiz = hypot(wx, wy)
        let elevation = atan2(wz, max(horiz, 0.0001)) * 180 / .pi
        var azimuth = atan2(wy, wx) * 180 / .pi
        if azimuth < 0 { azimuth += 360 }
        return (azimuth, elevation)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingAccuracy = newHeading.trueHeading >= 0 ? newHeading.headingAccuracy : newHeading.magneticHeading
        // Motion attitude is preferred; heading fills in if motion never arrives.
        if azimuth == nil {
            let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            if heading >= 0 { azimuth = heading }
        }
    }
}
