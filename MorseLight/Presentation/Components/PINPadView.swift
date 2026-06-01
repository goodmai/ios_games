import SwiftUI

/// Reusable PIN entry component: dot indicators + standard iOS numpad layout.
/// The parent controls the `entered` binding; when `entered.count == length`
/// the `onComplete` callback fires with the full PIN string.
struct PINPadView: View {
    @Binding var entered: String
    let length: Int
    let dotColor: Color
    let onComplete: (String) -> Void

    init(entered: Binding<String>,
         length: Int = PINManager.pinLength,
         dotColor: Color = .primary,
         onComplete: @escaping (String) -> Void) {
        self._entered = entered
        self.length = length
        self.dotColor = dotColor
        self.onComplete = onComplete
    }

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["",  "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 40) {
            dots
            pad
        }
    }

    // MARK: Dots

    private var dots: some View {
        HStack(spacing: 20) {
            ForEach(0..<length, id: \.self) { i in
                ZStack {
                    Circle()
                        .stroke(dotColor.opacity(0.35), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if i < entered.count {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 12, height: 12)
                            .transition(.scale)
                    }
                }
                .animation(.easeInOut(duration: 0.12), value: entered.count)
            }
        }
    }

    // MARK: Numpad

    private var pad: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(width: 84, height: 70)
                        } else {
                            PINKey(label: key) { handleKey(key) }
                        }
                    }
                }
            }
        }
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            if !entered.isEmpty { entered.removeLast() }
        } else if entered.count < length {
            entered += key
            if entered.count == length {
                onComplete(entered)
            }
        }
    }
}

// MARK: - PINKey button

private struct PINKey: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(label == "⌫" ? .title2 : .title)
                .frame(width: 84, height: 70)
                .background(.secondary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}
