#if canImport(CoreHaptics)
import CoreHaptics
import Foundation

/// Renders a `MorseHapticPattern` through CoreHaptics so deaf-blind / low-vision
/// users can feel a message. Thin device wrapper — the testable timing lives in
/// `MorseHapticPattern`; this layer is exercised by device checks (HAP-05).
@available(iOS 13.0, *)
final class MorseHapticPlayer {

    private var engine: CHHapticEngine?
    private let pattern: MorseHapticPattern

    init(pattern: MorseHapticPattern = MorseHapticPattern()) {
        self.pattern = pattern
    }

    var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func play(signals: [MorseSignal]) throws {
        guard isSupported else { return }

        let engine = try (self.engine ?? CHHapticEngine())
        self.engine = engine
        try engine.start()

        let hapticEvents = pattern.events(for: signals).map { event in
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: event.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: event.sharpness)
                ],
                relativeTime: event.time,
                duration: event.duration
            )
        }

        let chPattern = try CHHapticPattern(events: hapticEvents, parameters: [])
        let player = try engine.makePlayer(with: chPattern)
        try player.start(atTime: CHHapticTimeImmediate)
    }

    func stop() {
        engine?.stop()
    }
}
#endif
</content>
