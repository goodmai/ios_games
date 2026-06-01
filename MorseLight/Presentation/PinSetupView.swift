import SwiftUI

/// First-launch four-step PIN setup:
///   1. Enter Access PIN (PIN A)
///   2. Confirm Access PIN
///   3. Enter Duress PIN (PIN B) — must differ from A
///   4. Confirm Duress PIN
struct PinSetupView: View {

    let manager: PINManager
    let onComplete: () -> Void

    @State private var step: Step = .enterA
    @State private var entered  = ""
    @State private var pinA     = ""
    @State private var pinB     = ""
    @State private var error: String?
    @State private var dotColor: Color = .primary

    // MARK: Step

    private enum Step { case enterA, confirmA, enterB, confirmB }

    private var title: String {
        switch step {
        case .enterA:    "Set Access PIN"
        case .confirmA:  "Confirm Access PIN"
        case .enterB:    "Set Duress PIN"
        case .confirmB:  "Confirm Duress PIN"
        }
    }

    private var subtitle: String {
        switch step {
        case .enterA:   "Choose a 6-digit PIN to unlock the app."
        case .confirmA: "Re-enter your access PIN to confirm."
        case .enterB:   "Choose a different PIN. Entering it will erase all app data."
        case .confirmB: "Re-enter your duress PIN to confirm."
        }
    }

    private var isAStep: Bool { step == .enterA || step == .confirmA }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 10) {
                Image(systemName: isAStep ? "lock" : "exclamationmark.shield")
                    .font(.system(size: 48))
                    .foregroundStyle(isAStep ? .indigo : .red)
                    .padding(.bottom, 4)

                Text(title).font(.title2).bold()
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer().frame(height: 32)

            // Error
            if let msg = error {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                Spacer().frame(height: 16)
            }

            PINPadView(entered: $entered, dotColor: dotColor, onComplete: handle)
                .padding(.horizontal, 16)

            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    // MARK: State machine

    private func handle(_ pin: String) {
        switch step {

        case .enterA:
            pinA    = pin
            entered = ""
            error   = nil
            step    = .confirmA

        case .confirmA:
            if pin == pinA {
                entered = ""
                error   = nil
                step    = .enterB
            } else {
                flash(.red) {
                    entered = ""
                    step    = .enterA
                    pinA    = ""
                    error   = "PINs don't match — try again"
                }
            }

        case .enterB:
            if pin == pinA {
                flash(.red) {
                    entered = ""
                    error   = "Duress PIN must differ from Access PIN"
                }
            } else {
                pinB    = pin
                entered = ""
                error   = nil
                step    = .confirmB
            }

        case .confirmB:
            if pin == pinB {
                do {
                    try manager.setup(pinA: pinA, pinB: pinB)
                    onComplete()
                } catch {
                    self.error = error.localizedDescription
                    entered = ""
                }
            } else {
                flash(.red) {
                    entered = ""
                    step    = .enterB
                    pinB    = ""
                    error   = "PINs don't match — try again"
                }
            }
        }
    }

    // Brief red-dot flash before applying state change
    private func flash(_ color: Color, then action: @escaping () -> Void) {
        dotColor = color
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            dotColor = .primary
            action()
        }
    }
}
