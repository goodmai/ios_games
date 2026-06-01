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

/// Flashes `... --- ...` on the device torch. Runs in the control's extension
/// process via `FlashlightController` + `MorseConverter`.
@available(iOS 18.0, *)
struct SendSOSIntent: AppIntent {

    static let title: LocalizedStringResource = "Send SOS via Torch"
    static let description = IntentDescription("Transmits SOS in Morse code using the device torch.")

    func perform() async throws -> some IntentResult {
        let torch = FlashlightController()
        guard torch.isAvailable else { return .result() }

        let signals = MorseConverter().signals(for: "SOS")
        defer { torch.turnOff() }
        for signal in signals {
            switch signal {
            case .on(let duration):
                try? torch.setOn(true)
                try? await Task.sleep(for: .seconds(duration))
            case .off(let duration):
                torch.turnOff()
                try? await Task.sleep(for: .seconds(duration))
            }
        }
        return .result()
    }
}
#endif
</content>
