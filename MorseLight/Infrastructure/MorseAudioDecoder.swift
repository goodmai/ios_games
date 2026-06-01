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

/// Decodes a Morse-code audio file back to plain text.
///
/// Algorithm:
///  1. Stream the audio file in fixed chunks (memory bounded by `streamingChunkFrames`)
///  2. Mix channels to mono Float32
///  3. Optionally sweep 600–800 Hz (`autoTuneFrequency`) to track Doppler / off-tune
///     transmitters before detection
///  4. Slide windows; run Goertzel at the (tuned) tone to measure energy
///  5. Threshold → on/off `MorseSegment` list
///  6. `MorseSegmentDecoder`: K-means unit calibration → text
struct MorseAudioDecoder: Sendable {

    var toneFrequency: Double = 700.0
    var windowDuration: TimeInterval = 0.010   // 10 ms analysis window
    var energyThreshold: Float = 0.008          // normalized Goertzel power
    var language: MorseLanguage = .english

    // Minimum segment to keep (shorter = noise)
    var minSegmentDuration: TimeInterval = 0.020

    /// When true, the dominant tone in 600–800 Hz is detected per-file and used
    /// in place of `toneFrequency`, so motion-induced Doppler or a third-party
    /// transmitter's frequency drift still decodes.
    var autoTuneFrequency: Bool = false

    /// Frames read per streaming pass. Peak PCM-buffer memory is bounded by this,
    /// not by the file length.
    var streamingChunkFrames: AVAudioFrameCount = 4096

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

        let mono = try readMono(from: audioFile, format: pcmFormat, maxFrames: maxFrames)

        var frequency = toneFrequency
        if autoTuneFrequency,
           let peak = FrequencyPeakDetector().dominantFrequency(samples: mono, sampleRate: sampleRate) {
            frequency = peak
        }

        let segments = detectSegments(samples: mono, sampleRate: sampleRate, frequency: frequency)
        var decoder = MorseSegmentDecoder()
        decoder.language = language
        return decoder.text(from: segments)
    }

    // MARK: Step 1 — Stream file in chunks → mono Float32

    private func readMono(
        from audioFile: AVAudioFile,
        format pcmFormat: AVAudioFormat,
        maxFrames: AVAudioFrameCount
    ) throws -> [Float] {
        let chunkFrames = max(1, streamingChunkFrames)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: chunkFrames) else {
            throw MorseDecoderError.bufferAllocationFailed
        }

        var mono: [Float] = []
        mono.reserveCapacity(Int(maxFrames))

        var remaining = maxFrames
        while remaining > 0 {
            let toRead = min(chunkFrames, remaining)
            buffer.frameLength = 0
            do { try audioFile.read(into: buffer, frameCount: toRead) }
            catch { throw MorseDecoderError.cannotReadFile(error.localizedDescription) }

            if buffer.frameLength == 0 { break } // end of file
            mono.append(contentsOf: mixToMono(buffer: buffer))
            remaining -= min(buffer.frameLength, remaining)
        }
        return mono
    }

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
        sampleRate: Double,
        frequency: Double
    ) -> [MorseSegment] {
        let winSize = max(64, Int(sampleRate * windowDuration))
        var segments: [MorseSegment] = []

        var currentIsOn = false
        var segmentFrames = 0

        var i = 0
        while i + winSize <= samples.count {
            let windowSlice = samples[i ..< i + winSize]
            let power = Goertzel.power(windowSlice, freq: frequency, sampleRate: sampleRate)
            let winIsOn = power > energyThreshold

            if winIsOn != currentIsOn {
                let dur = Double(segmentFrames) / sampleRate
                if segmentFrames > 0 && dur >= minSegmentDuration {
                    segments.append(MorseSegment(isOn: currentIsOn, duration: dur))
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
            segments.append(MorseSegment(isOn: currentIsOn, duration: dur))
        }
        return segments
    }
}
</content>
