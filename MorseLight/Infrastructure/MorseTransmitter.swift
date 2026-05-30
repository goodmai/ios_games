import Foundation

actor MorseTransmitter {
    private let flashlight = FlashlightController()
    private let audio = MorseAudioEngine()

    private(set) var isTransmitting = false

    // MARK: Light

    func transmitLight(signals: [MorseSignal], brightness: Float) async throws {
        isTransmitting = true
        defer {
            flashlight.turnOff()
            isTransmitting = false
        }
        for signal in signals {
            try Task.checkCancellation()
            switch signal {
            case .on(let d):
                try flashlight.setOn(true, level: brightness)
                try await Task.sleep(for: .seconds(d))
            case .off(let d):
                flashlight.turnOff()
                try await Task.sleep(for: .seconds(d))
            }
        }
    }

    // MARK: Sound

    func transmitSound(signals: [MorseSignal]) throws {
        try audio.play(signals: signals)
    }

    func stopSound() {
        audio.stop()
    }

    // MARK: Export

    func exportAudio(signals: [MorseSignal]) throws -> URL {
        try audio.exportURL(signals: signals)
    }

    // MARK: Cleanup

    func stopAll() {
        flashlight.turnOff()
        audio.stop()
        isTransmitting = false
    }
}
