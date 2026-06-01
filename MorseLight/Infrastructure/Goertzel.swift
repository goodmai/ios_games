import Foundation

/// Single-frequency Goertzel power estimator.
///
/// Returns power normalized by N² so the result is independent of window length,
/// letting callers threshold against a fixed energy floor. Shared by
/// `MorseAudioDecoder` (fixed-tone detection) and `FrequencyPeakDetector`
/// (band sweep) to avoid duplicated DSP.
enum Goertzel {

    static func power(_ slice: ArraySlice<Float>, freq: Double, sampleRate: Double) -> Float {
        let n = slice.count
        guard n > 0, sampleRate > 0 else { return 0 }

        let k = (Double(n) * freq / sampleRate).rounded()
        let coeff = Float(2.0 * cos(2.0 * .pi * k / Double(n)))

        var s1: Float = 0
        var s2: Float = 0
        for x in slice {
            let s0 = x + coeff * s1 - s2
            s2 = s1
            s1 = s0
        }

        let power = s1 * s1 + s2 * s2 - coeff * s1 * s2
        return power / Float(n * n)
    }
}
</content>
