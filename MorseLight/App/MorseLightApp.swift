import SwiftUI

@main
struct MorseLightApp: App {

    @State private var pinManager = PINManager()
    @State private var phase: AppPhase = .startup

    private enum AppPhase {
        case startup    // Checking Keychain on first frame
        case setup      // No PINs configured yet
        case locked     // PINs set, awaiting correct entry
        case unlocked   // PIN A verified — main app visible
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch phase {
                case .startup:
                    // Transparent splash while we check Keychain synchronously
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .task {
                            phase = pinManager.isSetup ? .locked : .setup
                        }

                case .setup:
                    PinSetupView(manager: pinManager) {
                        // After setup, unlock immediately — no need to re-enter
                        phase = .unlocked
                    }

                case .locked:
                    PinLockView(manager: pinManager) {
                        phase = .unlocked
                    } onWiped: {
                        phase = .setup
                    }

                case .unlocked:
                    ContentView()
                }
            }
        }
    }
}
