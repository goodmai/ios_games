import AVFoundation
import Foundation

enum MorseDecoderError: Error, LocalizedError {
    case cannotReadFile(String)
    case bufferAllocationFailed
    case tooShort

    var errorDescription: String? {
        switch self {
        case .cannotReadFile(let msg): "Cannot read audio file: \(msg)"
        case .bufferAllocationFailed:  "Failed to allocate audio buffer"
        case .tooShort:                "Audio file is too short to contain Morse code"
        }
    }
}

/// Decodes a 700 Hz Morse-code audio file back to plain text.
///
/// Algorithm:
///  1. Read audio file (any format AVFoundation supports: M4A, WAV, MP3…)
///  2. Mix channels to mono Float32
///  3. Slide 10 ms windows; run Goertzel algorithm to measure 700 Hz energy
///  4. Threshold → on/off segment list with durations
///  5. K-means (k=2) calibrates unit duration from dot/dash clusters
///  6. Map segments to dots/dashes/gaps → look up Morse table → text
struct MorseAudioDecoder: Sendable {

    var toneFrequency: Double = 700.0
    var windowDuration: TimeInterval = 0.010   // 10 ms analysis window
    var energyThreshold: Float = 0.008          // normalized Goertzel power
    var language: MorseLanguage = .english

    // Minimum segment to keep (shorter = noise)
    var minSegmentDuration: TimeInterval = 0.020

    // MARK: Public entry point

    func decode(from url: URL) throws -> String {
        let audioFile: AVAudioFile
        do { audioFile = try AVAudioFile(forReading: url) }
        catch { throw MorseDecoderError.cannotReadFile(error.localizedDescription) }

        let sampleRate = audioFile.processingFormat.sampleRate
        let channelCount = audioFile.processingFormat.channelCount
        let maxFrames = AVAudioFrameCount(min(audioFile.length, Int64(sampleRate * 120))) // cap 2 min

        guard maxFrames > AVAudioFrameCount(sampleRate * minSegmentDuration * 2) else {
            throw MorseDecoderError.tooShort
        }

        let pcmFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        )!

        guard let buffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: maxFrames) else {
            throw MorseDecoderError.bufferAllocationFailed
        }
        try audioFile.read(into: buffer)

        let mono = mixToMono(buffer: buffer)
        let segments = detectSegments(samples: mono, sampleRate: sampleRate)
        return segmentsToText(segments)
    }

    // MARK: Step 1 — Mono mix

    private func mixToMono(buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frames = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)

        if channels == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frames))
        }
        var mono = [Float](repeating: 0, count: frames)
        for ch in 0..<channels {
            let src = UnsafeBufferPointer(start: channelData[ch], count: frames)
            for i in 0..<frames { mono[i] += src[i] }
        }
        let scale = 1.0 / Float(channels)
        return mono.map { $0 * scale }
    }

    // MARK: Step 2 — Goertzel detection → on/off segments

    private func detectSegments(
        samples: [Float],
        sampleRate: Double
    ) -> [(isOn: Bool, duration: TimeInterval)] {
        let winSize = max(64, Int(sampleRate * windowDuration))
        var segments: [(isOn: Bool, duration: TimeInterval)] = []

        var currentIsOn = false
        var segmentFrames = 0

        var i = 0
        while i + winSize <= samples.count {
            let windowSlice = samples[i ..< i + winSize]
            let power = goertzel(slice: windowSlice, freq: toneFrequency, sampleRate: sampleRate)
            let winIsOn = power > energyThreshold

            if winIsOn != currentIsOn {
                let dur = Double(segmentFrames) / sampleRate
                if segmentFrames > 0 && dur >= minSegmentDuration {
                    segments.append((isOn: currentIsOn, duration: dur))
                }
                currentIsOn = winIsOn
                segmentFrames = winSize
            } else {
                segmentFrames += winSize
            }
            i += winSize
        }

        // Last segment
        let dur = Double(segmentFrames) / sampleRate
        if segmentFrames > 0 && dur >= minSegmentDuration {
            segments.append((isOn: currentIsOn, duration: dur))
        }
        return segments
    }

    // MARK: Step 3 — Goertzel at single frequency (normalized)

    private func goertzel(slice: ArraySlice<Float>, freq: Double, sampleRate: Double) -> Float {
        let n = slice.count
        let k = (Double(n) * freq / sampleRate).rounded()
        let coeff = Float(2.0 * cos(2.0 * .pi * k / Double(n)))
        var s1: Float = 0, s2: Float = 0
        for x in slice {
            let s0 = x + coeff * s1 - s2
            s2 = s1; s1 = s0
        }
        // Normalize by N² so threshold is amplitude-independent
        let power = s1 * s1 + s2 * s2 - coeff * s1 * s2
        return power / Float(n * n)
    }

    // MARK: Step 4 — Calibrate unit duration via K-means (k=2)

    private func estimateUnit(from onDurations: [TimeInterval]) -> TimeInterval {
        guard !onDurations.isEmpty else { return 0.1 }
        guard onDurations.count > 1 else { return onDurations[0] }

        let sorted = onDurations.sorted()

        // K-means: two centroids = dot & dash
        var c1 = sorted.first!
        var c2 = sorted.last!

        for _ in 0..<20 {
            let mid = (c1 + c2) / 2.0
            let dots = sorted.filter { $0 <= mid }
            let dashes = sorted.filter { $0 > mid }
            if dots.isEmpty || dashes.isEmpty { break }
            let newC1 = dots.reduce(0, +) / Double(dots.count)
            let newC2 = dashes.reduce(0, +) / Double(dashes.count)
            if abs(newC1 - c1) < 0.001 && abs(newC2 - c2) < 0.001 { break }
            c1 = newC1; c2 = newC2
        }
        return c1   // dot cluster mean = 1 unit
    }

    // MARK: Step 5 — Segments → text

    private func segmentsToText(_ segments: [(isOn: Bool, duration: TimeInterval)]) -> String {
        let onDurations = segments.filter { $0.isOn }.map { $0.duration }
        guard !onDurations.isEmpty else { return "" }

        let unit = estimateUnit(from: onDurations)
        guard unit > 0 else { return "" }

        // Reverse lookup: Morse code string → Character (language-aware)
        var table: [String: Character] = [:]
        for (ch, code) in MorseCode.table(for: language) where ch != " " { table[code] = ch }

        var result = ""
        var currentCode = ""

        for seg in segments {
            if seg.isOn {
                // dot threshold = 2× unit (dot ≈ 1u, dash ≈ 3u)
                currentCode += seg.duration < unit * 2.0 ? "." : "-"
            } else {
                if seg.duration > unit * 5.0 {
                    // Word gap (7u): flush letter + space
                    if let ch = table[currentCode] { result.append(ch) }
                    currentCode = ""
                    if !result.hasSuffix(" ") { result += " " }
                } else if seg.duration > unit * 2.0 {
                    // Letter gap (3u): flush letter
                    if let ch = table[currentCode] { result.append(ch) }
                    currentCode = ""
                }
                // else intra-character gap (1u): keep building currentCode
            }
        }

        if !currentCode.isEmpty, let ch = table[currentCode] {
            result.append(ch)
        }

        return result.trimmingCharacters(in: .whitespaces)
    }
}
