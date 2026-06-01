import Foundation

enum GamePhase: String, Sendable, CaseIterable, Equatable {
    case idle
    case menu
    case playing
    case paused
    case gameOver
    case victory
}

@Observable
final class GameState: @unchecked Sendable {
    private(set) var phase: GamePhase = .idle
    private(set) var session: GameSession?
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isPaused: Bool = false

    private let lock = NSLock()

    var isPlaying: Bool { phase == .playing && !isPaused }
    var hasActiveSession: Bool { session != nil }
    var currentScore: Int { session?.player.score ?? 0 }
    var currentHealth: Int { session?.player.health ?? 0 }
    var currentLives: Int { session?.player.lives ?? 0 }

    func transition(to newPhase: GamePhase) {
        lock.lock()
        defer { lock.unlock() }
        guard isValidTransition(from: phase, to: newPhase) else { return }
        phase = newPhase
    }

    func startSession(_ session: GameSession) {
        lock.lock()
        defer { lock.unlock() }
        self.session = session
        phase = .playing
        elapsedTime = 0
        isPaused = false
    }

    func updateSession(_ updated: GameSession) {
        lock.lock()
        defer { lock.unlock() }
        session = updated
    }

    func pause() {
        lock.lock()
        defer { lock.unlock() }
        guard phase == .playing else { return }
        isPaused = true
        phase = .paused
    }

    func resume() {
        lock.lock()
        defer { lock.unlock() }
        guard phase == .paused else { return }
        isPaused = false
        phase = .playing
    }

    func tick(delta: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        guard phase == .playing else { return }
        elapsedTime += delta
    }

    func endGame() {
        lock.lock()
        defer { lock.unlock() }
        phase = .gameOver
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        session = nil
        phase = .idle
        elapsedTime = 0
        isPaused = false
    }

    private func isValidTransition(from current: GamePhase, to next: GamePhase) -> Bool {
        switch (current, next) {
        case (.idle, .menu): true
        case (.menu, .playing): true
        case (.playing, .paused): true
        case (.playing, .gameOver): true
        case (.playing, .victory): true
        case (.paused, .playing): true
        case (.paused, .menu): true
        case (.gameOver, .menu): true
        case (.gameOver, .idle): true
        case (.victory, .menu): true
        case (.victory, .idle): true
        case (_, .idle): true
        default: false
        }
    }
}
