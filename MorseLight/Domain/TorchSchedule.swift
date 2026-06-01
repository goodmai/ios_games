import Foundation

/// A torch state change at an absolute offset from the start of transmission.
struct TorchFlashStep: Equatable, Sendable {
    let isOn: Bool
    let startOffset: TimeInterval
}

/// Builds an absolute-offset flash schedule from Morse signals.
///
/// Players should sleep until `start + step.startOffset` (absolute deadlines)
/// rather than sleeping for each duration in turn — cumulative `sleep(duration)`
/// accrues drift over a long message, whereas absolute deadlines stay locked to
/// the original timeline.
enum TorchSchedule {

    static func steps(for signals: [MorseSignal]) -> [TorchFlashStep] {
        var steps: [TorchFlashStep] = []
        var offset: TimeInterval = 0
        for signal in signals {
            switch signal {
            case .on(let duration):
                steps.append(TorchFlashStep(isOn: true, startOffset: offset))
                offset += duration
            case .off(let duration):
                steps.append(TorchFlashStep(isOn: false, startOffset: offset))
                offset += duration
            }
        }
        return steps
    }

    static func totalDuration(for signals: [MorseSignal]) -> TimeInterval {
        signals.reduce(0) { acc, signal in
            switch signal {
            case .on(let d), .off(let d): return acc + d
            }
        }
    }
}
</content>
