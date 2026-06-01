import Foundation

/// Flashes a Morse signal stream on the device torch using **absolute** clock
/// deadlines, so timing stays locked to the original timeline instead of drifting
/// the way cumulative `Task.sleep(for:)` does over a long message.
///
/// Used by the Control Center SOS intent: combined with `openAppWhenRun`, the
/// transmission runs in the foreground app process rather than the control
/// extension, avoiding the extension's CPU/Watchdog limits.
final class TorchMorseTransmitter {

    private let torch = FlashlightController()

    var isAvailable: Bool { torch.isAvailable }

    func transmit(signals: [MorseSignal], brightness: Float = 1.0) async {
        let steps = TorchSchedule.steps(for: signals)
        guard torch.isAvailable, !steps.isEmpty else { return }

        let clock = ContinuousClock()
        let start = clock.now
        defer { torch.turnOff() }

        for step in steps {
            let deadline = start.advanced(by: .seconds(step.startOffset))
            do { try await Task.sleep(until: deadline, clock: clock) }
            catch { return } // cancelled

            if step.isOn {
                try? torch.setOn(true, level: brightness)
            } else {
                torch.turnOff()
            }
        }

        // Hold the final element for its full duration before turning off.
        let total = TorchSchedule.totalDuration(for: signals)
        try? await Task.sleep(until: start.advanced(by: .seconds(total)), clock: clock)
    }
}
</content>
