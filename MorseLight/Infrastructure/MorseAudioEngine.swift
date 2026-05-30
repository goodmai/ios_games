import AVFoundation
import Foundation

final class MorseAudioEngine: @unchecked Sendable {
    private let sampleRate = 44100
    private let frequency = 700.0
    private var player: AVAudioPlayer?

    // MARK: Playback

    func play(signals: [MorseSignal]) throws {
        stop()
        let data = generateWAV(signals: signals)
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

    // MARK: Export

    func exportURL(signals: [MorseSignal]) throws -> URL {
        let data = generateWAV(signals: signals)
        let ts = Int(Date().timeIntervalSince1970)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("morse_\(ts).wav")
        try data.write(to: url)
        return url
    }

    // MARK: WAV Generation

    func generateWAV(signals: [MorseSignal]) -> Data {
        var samples: [Float] = []
        for signal in signals {
            switch signal {
            case .on(let d):  samples += tone(seconds: d)
            case .off(let d): samples += silence(seconds: d)
            }
        }
        return buildWAV(samples: samples)
    }

    private func tone(seconds: TimeInterval) -> [Float] {
        let n = Int(Double(sampleRate) * seconds)
        guard n > 0 else { return [] }
        let fadeLen = min(Int(Double(sampleRate) * 0.005), max(1, n / 4))
        return (0..<n).map { i in
            let fade: Double
            if      i < fadeLen      { fade = Double(i) / Double(fadeLen) }
            else if i > n - fadeLen  { fade = Double(n - i) / Double(fadeLen) }
            else                     { fade = 1.0 }
            return Float(sin(2.0 * .pi * frequency * Double(i) / Double(sampleRate)) * fade)
        }
    }

    private func silence(seconds: TimeInterval) -> [Float] {
        Array(repeating: 0, count: Int(Double(sampleRate) * seconds))
    }

    private func buildWAV(samples: [Float]) -> Data {
        let bytesPerSample = 2
        let channels = UInt16(1)
        let sr = UInt32(sampleRate)
        let dataSize = UInt32(samples.count * bytesPerSample)

        var d = Data()
        d += "RIFF".utf8
        d.appendLE(36 + dataSize)
        d += "WAVE".utf8
        d += "fmt ".utf8
        d.appendLE(UInt32(16))
        d.appendLE(UInt16(1))    // PCM
        d.appendLE(channels)
        d.appendLE(sr)
        d.appendLE(sr * UInt32(channels) * UInt32(bytesPerSample))
        d.appendLE(channels * UInt16(bytesPerSample))
        d.appendLE(UInt16(16))   // bits per sample
        d += "data".utf8
        d.appendLE(dataSize)
        for s in samples {
            d.appendLE(Int16(max(-1, min(1, s)) * 32767))
        }
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
