import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @State private var vm = AppViewModel()

    var body: some View {
        NavigationStack {
            List {
                flashlightSection
                morseInputSection
                transmissionSection
                permissionsSection
            }
            .navigationTitle("MorseLight")
            .navigationBarTitleDisplayMode(.large)
            .task { await vm.setup() }
            .sheet(isPresented: $vm.showShareSheet) {
                if let url = vm.audioShareURL {
                    ActivityViewController(activityItems: [url])
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    // MARK: - Flashlight Section

    private var flashlightSection: some View {
        Section {
            // On/Off toggle
            HStack {
                Image(systemName: vm.manualTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .foregroundStyle(vm.manualTorchOn ? .yellow : .secondary)
                    .font(.title2)
                    .frame(width: 32)

                Toggle("Flashlight", isOn: Binding(
                    get: { vm.manualTorchOn },
                    set: { _ in vm.toggleManualTorch() }
                ))
                .disabled(!vm.isFlashlightAvailable || vm.isTransmittingLight)
            }

            // Brightness
            LabeledContent {
                HStack {
                    Image(systemName: "sun.min")
                        .foregroundStyle(.secondary)
                    Slider(value: $vm.brightness, in: 0.01...1.0) { editing in
                        if !editing { vm.applyBrightness() }
                    }
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.secondary)
                }
            } label: {
                Text("Brightness")
            }
            .disabled(!vm.isFlashlightAvailable)

            // Speed
            LabeledContent {
                HStack {
                    Text("Slow").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $vm.unitDuration, in: 0.05...0.35)
                    Text("Fast").font(.caption).foregroundStyle(.secondary)
                }
            } label: {
                Text("Speed")
            }

            if !vm.isFlashlightAvailable {
                Label("Torch unavailable on this device", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } header: {
            Label("Flashlight", systemImage: "flashlight.on.fill")
        }
    }

    // MARK: - Morse Input Section

    private var morseInputSection: some View {
        Section {
            // Text input
            TextField("Type your message…", text: $vm.inputText, axis: .vertical)
                .lineLimit(3...6)
                .submitLabel(.done)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            // Live Morse preview
            if !vm.morsePreview.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(vm.morsePreview)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
                }
            }
        } header: {
            Label("Message", systemImage: "text.cursor")
        }
    }

    // MARK: - Transmission Section

    private var transmissionSection: some View {
        Section {
            // Via Light button
            Button {
                vm.transmitViaLight()
            } label: {
                HStack {
                    Label("Via Light", systemImage: "flashlight.on.fill")
                        .foregroundStyle(vm.canTransmitLight ? .yellow : .secondary)
                    Spacer()
                    if vm.isTransmittingLight {
                        ProgressView().tint(.yellow)
                    }
                }
            }
            .disabled(!vm.canTransmitLight)

            // Via Sound button
            Button {
                vm.transmitViaSound()
            } label: {
                HStack {
                    Label("Via Sound", systemImage: "waveform")
                        .foregroundStyle(vm.canTransmitSound ? .blue : .secondary)
                    Spacer()
                    if vm.isPlayingSound {
                        ProgressView().tint(.blue)
                    }
                }
            }
            .disabled(!vm.canTransmitSound)

            // Share audio button
            Button {
                vm.prepareAudioShare()
            } label: {
                Label("Share Audio (WAV)", systemImage: "square.and.arrow.up")
                    .foregroundStyle(!vm.inputText.isEmpty ? .green : .secondary)
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)

            // Status / Stop
            if vm.isTransmittingLight || vm.isPlayingSound {
                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .symbolEffect(.variableColor)
                        .foregroundStyle(.orange)
                    Text(vm.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Stop") { vm.stop() }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                }
            }
        } header: {
            Label("Transmit", systemImage: "dot.radiowaves.left.and.right")
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        Section {
            PermissionRow(
                icon: "camera.fill",
                name: "Camera (Flashlight)",
                status: vm.cameraPermission
            ) {
                Task { await vm.requestCameraPermission() }
            }

            PermissionRow(
                icon: "mic.fill",
                name: "Microphone",
                status: vm.micPermission
            ) {
                Task { await vm.requestMicPermission() }
            }

            PermissionRow(
                icon: "photo.on.rectangle",
                name: "Photo Library",
                status: photoAuthStatus(vm.photoPermission)
            ) {
                Task { await vm.requestPhotoPermission() }
            }
        } header: {
            Label("Permissions", systemImage: "lock.shield")
        } footer: {
            Text("Camera permission is required to control the flashlight. Microphone and Photo Library are needed for audio export.")
                .font(.caption)
        }
    }

    private func photoAuthStatus(_ status: PHAuthorizationStatus) -> AVAuthorizationStatus {
        switch status {
        case .authorized, .limited: return .authorized
        case .denied, .restricted: return .denied
        default: return .notDetermined
        }
    }
}

// MARK: - PermissionRow

private struct PermissionRow: View {
    let icon: String
    let name: String
    let status: AVAuthorizationStatus
    let onRequest: () -> Void

    private var label: String {
        switch status {
        case .authorized: "Granted"
        case .denied:     "Denied"
        case .restricted: "Restricted"
        default:          "Not Requested"
        }
    }

    private var color: Color {
        switch status {
        case .authorized:            .green
        case .denied, .restricted:   .red
        default:                     .secondary
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(name)
            Spacer()
            if status == .notDetermined {
                Button("Request", action: onRequest)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)
            } else {
                Text(label)
                    .foregroundStyle(color)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    ContentView()
}
