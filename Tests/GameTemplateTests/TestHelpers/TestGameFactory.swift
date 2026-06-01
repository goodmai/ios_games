import Foundation
@testable import GameTemplate

enum TestGameFactory {
    static func makePlayer(
        health: Int = Player.maxHealth,
        lives: Int = Player.defaultLives,
        score: Int = 0
    ) -> Player {
        var player = Player(health: health, lives: lives)
        if score > 0 { player.addScore(score) }
        return player
    }

    static func makeSession(playerName: String = "TestPlayer") -> GameSession {
        GameSession(playerName: playerName)
    }

    static func makeRepository() -> MockScoreRepository {
        MockScoreRepository()
    }

    static func makeStartUseCase() -> StartGameUseCaseImpl {
        StartGameUseCaseImpl()
    }

    static func makeUpdateScoreUseCase(repository: any ScoreRepository) -> UpdateScoreUseCaseImpl {
        UpdateScoreUseCaseImpl(repository: repository)
    }

    @MainActor
    static func makeEngine(repository: any ScoreRepository = MockScoreRepository()) -> GameEngine {
        GameEngine(
            state: GameState(),
            startGameUseCase: makeStartUseCase(),
            updateScoreUseCase: makeUpdateScoreUseCase(repository: repository)
        )
    }
}
