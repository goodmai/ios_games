import Foundation

protocol GameEngineDelegate: AnyObject, Sendable {
    func gameEngine(_ engine: GameEngine, didChangePhase phase: GamePhase)
    func gameEngine(_ engine: GameEngine, didUpdateScore score: Int)
    func gameEngineDidEndGame(_ engine: GameEngine, finalScore: Int)
}

@MainActor
final class GameEngine {
    private let state: GameState
    private let startGameUseCase: any StartGameUseCase
    private let updateScoreUseCase: any UpdateScoreUseCase

    weak var delegate: (any GameEngineDelegate)?

    init(
        state: GameState,
        startGameUseCase: any StartGameUseCase,
        updateScoreUseCase: any UpdateScoreUseCase
    ) {
        self.state = state
        self.startGameUseCase = startGameUseCase
        self.updateScoreUseCase = updateScoreUseCase
    }

    var currentPhase: GamePhase { state.phase }
    var currentScore: Int { state.currentScore }
    var isPlaying: Bool { state.isPlaying }

    func startGame(playerName: String) async throws {
        let session = try await startGameUseCase.execute(playerName: playerName)
        state.startSession(session)
        delegate?.gameEngine(self, didChangePhase: .playing)
    }

    func awardPoints(_ points: Int) async throws {
        guard var session = state.session else { throw GameError.gameNotStarted }
        try await updateScoreUseCase.execute(session: &session, points: points)
        state.updateSession(session)
        delegate?.gameEngine(self, didUpdateScore: session.player.score)
    }

    func pause() {
        state.pause()
        delegate?.gameEngine(self, didChangePhase: .paused)
    }

    func resume() {
        state.resume()
        delegate?.gameEngine(self, didChangePhase: .playing)
    }

    func endGame() async throws -> ScoreEntry? {
        guard let session = state.session else { return nil }
        let entry = try await updateScoreUseCase.finalize(session: session)
        state.endGame()
        delegate?.gameEngineDidEndGame(self, finalScore: entry.score)
        return entry
    }

    func update(deltaTime: TimeInterval) {
        guard state.isPlaying else { return }
        state.tick(delta: deltaTime)
    }

    func reset() {
        state.reset()
    }
}
