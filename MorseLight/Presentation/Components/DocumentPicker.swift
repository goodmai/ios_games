import SwiftUI
import UniformTypeIdentifiers

/// Wraps UIDocumentPickerViewController for SwiftUI.
/// Accepts any audio UTType; security-scoped access is started before handing
/// the URL to the completion handler — caller must call
/// url.stopAccessingSecurityScopedResource() when done.
struct DocumentPicker: UIViewControllerRepresentable {
    let completion: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    // MARK: Coordinator

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let completion: (URL) -> Void

        init(completion: @escaping (URL) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            // Start security scope here; caller owns the stop call.
            _ = url.startAccessingSecurityScopedResource()
            // Bounce to MainActor in case UIKit calls back on a background thread.
            let cb = completion
            Task { await MainActor.run { cb(url) } }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
