#if canImport(Vision)
import Vision
import AVFoundation
import Foundation

/// Bridges camera frames to `LightSignalDecoder`. `VNDetectTrajectoriesRequest`
/// locates and tracks the moving/blinking light region; the per-frame mean
/// luminance of that region forms the brightness timeline fed to the decoder.
///
/// Device/CV layer — the decode math is unit-tested in `LightSignalDecoder`;
/// this wrapper is validated by manual capture checks (CV-06).
@available(iOS 17.0, *)
final class VisionFlashDetector {

    private let decoder: LightSignalDecoder
    private let request: VNDetectTrajectoriesRequest

    init(language: MorseLanguage = .english, trajectoryLength: Int = 8) {
        var decoder = LightSignalDecoder()
        decoder.language = language
        self.decoder = decoder
        self.request = VNDetectTrajectoriesRequest(
            frameAnalysisSpacing: .zero,
            trajectoryLength: trajectoryLength
        )
    }

    /// Decode a pre-sampled luminance timeline (e.g. accumulated from the tracked
    /// torch ROI during capture).
    func decode(brightnessTimeline: [Float], frameRate: Double) -> String {
        decoder.decode(brightness: brightnessTimeline, frameRate: frameRate)
    }

    /// Feed a single captured frame into the trajectory tracker. Returns detected
    /// trajectory observations for the caller to sample ROI luminance from.
    func process(_ pixelBuffer: CVPixelBuffer) throws -> [VNTrajectoryObservation] {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([request])
        return request.results ?? []
    }
}
#endif
</content>
