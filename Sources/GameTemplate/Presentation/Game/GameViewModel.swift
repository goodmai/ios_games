import Foundation

@Observable
@MainActor
final class GameViewModel {
    private let engine: GameEngine

    private(set) var phase: GamePhase = .idle
    private(set) var score: Int = 0
    private(set) var health: Int = Player.maxHealth
    private(set) var lives: Int = Player.defaultLives
    private(set) var errorMessage: String?
    private(set) var finalEntry: ScoreEntry?

    init(engine: GameEngine) {
        self.engine = engine
    }

    func startGame(playerName: String) {
        Task {
            do {
                try await engine.startGame(playerName: playerName)
                sync()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func pauseGame() {
        engine.pause()
        sync()
    }

    func resumeGame() {
        engine.resume()
        sync()
    }

    func endGame() {
        Task {
            do {
                finalEntry = try await engine.endGame()
                sync()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func resetGame() {
        engine.reset()
        finalEntry = nil
        errorMessage = nil
        sync()
    }

    func dismissError() {
        errorMessage = nil
    }

    private func sync() {
        phase = engine.currentPhase
        score = engine.currentScore
    }
}
