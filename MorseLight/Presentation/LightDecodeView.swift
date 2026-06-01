import SwiftUI
import AVFoundation

/// Camera-based light decoder screen (Epic E3): point the camera at a blinking
/// torch, capture the brightness timeline, and decode it to text.
struct LightDecodeView: View {
    @State private var model = LightDecodeViewModel()
    let language: MorseLanguage

    var body: some View {
        VStack(spacing: 16) {
            CameraPreview(session: model.session)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .center) {
                    if model.isCapturing {
                        Image(systemName: "dot.viewfinder")
                            .font(.system(size: 44))
                            .foregroundStyle(.teal)
                            .symbolEffect(.pulse)
                    }
                }
                .padding(.horizontal)

            Button {
                model.toggle(language: language)
            } label: {
                Label(model.isCapturing ? "Stop & Decode" : "Start Capture",
                      systemImage: model.isCapturing ? "stop.circle.fill" : "record.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(model.isCapturing ? .red : .teal)
            .accessibilityIdentifier("lightCaptureButton")
            .padding(.horizontal)

            if !model.decodedText.isEmpty {
                VStack(spacing: 4) {
                    Text("Decoded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(model.decodedText)
                        .font(.title3.monospaced())
                        .textSelection(.enabled)
                        .accessibilityIdentifier("lightDecodedText")
                }
            }

            if let err = model.errorMessage {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(.top)
        .navigationTitle("Decode Light")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { model.cancel() }
    }
}

@Observable
@MainActor
final class LightDecodeViewModel {
    var isCapturing = false
    var decodedText = ""
    var errorMessage: String?

    private let capture = CameraLightCapture()
    var session: AVCaptureSession { capture.captureSession }

    func toggle(language: MorseLanguage) {
        if isCapturing {
            decodedText = capture.stopAndDecode(language: language)
            if decodedText.isEmpty { decodedText = "(no light Morse detected)" }
            isCapturing = false
        } else {
            guard capture.isAvailable else {
                errorMessage = "Camera unavailable on this device"
                return
            }
            do {
                errorMessage = nil
                decodedText = ""
                try capture.start()
                isCapturing = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancel() {
        if isCapturing {
            _ = capture.stopAndDecode(language: .english)
            isCapturing = false
        }
    }
}

// MARK: - Camera preview bridge

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
</content>
