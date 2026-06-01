import Testing
import Foundation
@testable import MorseLight

@Suite("FrequencyPeakDetector")
struct FrequencyPeakDetectorTests {

    private func sine(_ freq: Double, seconds: Double, sampleRate: Double = 44_100) -> [Float] {
        let n = Int(seconds * sampleRate)
        return (0..<n).map { Float(sin(2.0 * .pi * freq * Double($0) / sampleRate)) }
    }

    // MARK: - Peak detection (FTL-01, FTL-02)

    @Test("Detects the nominal 700 Hz tone within the band")
    func detectsNominalTone() {
        let detector = FrequencyPeakDetector()
        let peak = detector.dominantFrequency(samples: sine(700, seconds: 0.1), sampleRate: 44_100)
        #expect(peak != nil)
        #expect(abs(peak! - 700) <= detector.resolution * 2)
    }

    @Test("Detects a Doppler-shifted 760 Hz tone (off the fixed 700 Hz bin)")
    func detectsShiftedTone() {
        let detector = FrequencyPeakDetector()
        let peak = detector.dominantFrequency(samples: sine(760, seconds: 0.1), sampleRate: 44_100)
        #expect(peak != nil)
        #expect(abs(peak! - 760) <= detector.resolution * 2)
    }

    @Test("Detects a low-edge 620 Hz tone")
    func detectsLowEdgeTone() {
        let detector = FrequencyPeakDetector()
        let peak = detector.dominantFrequency(samples: sine(620, seconds: 0.1), sampleRate: 44_100)
        #expect(peak != nil)
        #expect(abs(peak! - 620) <= detector.resolution * 2)
    }

    // MARK: - Noise floor (FTL-03)

    @Test("Returns nil for pure silence")
    func silenceReturnsNil() {
        let silence = [Float](repeating: 0, count: 44_100 / 10)
        #expect(FrequencyPeakDetector().dominantFrequency(samples: silence, sampleRate: 44_100) == nil)
    }

    @Test("Returns nil for empty input")
    func emptyReturnsNil() {
        #expect(FrequencyPeakDetector().dominantFrequency(samples: [], sampleRate: 44_100) == nil)
    }

    // MARK: - Defaults (FTL-04)

    @Test("Default band is 600–800 Hz")
    func defaultBand() {
        let detector = FrequencyPeakDetector()
        #expect(detector.minFrequency == 600.0)
        #expect(detector.maxFrequency == 800.0)
    }
}
</content>
