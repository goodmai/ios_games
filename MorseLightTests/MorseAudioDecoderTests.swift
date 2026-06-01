import Testing
import Foundation
@testable import MorseLight

@Suite("MorseAudioDecoder")
struct MorseAudioDecoderTests {

    // MARK: - Helpers

    /// Encodes text → M4A file via AVFoundation, decodes back to text using Goertzel.
    private func roundTrip(_ text: String, unit: TimeInterval = 0.08) throws -> String {
        var converter = MorseConverter()
        converter.unitDuration = unit
        let signals = converter.signals(for: text)
        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }
        return try MorseAudioDecoder().decode(from: url)
    }

    // MARK: - Single character round-trips

    @Test("Round-trip single letter E (dit)")
    func singleLetterE() throws {
        let result = try roundTrip("E")
        #expect(result == "E")
    }

    @Test("Round-trip single letter T (dah)")
    func singleLetterT() throws {
        let result = try roundTrip("T")
        #expect(result == "T")
    }

    @Test("Round-trip single letter A (.-)")
    func singleLetterA() throws {
        let result = try roundTrip("A")
        #expect(result == "A")
    }

    @Test("Round-trip single letter S (...)")
    func singleLetterS() throws {
        let result = try roundTrip("S")
        #expect(result == "S")
    }

    @Test("Round-trip single letter O (---)")
    func singleLetterO() throws {
        let result = try roundTrip("O")
        #expect(result == "O")
    }

    // MARK: - Word round-trips

    @Test("Round-trip SOS")
    func sos() throws {
        let result = try roundTrip("SOS")
        #expect(result == "SOS")
    }

    @Test("Round-trip HI")
    func hi() throws {
        let result = try roundTrip("HI")
        #expect(result == "HI")
    }

    // MARK: - Goertzel energy detection

    @Test("Decoder: pure silence returns empty or no-Morse string")
    func silenceReturnsEmpty() throws {
        let signals: [MorseSignal] = [.off(duration: 0.5)]
        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }
        let result = try MorseAudioDecoder().decode(from: url)
        #expect(result.isEmpty)
    }

    // MARK: - Error cases

    @Test("Decoder: non-existent file throws cannotReadFile")
    func nonExistentFileThrows() {
        let badURL = URL(fileURLWithPath: "/tmp/does_not_exist_morse.m4a")
        let decoder = MorseAudioDecoder()
        #expect(throws: MorseDecoderError.self) {
            _ = try decoder.decode(from: badURL)
        }
    }

    @Test("Decoder: too-short audio throws tooShort")
    func tooShortAudioThrows() throws {
        let signals: [MorseSignal] = [.on(duration: 0.01)]
        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(throws: MorseDecoderError.self) {
            _ = try MorseAudioDecoder().decode(from: url)
        }
    }

    // MARK: - Configurable parameters

    @Test("Decoder: toneFrequency default is 700 Hz")
    func defaultToneFrequency() {
        let decoder = MorseAudioDecoder()
        #expect(decoder.toneFrequency == 700.0)
    }

    @Test("Decoder: windowDuration default is 10ms")
    func defaultWindowDuration() {
        let decoder = MorseAudioDecoder()
        #expect(decoder.windowDuration == 0.010)
    }

    @Test("Decoder: energyThreshold default is 0.008")
    func defaultEnergyThreshold() {
        let decoder = MorseAudioDecoder()
        #expect(decoder.energyThreshold == 0.008)
    }

    // MARK: - E1: Doppler-resilient auto-tune (FTL-05)

    @Test("Decoder: autoTuneFrequency defaults to false")
    func defaultAutoTune() {
        #expect(MorseAudioDecoder().autoTuneFrequency == false)
    }

    @Test("Auto-tune enabled still round-trips a nominal 700 Hz file")
    func autoTuneRoundTrip() throws {
        var converter = MorseConverter()
        converter.unitDuration = 0.08
        let signals = converter.signals(for: "SOS")
        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }

        var decoder = MorseAudioDecoder()
        decoder.autoTuneFrequency = true
        #expect(try decoder.decode(from: url) == "SOS")
    }

    // MARK: - E2: Streaming reads (MEM-01, MEM-02)

    @Test("Decoder: streamingChunkFrames defaults to 4096")
    func defaultChunkFrames() {
        #expect(MorseAudioDecoder().streamingChunkFrames == 4096)
    }

    @Test("Small chunk size still decodes SOS (chunk-boundary equivalence)")
    func smallChunkRoundTrip() throws {
        var converter = MorseConverter()
        converter.unitDuration = 0.08
        let signals = converter.signals(for: "SOS")
        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }

        var decoder = MorseAudioDecoder()
        decoder.streamingChunkFrames = 1024
        #expect(try decoder.decode(from: url) == "SOS")
    }
}
