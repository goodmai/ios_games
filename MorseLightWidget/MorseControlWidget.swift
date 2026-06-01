#if canImport(WidgetKit) && canImport(AppIntents)
import WidgetKit
import SwiftUI
import AppIntents

/// iOS 18 Control Center control: a one-tap "SOS via torch" button matching the
/// system's `ControlWidget` pattern (Epic E4). Verified on device (CTL-01, CTL-02).
@available(iOS 18.0, *)
struct MorseTorchControl: ControlWidget {

    static let kind = "com.goodmai.MorseLight.torchControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: SendSOSIntent()) {
                Label("SOS", systemImage: "flashlight.on.fill")
            }
        }
        .displayName("Morse SOS")
        .description("Flash an SOS distress signal with the torch.")
    }
}

/// Flashes `... --- ...` on the device torch.
///
/// `openAppWhenRun` moves the actual transmission into the foreground app
/// process: a Control Center extension has a strict CPU/Watchdog budget, and a
/// multi-second SOS would risk the system terminating the control. The app has no
/// such limit. Timing uses `TorchMorseTransmitter`'s absolute-deadline scheduler
/// so a long signal does not drift.
@available(iOS 18.0, *)
struct SendSOSIntent: AppIntent {

    static let title: LocalizedStringResource = "Send SOS via Torch"
    static let description = IntentDescription("Transmits SOS in Morse code using the device torch.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let signals = MorseConverter().signals(for: "SOS")
        await TorchMorseTransmitter().transmit(signals: signals)
        return .result()
    }
}
#endif
</content>
