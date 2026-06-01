import Foundation

/// Finds the dominant tone in a narrow band so the decoder can retune off the
/// nominal 700 Hz. Defends against Doppler shift (device in motion) and
/// third-party transmitters whose carrier drifts.
///
/// Measures Goertzel power across the band on the *loudest* window of the signal,
/// so silence and quiet gaps don't bias the estimate toward noise.
struct FrequencyPeakDetector: Sendable {

    var minFrequency: Double = 600.0
    var maxFrequency: Double = 800.0
    var resolution: Double = 5.0          // Hz between candidate bins
    var minPower: Float = 0.0008          // noise floor; below → no confident tone
    var analysisWindow: TimeInterval = 0.05

    /// Returns the strongest in-band frequency, or `nil` if nothing rises above
    /// the noise floor.
    func dominantFrequency(samples: [Float], sampleRate: Double) -> Double? {
        guard !samples.isEmpty, sampleRate > 0, maxFrequency > minFrequency else { return nil }

        let window = loudestWindow(samples, sampleRate: sampleRate)
        guard !window.isEmpty else { return nil }

        var bestFreq = minFrequency
        var bestPower: Float = -1
        var freq = minFrequency
        while freq <= maxFrequency {
            let power = Goertzel.power(window[...], freq: freq, sampleRate: sampleRate)
            if power > bestPower {
                bestPower = power
                bestFreq = freq
            }
            freq += resolution
        }
        return bestPower >= minPower ? bestFreq : nil
    }

    private func loudestWindow(_ samples: [Float], sampleRate: Double) -> [Float] {
        let win = min(samples.count, max(256, Int(sampleRate * analysisWindow)))
        guard win > 0, samples.count >= win else { return samples }

        let hop = max(1, win / 2)
        var bestStart = 0
        var bestEnergy: Float = -1
        var i = 0
        while i + win <= samples.count {
            var energy: Float = 0
            for j in i ..< (i + win) { energy += samples[j] * samples[j] }
            if energy > bestEnergy {
                bestEnergy = energy
                bestStart = i
            }
            i += hop
        }
        return Array(samples[bestStart ..< bestStart + win])
    }
}
</content>
