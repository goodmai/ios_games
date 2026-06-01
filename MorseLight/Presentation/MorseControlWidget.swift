#if canImport(WidgetKit) && canImport(AppIntents)
import WidgetKit
import SwiftUI
import AppIntents

/// iOS 18 Control Center control: a one-tap "SOS via torch" button matching the
/// system's new `ControlWidget` pattern. UI/integration surface — verified by
/// manual checks (CTL-01, CTL-02); the torch wiring lands in Phase 4.
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

/// App Intent invoked by the control. Phase 4 wires this to the flashlight
/// transmitter so it blinks `... --- ...` via `MorseConverter` + `FlashlightController`.
@available(iOS 18.0, *)
struct SendSOSIntent: AppIntent {

    static let title: LocalizedStringResource = "Send SOS via Torch"
    static let description = IntentDescription("Transmits SOS in Morse code using the device torch.")

    func perform() async throws -> some IntentResult {
        // TODO(Phase 4): inject the transmitter and play MorseConverter().signals(for: "SOS").
        return .result()
    }
}
#endif
</content>
