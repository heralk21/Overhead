import AVFoundation
import SwiftUI
import UIKit

/// Live back-camera preview. Reports horizontal FOV for sky projection.
struct CameraPreviewView: UIViewRepresentable {
    @Binding var fieldOfView: Double
    @Binding var cameraReady: Bool
    @Binding var cameraError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        private let parent: CameraPreviewView
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "overhead.camera.session")
        private weak var preview: PreviewView?

        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }

        func attach(to view: PreviewView) {
            preview = view
            view.previewLayer.session = session
            view.previewLayer.videoGravity = .resizeAspectFill
            requestAndStart()
        }

        func stop() {
            sessionQueue.async { [session] in
                if session.isRunning { session.stopRunning() }
            }
        }

        private func requestAndStart() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                configureAndRun()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                    DispatchQueue.main.async {
                        if ok { self?.configureAndRun() }
                        else { self?.fail("Camera access denied. Enable it in Settings to scan aircraft.") }
                    }
                }
            default:
                fail("Camera access denied. Enable it in Settings to scan aircraft.")
            }
        }

        private func configureAndRun() {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                self.session.beginConfiguration()
                self.session.sessionPreset = .high
                self.session.inputs.forEach { self.session.removeInput($0) }

                guard let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: .back
                ) else {
                    DispatchQueue.main.async { self.fail("No camera available on this device.") }
                    self.session.commitConfiguration()
                    return
                }

                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if self.session.canAddInput(input) { self.session.addInput(input) }
                } catch {
                    DispatchQueue.main.async { self.fail("Could not start the camera.") }
                    self.session.commitConfiguration()
                    return
                }

                let fov = Double(device.activeFormat.videoFieldOfView)
                self.session.commitConfiguration()
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.parent.fieldOfView = fov > 10 ? fov : 62
                    self.parent.cameraReady = true
                    self.parent.cameraError = nil
                }
            }
        }

        private func fail(_ message: String) {
            parent.cameraReady = false
            parent.cameraError = message
        }
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
