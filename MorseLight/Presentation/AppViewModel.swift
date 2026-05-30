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

    // MARK: Transmission state
    var isTransmittingLight = false
    var isPlayingSound = false
    var statusMessage = ""

    // MARK: Share state
    var audioShareURL: URL?
    var showShareSheet = false

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
        inputText.isEmpty ? "" : converter.morseString(for: inputText)
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
        return c
    }

    private var signals: [MorseSignal] {
        converter.signals(for: inputText)
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
        lightTask?.cancel()
        let sigs = signals
        let brt = brightness
        isTransmittingLight = true
        statusMessage = "Transmitting via light…"

        // Turn off manual torch so Morse controls it
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
        let sigs = signals
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
        let sigs = signals
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
