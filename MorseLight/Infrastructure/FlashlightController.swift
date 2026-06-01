import AVFoundation

final class FlashlightController: @unchecked Sendable {

    var isAvailable: Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.hasTorch && device.isTorchAvailable
    }

    var isOn: Bool {
        AVCaptureDevice.default(for: .video)?.torchMode == .on
    }

    func setOn(_ on: Bool, level: Float = AVCaptureDevice.maxAvailableTorchLevel) throws {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        if on {
            try device.setTorchModeOn(level: max(0.01, min(1.0, level)))
        } else {
            device.torchMode = .off
        }
    }

    func turnOff() { try? setOn(false) }
}
