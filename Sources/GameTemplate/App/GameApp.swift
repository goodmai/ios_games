import Foundation

// Entry point composition root — wire up all dependencies here.
// In a real iOS app this would be marked @main and import SwiftUI.
struct GameApp {
    let state: GameState
    let engine: GameEngine
    let gameViewModel: GameViewModel
    let menuViewModel: MenuViewModel

    static func make() -> GameApp {
        let repository: any ScoreRepository = InMemoryScoreRepository()
        let state = GameState()

        let startUseCase = StartGameUseCaseImpl()
        let updateScoreUseCase = UpdateScoreUseCaseImpl(repository: repository)

        let engine = GameEngine(
            state: state,
            startGameUseCase: startUseCase,
            updateScoreUseCase: updateScoreUseCase
        )

        return GameApp(
            state: state,
            engine: engine,
            gameViewModel: GameViewModel(engine: engine),
            menuViewModel: MenuViewModel(repository: repository)
        )
    }
}
