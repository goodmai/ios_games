import SwiftUI

/// Lock screen shown on every app launch after PINs are configured.
/// PIN A → unlock. PIN B → wipe all data. 10 wrong attempts → wipe all data.
struct PinLockView: View {

    let manager: PINManager
    let onUnlocked: () -> Void
    let onWiped:    () -> Void

    @State private var entered:    String  = ""
    @State private var errorText:  String? = nil
    @State private var dotColor:   Color   = .primary
    @State private var wipeShown:  Bool    = false

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App identity
            VStack(spacing: 8) {
                Image(systemName: wipeShown ? "trash.fill" : "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(wipeShown ? .red : .indigo)
                    .animation(.easeInOut, value: wipeShown)
                Text("MorseLight")
                    .font(.title2).bold()
                Text(wipeShown ? "All data erased" : "Enter your PIN")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 24)

            // Attempt counter (shown after first failure)
            if manager.failedAttempts > 0 && !wipeShown {
                let left = PINManager.maxAttempts - manager.failedAttempts
                Text("\(left) attempt\(left == 1 ? "" : "s") remaining")
                    .font(.caption)
                    .foregroundStyle(left <= 3 ? .red : .orange)
                    .padding(.bottom, 8)
            }

            // Error text
            if let msg = errorText {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .transition(.opacity)
                    .padding(.bottom, 8)
            }

            if !wipeShown {
                PINPadView(entered: $entered, dotColor: dotColor, onComplete: handle)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: wipeShown)
    }

    // MARK: PIN handler

    private func handle(_ pin: String) {
        let result = manager.verify(pin: pin)

        switch result {
        case .unlocked:
            entered = ""
            errorText = nil
            onUnlocked()

        case .wiped:
            entered = ""
            errorText = nil
            wipeShown = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                onWiped()
            }

        case .wrong(let left):
            flash(.red) {
                entered   = ""
                errorText = left > 0 ? "Incorrect PIN" : nil
            }
        }
    }

    private func flash(_ color: Color, then action: @escaping () -> Void) {
        dotColor = color
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            dotColor = .primary
            action()
        }
    }
}
