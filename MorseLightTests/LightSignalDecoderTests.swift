import Testing
import Foundation
@testable import MorseLight

@Suite("LightSignalDecoder")
struct LightSignalDecoderTests {

    /// Renders text → a synthetic brightness timeline (1.0 on, 0.0 off) at `fps`,
    /// mirroring what a camera would sample from a blinking torch.
    private func brightness(_ text: String, unit: TimeInterval = 0.08, fps: Double = 240) -> [Float] {
        var converter = MorseConverter()
        converter.unitDuration = unit
        var out: [Float] = []
        for signal in converter.signals(for: text) {
            switch signal {
            case .on(let d):  out += Array(repeating: Float(1.0), count: Int(d * fps))
            case .off(let d): out += Array(repeating: Float(0.0), count: Int(d * fps))
            }
        }
        return out
    }

    // MARK: - Round-trips (CV-01, CV-02, CV-03)

    @Test("Round-trips single letter E from a brightness timeline")
    func roundTripE() {
        let text = LightSignalDecoder().decode(brightness: brightness("E"), frameRate: 240)
        #expect(text == "E")
    }

    @Test("Round-trips SOS from a brightness timeline")
    func roundTripSOS() {
        let text = LightSignalDecoder().decode(brightness: brightness("SOS"), frameRate: 240)
        #expect(text == "SOS")
    }

    @Test("Round-trips HI from a brightness timeline")
    func roundTripHI() {
        let text = LightSignalDecoder().decode(brightness: brightness("HI"), frameRate: 240)
        #expect(text == "HI")
    }

    // MARK: - Noise rejection & defaults (CV-04)

    @Test("Empty timeline decodes to empty string")
    func emptyTimeline() {
        #expect(LightSignalDecoder().decode(brightness: [], frameRate: 240).isEmpty)
    }

    @Test("Sub-threshold flicker shorter than minSegmentDuration is ignored")
    func rejectsFlicker() {
        // A single bright frame at 240 fps ≈ 4 ms, below the 20 ms floor → no letter.
        let flicker: [Float] = [0, 0, 1, 0, 0]
        #expect(LightSignalDecoder().decode(brightness: flicker, frameRate: 240).isEmpty)
    }

    @Test("Default brightness threshold is 0.5")
    func defaultThreshold() {
        #expect(LightSignalDecoder().brightnessThreshold == 0.5)
    }
}
</content>
