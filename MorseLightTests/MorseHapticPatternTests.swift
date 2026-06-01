import Testing
import Foundation
@testable import MorseLight

@Suite("MorseHapticPattern")
struct MorseHapticPatternTests {

    private func signals(_ text: String, unit: TimeInterval = 0.1) -> [MorseSignal] {
        var converter = MorseConverter()
        converter.unitDuration = unit
        return converter.signals(for: text)
    }

    // MARK: - One event per on-signal (HAP-01)

    @Test("Emits one haptic event per on-signal, none for gaps")
    func oneEventPerOn() {
        let sos = signals("SOS")               // ... --- ... → 9 on-signals
        let events = MorseHapticPattern().events(for: sos)
        let onCount = sos.filter { if case .on = $0 { return true } else { return false } }.count
        #expect(events.count == onCount)
        #expect(events.count == 9)
    }

    @Test("Single dot (E) yields exactly one event")
    func singleDot() {
        let events = MorseHapticPattern().events(for: signals("E"))
        #expect(events.count == 1)
        #expect(events[0].time == 0)
    }

    @Test("Empty text yields no events")
    func emptyText() {
        #expect(MorseHapticPattern().events(for: signals("")).isEmpty)
    }

    // MARK: - Timing (HAP-02, HAP-03)

    @Test("Event times are strictly increasing")
    func monotonicTimes() {
        let events = MorseHapticPattern().events(for: signals("SOS"))
        for i in 1..<events.count {
            #expect(events[i].time > events[i - 1].time)
        }
    }

    @Test("First event starts at time zero")
    func startsAtZero() {
        let events = MorseHapticPattern().events(for: signals("SOS"))
        #expect(events.first?.time == 0)
    }

    @Test("totalDuration equals the sum of all signal durations")
    func totalDurationSum() {
        let sos = signals("SOS")
        let expected = sos.reduce(0.0) { acc, s in
            switch s { case .on(let d), .off(let d): return acc + d }
        }
        #expect(MorseHapticPattern().totalDuration(for: sos) == expected)
    }

    // MARK: - Configuration (HAP-04)

    @Test("Default intensity is 1.0 and applied to every event")
    func defaultIntensity() {
        let pattern = MorseHapticPattern()
        #expect(pattern.intensity == 1.0)
        let events = pattern.events(for: signals("S"))
        #expect(events.allSatisfy { $0.intensity == 1.0 })
    }

    @Test("Custom intensity and sharpness propagate to events")
    func customParameters() {
        var pattern = MorseHapticPattern()
        pattern.intensity = 0.6
        pattern.sharpness = 0.2
        let events = pattern.events(for: signals("T"))
        #expect(events.allSatisfy { $0.intensity == 0.6 && $0.sharpness == 0.2 })
    }
}
</content>
