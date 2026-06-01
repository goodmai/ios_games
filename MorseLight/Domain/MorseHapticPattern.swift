import Foundation

/// One playable haptic pulse: a continuous buzz starting at `time` lasting
/// `duration`, at the given `intensity` / `sharpness` (0…1, CoreHaptics scale).
struct MorseHapticEvent: Equatable, Sendable {
    let time: TimeInterval
    let duration: TimeInterval
    let intensity: Float
    let sharpness: Float
}

/// Pure mapping from a Morse signal stream to a timed haptic-event list.
///
/// Each `.on` becomes a continuous haptic pulse; each `.off` advances time as a
/// silent gap. Kept free of CoreHaptics so the timing is fully unit-testable;
/// `MorseHapticPlayer` renders the events on device.
struct MorseHapticPattern: Sendable {

    var intensity: Float = 1.0
    var sharpness: Float = 0.5

    func events(for signals: [MorseSignal]) -> [MorseHapticEvent] {
        var time: TimeInterval = 0
        var events: [MorseHapticEvent] = []
        for signal in signals {
            switch signal {
            case .on(let duration):
                events.append(MorseHapticEvent(
                    time: time,
                    duration: duration,
                    intensity: intensity,
                    sharpness: sharpness
                ))
                time += duration
            case .off(let duration):
                time += duration
            }
        }
        return events
    }

    func totalDuration(for signals: [MorseSignal]) -> TimeInterval {
        signals.reduce(0) { acc, signal in
            switch signal {
            case .on(let d), .off(let d): return acc + d
            }
        }
    }
}
</content>
