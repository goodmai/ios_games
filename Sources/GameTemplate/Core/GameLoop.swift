import Foundation

protocol GameLoopDelegate: AnyObject, Sendable {
    @MainActor func gameLoop(_ loop: GameLoop, didTick deltaTime: TimeInterval)
}

@MainActor
final class GameLoop {
    weak var delegate: (any GameLoopDelegate)?

    private var displayLink: Timer?
    private var lastTimestamp: TimeInterval = 0
    private(set) var isRunning = false

    let targetFPS: Double
    var interval: TimeInterval { 1.0 / targetFPS }

    init(targetFPS: Double = 60.0) {
        self.targetFPS = targetFPS
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        lastTimestamp = Date.timeIntervalSinceReferenceDate
        displayLink = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
        lastTimestamp = 0
    }

    private func tick() {
        let now = Date.timeIntervalSinceReferenceDate
        let delta = lastTimestamp == 0 ? interval : min(now - lastTimestamp, 0.1)
        lastTimestamp = now
        delegate?.gameLoop(self, didTick: delta)
    }
}
