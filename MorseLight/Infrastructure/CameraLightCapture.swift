import AVFoundation
import CoreVideo
import Foundation

/// Captures camera frames and records the mean luminance of each frame, building
/// the brightness timeline that `LightSignalDecoder` turns into text (Epic E3).
///
/// The `AVCaptureVideoDataOutput` delegate API requires a `DispatchQueue` callback
/// target — there is no `async` equivalent — so a dedicated sample queue is used
/// here at the framework boundary; all decoded results are delivered back on the
/// main actor.
final class CameraLightCapture: NSObject, @unchecked Sendable {

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sampleQueue = DispatchQueue(label: "com.goodmai.MorseLight.lightCapture")

    private var luminances: [Float] = []
    private var firstTimestamp: CMTime?
    private var lastTimestamp: CMTime?

    var isAvailable: Bool { AVCaptureDevice.default(for: .video) != nil }

    /// The preview-layer session, for `AVCaptureVideoPreviewLayer`.
    var captureSession: AVCaptureSession { session }

    // MARK: Lifecycle

    func start() throws {
        guard !session.isRunning else { return }
        try configureIfNeeded()
        luminances.removeAll(keepingCapacity: true)
        firstTimestamp = nil
        lastTimestamp = nil
        sampleQueue.async { [session] in session.startRunning() }
    }

    /// Stops capture and decodes the accumulated brightness timeline.
    func stopAndDecode(language: MorseLanguage) -> String {
        if session.isRunning { session.stopRunning() }

        let samples = luminances
        guard samples.count > 1,
              let first = firstTimestamp, let last = lastTimestamp,
              last.seconds > first.seconds else { return "" }

        let frameRate = Double(samples.count - 1) / (last.seconds - first.seconds)
        var decoder = LightSignalDecoder()
        decoder.language = language
        return decoder.decode(brightness: samples, frameRate: frameRate)
    }

    // MARK: Configuration

    private func configureIfNeeded() throws {
        guard session.inputs.isEmpty else { return }
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) { session.addInput(input) }

        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
    }
}

extension CameraLightCapture: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let luminance = meanLuminance(of: pixelBuffer)

        if firstTimestamp == nil { firstTimestamp = timestamp }
        lastTimestamp = timestamp
        luminances.append(luminance)
    }

    /// Average of the Y (luma) plane, subsampled for speed, normalized to 0…1.
    private func meanLuminance(of pixelBuffer: CVPixelBuffer) -> Float {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return 0 }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let buffer = base.assumingMemoryBound(to: UInt8.self)

        let rowStep = max(1, height / 32)
        let colStep = max(1, width / 32)
        var sum = 0
        var count = 0
        var row = 0
        while row < height {
            let rowOffset = row * bytesPerRow
            var col = 0
            while col < width {
                sum += Int(buffer[rowOffset + col])
                count += 1
                col += colStep
            }
            row += rowStep
        }
        guard count > 0 else { return 0 }
        return Float(sum) / Float(count) / 255.0
    }
}
</content>
