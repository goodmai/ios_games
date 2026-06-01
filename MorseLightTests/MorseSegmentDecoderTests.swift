import Testing
import Foundation
@testable import MorseLight

@Suite("MorseSegmentDecoder")
struct MorseSegmentDecoderTests {

    /// Ideal segments straight from the converter's signal timing (no channel noise).
    private func segments(_ text: String, unit: TimeInterval = 0.08) -> [MorseSegment] {
        var converter = MorseConverter()
        converter.unitDuration = unit
        return converter.signals(for: text).map { signal in
            switch signal {
            case .on(let d):  return MorseSegment(isOn: true, duration: d)
            case .off(let d): return MorseSegment(isOn: false, duration: d)
            }
        }
    }

    @Test("Decodes a single dot to E")
    func decodesE() {
        #expect(MorseSegmentDecoder().text(from: segments("E")) == "E")
    }

    @Test("Decodes SOS from ideal segments")
    func decodesSOS() {
        #expect(MorseSegmentDecoder().text(from: segments("SOS")) == "SOS")
    }

    @Test("Decodes HI from ideal segments")
    func decodesHI() {
        #expect(MorseSegmentDecoder().text(from: segments("HI")) == "HI")
    }

    @Test("No segments decodes to empty string")
    func decodesEmpty() {
        #expect(MorseSegmentDecoder().text(from: []) == "")
    }

    @Test("Russian language decodes Cyrillic from ideal segments")
    func decodesRussian() {
        var decoder = MorseSegmentDecoder()
        decoder.language = .russian
        var converter = MorseConverter()
        converter.language = .russian
        converter.unitDuration = 0.08
        let segs = converter.signals(for: "ЭТО").map { signal -> MorseSegment in
            switch signal {
            case .on(let d):  return MorseSegment(isOn: true, duration: d)
            case .off(let d): return MorseSegment(isOn: false, duration: d)
            }
        }
        #expect(decoder.text(from: segs) == "ЭТО")
    }
}
</content>
