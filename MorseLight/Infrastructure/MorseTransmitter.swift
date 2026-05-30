import Foundation

actor MorseTransmitter {
    private let flashlight = FlashlightController()
    private let audio = MorseAudioEngine()
    private let decoder = MorseAudioDecoder()

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

    func stopSound() { audio.stop() }

    // MARK: Export — M4A (AAC, native iOS format)

    func exportAudio(signals: [MorseSignal]) throws -> URL {
        try audio.exportM4A(signals: signals)
    }

    // MARK: Decode — audio file → Morse → text
    // Runs on background thread; actor isolation ensures thread safety.

    func decodeAudio(from url: URL) async throws -> String {
        let dec = decoder   // capture value for Task.detached
        return try await Task.detached(priority: .userInitiated) {
            try dec.decode(from: url)
        }.value
    }

    // MARK: Cleanup

    func stopAll() {
        flashlight.turnOff()
        audio.stop()
        isTransmitting = false
    }
}
