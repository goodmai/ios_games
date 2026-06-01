import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @State private var vm = AppViewModel()
    @State private var showMorseTable = false

    var body: some View {
        NavigationStack {
            List {
                flashlightSection
                languageSection
                morseInputSection
                cipherSection
                transmissionSection
                decodeSection
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
            .sheet(isPresented: $vm.showDocumentPicker) {
                DocumentPicker { url in
                    vm.showDocumentPicker = false
                    vm.decodeAudio(from: url)
                }
            }
            .sheet(isPresented: $showMorseTable) {
                MorseTableSheet(language: vm.selectedLanguage)
            }
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        Section {
            Picker("Language", selection: $vm.selectedLanguage) {
                ForEach(MorseLanguage.allCases, id: \.self) { lang in
                    Text("\(lang.flagEmoji) \(lang.rawValue)").tag(lang)
                }
            }
            .pickerStyle(.segmented)

            Button {
                showMorseTable = true
            } label: {
                HStack {
                    Label("Morse Alphabet Table", systemImage: "list.bullet.rectangle")
                        .foregroundStyle(.teal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Language", systemImage: "globe")
        } footer: {
            Text("Select the Morse alphabet used for encoding and decoding.")
                .font(.caption)
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

    // MARK: - Cipher Section

    private var cipherSection: some View {
        Section {
            HStack {
                Image(systemName: vm.isCipherEnabled ? "lock.fill" : "lock.open")
                    .foregroundStyle(vm.isCipherEnabled ? .indigo : .secondary)
                    .frame(width: 24)
                SecureField("Seed phrase (optional)", text: $vm.seedText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if vm.isCipherEnabled {
                    Button {
                        vm.seedText = ""
                        vm.cipherError = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }

            if vm.isCipherEnabled {
                Label("AES-256-GCM active — messages are encrypted before transmission and decrypted on import.",
                      systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.indigo)
            }

            if let err = vm.cipherError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Label("Cipher", systemImage: "lock.shield")
        } footer: {
            Text("Both sender and receiver must use the same seed phrase. Leave empty to transmit unencrypted.")
                .font(.caption)
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
                Label("Share Audio (M4A)", systemImage: "square.and.arrow.up")
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

    // MARK: - Decode Section

    private var decodeSection: some View {
        Section {
            Button {
                vm.importAndDecodeAudio()
            } label: {
                HStack {
                    Label("Import Audio File", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.purple)
                    Spacer()
                    if vm.isDecoding {
                        ProgressView().tint(.purple)
                    }
                }
            }
            .disabled(vm.isDecoding)

            if let err = vm.decodeError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !vm.decodedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Decoded Text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(vm.decodedText)
                        .font(.body)
                        .textSelection(.enabled)

                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = vm.decodedText
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.blue)

                        Button {
                            vm.inputText = vm.decodedText
                        } label: {
                            Label("Use as Input", systemImage: "arrow.up.doc")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label("Decode Audio", systemImage: "waveform.badge.magnifyingglass")
        } footer: {
            Text("Import an M4A/WAV audio file containing 700 Hz Morse code to decode it back to text.")
                .font(.caption)
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

// MARK: - Morse Table Sheet

private struct MorseTableSheet: View {
    let language: MorseLanguage

    private var entries: [(Character, String)] {
        let codeTable = MorseCode.table(for: language)
        return codeTable
            .filter { $0.key != " " && !$0.value.isEmpty }
            .sorted { lhs, rhs in
                // Letters first, then digits, then punctuation
                let lStr = String(lhs.key)
                let rStr = String(rhs.key)
                return lStr < rStr
            }
    }

    var body: some View {
        NavigationStack {
            List(entries, id: \.0) { char, code in
                HStack {
                    Text(String(char))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 36, alignment: .leading)
                        .foregroundStyle(.primary)
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(morseSymbols(code))
                        .font(.caption)
                        .foregroundStyle(.teal)
                }
            }
            .navigationTitle("\(language.flagEmoji) \(language.rawValue) Morse")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func morseSymbols(_ code: String) -> String {
        code.map { $0 == "." ? "·" : "—" }.joined()
    }
}

#Preview {
    ContentView()
}
