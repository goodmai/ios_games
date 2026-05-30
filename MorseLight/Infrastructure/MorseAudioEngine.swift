import AVFoundation
import Foundation

enum MorseAudioError: Error, LocalizedError {
    case bufferAllocationFailed
    case emptySamples

    var errorDescription: String? {
        switch self {
        case .bufferAllocationFailed: "Failed to allocate audio buffer"
        case .emptySamples: "No audio samples to encode — input text is empty"
        }
    }
}

final class MorseAudioEngine: @unchecked Sendable {
    let sampleRate = 44100
    private let frequency = 700.0
    private var player: AVAudioPlayer?

    // MARK: Playback (internal WAV — lowest latency, no codec overhead)

    func play(signals: [MorseSignal]) throws {
        stop()
        let data = buildWAV(samples: generateSamples(from: signals))
        try configureSession()
        player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
        player?.prepareToPlay()
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }

    var isPlaying: Bool { player?.isPlaying == true }

    // MARK: Export — M4A / AAC (native iOS format: works in iMessage, AirDrop, Files)

    func exportM4A(signals: [MorseSignal]) throws -> URL {
        let samples = generateSamples(from: signals)
        guard !samples.isEmpty else { throw MorseAudioError.emptySamples }

        let ts = Int(Date().timeIntervalSince1970)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("morse_\(ts).m4a")

        // Float32 PCM → AAC via AVAudioFile (auto-converts on write)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: Double(sampleRate),
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64_000
        ]

        let pcmFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(sampleRate),
            channels: 1,
            interleaved: false
        )!

        let file = try AVAudioFile(
            forWriting: url,
            settings: outputSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        let frameCount = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: frameCount) else {
            throw MorseAudioError.bufferAllocationFailed
        }
        buffer.frameLength = frameCount
        samples.withUnsafeBufferPointer { ptr in
            buffer.floatChannelData![0].initialize(from: ptr.baseAddress!, count: samples.count)
        }

        try file.write(from: buffer)
        return url
    }

    // MARK: PCM sample generation (shared by play + export + tests)

    func generateSamples(from signals: [MorseSignal]) -> [Float] {
        var out: [Float] = []
        out.reserveCapacity(signals.reduce(0) { acc, s in
            switch s {
            case .on(let d), .off(let d): return acc + Int(Double(sampleRate) * d)
            }
        })
        for signal in signals {
            switch signal {
            case .on(let d):  out += tone(seconds: d)
            case .off(let d): out += silence(seconds: d)
            }
        }
        return out
    }

    // MARK: Private helpers

    private func tone(seconds: TimeInterval) -> [Float] {
        let n = Int(Double(sampleRate) * seconds)
        guard n > 0 else { return [] }
        let fadeLen = min(Int(Double(sampleRate) * 0.005), max(1, n / 4))
        return (0..<n).map { i in
            let fade: Double
            if      i < fadeLen     { fade = Double(i) / Double(fadeLen) }
            else if i > n - fadeLen { fade = Double(n - i) / Double(fadeLen) }
            else                    { fade = 1.0 }
            return Float(sin(2.0 * .pi * frequency * Double(i) / Double(sampleRate)) * fade)
        }
    }

    private func silence(seconds: TimeInterval) -> [Float] {
        Array(repeating: 0, count: Int(Double(sampleRate) * seconds))
    }

    private func buildWAV(samples: [Float]) -> Data {
        let bps = 2
        let ch  = UInt16(1)
        let sr  = UInt32(sampleRate)
        let sz  = UInt32(samples.count * bps)
        var d = Data(capacity: Int(44 + sz))
        d += "RIFF".utf8; d.appendLE(36 + sz); d += "WAVE".utf8
        d += "fmt ".utf8; d.appendLE(UInt32(16)); d.appendLE(UInt16(1))
        d.appendLE(ch); d.appendLE(sr)
        d.appendLE(sr * UInt32(ch) * UInt32(bps))
        d.appendLE(ch * UInt16(bps)); d.appendLE(UInt16(16))
        d += "data".utf8; d.appendLE(sz)
        for s in samples { d.appendLE(Int16(max(-1, min(1, s)) * 32767)) }
        return d
    }

    private func configureSession() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { self.append(contentsOf: $0) }
    }
}
