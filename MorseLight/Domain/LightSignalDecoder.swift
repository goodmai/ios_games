import Foundation

/// Decodes Morse from a per-frame brightness timeline (e.g. mean luminance of a
/// torch region sampled by the camera). Thresholds brightness into on/off spans,
/// then defers to `MorseSegmentDecoder` for unit calibration and text — so the
/// Morse timing logic is never duplicated between the audio and light paths.
struct LightSignalDecoder: Sendable {

    var language: MorseLanguage = .english
    var brightnessThreshold: Float = 0.5       // 0…1 normalized luminance
    var minSegmentDuration: TimeInterval = 0.020

    /// - Parameters:
    ///   - brightness: normalized luminance per frame.
    ///   - frameRate: capture rate in frames per second.
    func decode(brightness: [Float], frameRate: Double) -> String {
        guard frameRate > 0 else { return "" }
        let segments = segments(brightness: brightness, frameRate: frameRate)
        var decoder = MorseSegmentDecoder()
        decoder.language = language
        return decoder.text(from: segments)
    }

    private func segments(brightness: [Float], frameRate: Double) -> [MorseSegment] {
        let frameDuration = 1.0 / frameRate
        var segments: [MorseSegment] = []

        var currentIsOn = false
        var frames = 0
        var started = false

        func flush() {
            let dur = Double(frames) * frameDuration
            if frames > 0 && dur >= minSegmentDuration {
                segments.append(MorseSegment(isOn: currentIsOn, duration: dur))
            }
        }

        for sample in brightness {
            let isOn = sample >= brightnessThreshold
            if !started {
                currentIsOn = isOn
                frames = 1
                started = true
            } else if isOn != currentIsOn {
                flush()
                currentIsOn = isOn
                frames = 1
            } else {
                frames += 1
            }
        }
        if started { flush() }
        return segments
    }
}
</content>
