import SwiftUI
import AVFoundation
import Photos

@Observable
@MainActor
final class AppViewModel {

    // MARK: Input state
    var inputText = ""
    var brightness: Float = 1.0
    var unitDuration: TimeInterval = 0.1
    var selectedLanguage: MorseLanguage = .english

    // MARK: Cipher state
    var seedText = ""
    var cipherError: String?

    var isCipherEnabled: Bool { !seedText.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: Transmission state
    var isTransmittingLight = false
    var isPlayingSound = false
    var statusMessage = ""

    // MARK: Share state
    var audioShareURL: URL?
    var showShareSheet = false

    // MARK: Decode state
    var showDocumentPicker = false
    var decodedText = ""
    var isDecoding = false
    var decodeError: String?
    /// Sweeps 600–800 Hz and retunes Goertzel to the dominant tone (Epic E1),
    /// so Doppler-shifted or off-tune third-party recordings still decode.
    var autoTuneFrequency = false

    // MARK: Torch manual toggle
    var manualTorchOn = false

    // MARK: Permissions
    var cameraPermission: AVAuthorizationStatus = .notDetermined
    var micPermission: AVAuthorizationStatus = .notDetermined
    var photoPermission: PHAuthorizationStatus = .notDetermined

    // MARK: Private
    private let flashlight = FlashlightController()
    private let transmitter = MorseTransmitter()
    private var lightTask: Task<Void, Never>?

    // MARK: Computed

    var morsePreview: String {
        guard !inputText.isEmpty else { return "" }
        if isCipherEnabled { return "[AES-256-GCM encrypted — \(inputText.count) chars]" }
        return converter.morseString(for: inputText)
    }

    var canTransmitLight: Bool {
        flashlight.isAvailable &&
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isTransmittingLight
    }

    var canTransmitSound: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isFlashlightAvailable: Bool { flashlight.isAvailable }

    private var converter: MorseConverter {
        var c = MorseConverter()
        c.unitDuration = unitDuration
        c.language = selectedLanguage
        return c
    }

    /// Returns signals for transmission, encrypting the text first if a seed is set.
    private func buildSignals() throws -> [MorseSignal] {
        if isCipherEnabled {
            let hex = try MorseCipher.encrypt(inputText, seed: seedText.trimmingCharacters(in: .whitespaces))
            return converter.signals(for: hex)
        }
        return converter.signals(for: inputText)
    }

    // MARK: Setup

    func setup() async {
        refreshPermissions()
    }

    func refreshPermissions() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        micPermission = AVCaptureDevice.authorizationStatus(for: .audio)
        photoPermission = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }

    // MARK: Manual torch

    func toggleManualTorch() {
        manualTorchOn.toggle()
        try? flashlight.setOn(manualTorchOn, level: brightness)
    }

    func applyBrightness() {
        guard manualTorchOn else { return }
        try? flashlight.setOn(true, level: brightness)
    }

    // MARK: Morse via light

    func transmitViaLight() {
        guard canTransmitLight else { return }
        cipherError = nil
        let sigs: [MorseSignal]
        do { sigs = try buildSignals() }
        catch { cipherError = error.localizedDescription; return }

        lightTask?.cancel()
        let brt = brightness
        isTransmittingLight = true
        statusMessage = "Transmitting via light…"

        if manualTorchOn {
            manualTorchOn = false
            flashlight.turnOff()
        }

        lightTask = Task {
            do {
                try await transmitter.transmitLight(signals: sigs, brightness: brt)
            } catch is CancellationError {
                // user stopped
            } catch {
                statusMessage = error.localizedDescription
            }
            isTransmittingLight = false
            statusMessage = ""
        }
    }

    // MARK: Morse via sound

    func transmitViaSound() {
        guard canTransmitSound else { return }
        cipherError = nil
        let sigs: [MorseSignal]
        do { sigs = try buildSignals() }
        catch { cipherError = error.localizedDescription; return }

        isPlayingSound = true
        statusMessage = "Playing Morse audio…"
        Task {
            do {
                try await transmitter.transmitSound(signals: sigs)
            } catch {
                statusMessage = error.localizedDescription
            }
            isPlayingSound = false
            statusMessage = ""
        }
    }

    // MARK: Share audio

    func prepareAudioShare() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        cipherError = nil
        let sigs: [MorseSignal]
        do { sigs = try buildSignals() }
        catch { cipherError = error.localizedDescription; return }

        Task {
            do {
                let url = try await transmitter.exportAudio(signals: sigs)
                audioShareURL = url
                showShareSheet = true
            } catch {
                statusMessage = "Could not generate audio: \(error.localizedDescription)"
            }
        }
    }

    // MARK: Import & decode audio

    func importAndDecodeAudio() {
        showDocumentPicker = true
    }

    func decodeAudio(from url: URL) {
        isDecoding = true
        decodedText = ""
        decodeError = nil
        let seed = seedText.trimmingCharacters(in: .whitespaces)
        let autoTune = autoTuneFrequency
        Task {
            defer {
                url.stopAccessingSecurityScopedResource()
                isDecoding = false
            }
            do {
                var text = try await transmitter.decodeAudio(from: url, language: selectedLanguage, autoTune: autoTune)
                if !seed.isEmpty && !text.isEmpty {
                    text = (try? MorseCipher.decrypt(text, seed: seed)) ?? "[Decryption failed — wrong seed?]"
                }
                decodedText = text.isEmpty ? "(no Morse detected)" : text
            } catch {
                decodeError = error.localizedDescription
            }
        }
    }

    // MARK: Integration self-test hook (UI tests only)

    /// Encodes "SOS" to an audio file and decodes it back through the live
    /// pipeline, surfacing the result in `decodedText`. Drives Epics E1 (auto-tune)
    /// and E2 (streaming decode) end-to-end for `MorseLightUITests` without a file
    /// picker. Invoked only via the `-decodeSelfTest` launch argument.
    func runDecodeSelfTest(message: String = "SOS") {
        isDecoding = true
        decodedText = ""
        decodeError = nil
        var c = MorseConverter()
        c.unitDuration = 0.08
        let signals = c.signals(for: message)
        let autoTune = autoTuneFrequency
        let language = selectedLanguage
        Task {
            do {
                let url = try await transmitter.exportAudio(signals: signals)
                defer { try? FileManager.default.removeItem(at: url) }
                let text = try await transmitter.decodeAudio(from: url, language: language, autoTune: autoTune)
                decodedText = text.isEmpty ? "(no Morse detected)" : text
            } catch {
                decodeError = error.localizedDescription
            }
            isDecoding = false
        }
    }

    // MARK: Stop

    func stop() {
        lightTask?.cancel()
        lightTask = nil
        isTransmittingLight = false
        isPlayingSound = false
        statusMessage = ""
        Task { await transmitter.stopAll() }
    }

    // MARK: Permissions

    func requestCameraPermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraPermission = granted ? .authorized : .denied
    }

    func requestMicPermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        micPermission = granted ? .authorized : .denied
    }

    func requestPhotoPermission() async {
        photoPermission = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}
