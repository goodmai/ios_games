import Testing
import Foundation
@testable import MorseLight

@Suite("TorchSchedule")
struct TorchScheduleTests {

    private func signals(_ text: String, unit: TimeInterval = 0.1) -> [MorseSignal] {
        var converter = MorseConverter()
        converter.unitDuration = unit
        return converter.signals(for: text)
    }

    @Test("One step per signal")
    func stepPerSignal() {
        let sos = signals("SOS")
        #expect(TorchSchedule.steps(for: sos).count == sos.count)
    }

    @Test("First step starts at offset zero")
    func firstStepAtZero() {
        let steps = TorchSchedule.steps(for: signals("E"))
        #expect(steps.first?.startOffset == 0)
        #expect(steps.first?.isOn == true)
    }

    @Test("Offsets are strictly increasing (absolute timeline)")
    func monotonicOffsets() {
        let steps = TorchSchedule.steps(for: signals("SOS"))
        for i in 1..<steps.count {
            #expect(steps[i].startOffset > steps[i - 1].startOffset)
        }
    }

    @Test("On/off flags alternate with the signal stream")
    func onOffMapping() {
        // E = single dot → [on]; A = .- → on, off, on
        let a = TorchSchedule.steps(for: signals("A"))
        #expect(a.map(\.isOn) == [true, false, true])
    }

    @Test("Final offset is below the total duration")
    func finalOffsetWithinTotal() {
        let sos = signals("SOS")
        let steps = TorchSchedule.steps(for: sos)
        let total = TorchSchedule.totalDuration(for: sos)
        #expect((steps.last?.startOffset ?? 0) < total)
    }

    @Test("Empty input yields no steps")
    func emptyInput() {
        #expect(TorchSchedule.steps(for: signals("")).isEmpty)
    }
}
</content>
