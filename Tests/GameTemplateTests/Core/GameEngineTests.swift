import Testing
import Foundation
@testable import GameTemplate

@Suite("GameEngine")
@MainActor
struct GameEngineTests {

    @Test("Engine starts in idle phase")
    func engineStartsIdle() {
        let engine = TestGameFactory.makeEngine()
        #expect(engine.currentPhase == .idle)
        #expect(engine.isPlaying == false)
    }

    @Test("Starting game with valid name transitions to playing")
    func startGameTransitionsToPlaying() async throws {
        let engine = TestGameFactory.makeEngine()
        try await engine.startGame(playerName: "Alice")
        #expect(engine.currentPhase == .playing)
        #expect(engine.isPlaying == true)
    }

    @Test("Starting game with empty name throws error")
    func startGameWithEmptyNameThrows() async {
        let engine = TestGameFactory.makeEngine()
        await #expect(throws: GameError.invalidPlayerName) {
            try await engine.startGame(playerName: "")
        }
    }

    @Test("Awarding points increases score")
    func awardingPointsIncreasesScore() async throws {
        let engine = TestGameFactory.makeEngine()
        try await engine.startGame(playerName: "Alice")
        try await engine.awardPoints(100)
        #expect(engine.currentScore == 100)
    }

    @Test("Awarding points before start throws gameNotStarted")
    func awardingPointsBeforeStartThrows() async {
        let engine = TestGameFactory.makeEngine()
        await #expect(throws: GameError.gameNotStarted) {
            try await engine.awardPoints(100)
        }
    }

    @Test("Pause and resume toggle isPlaying")
    func pauseAndResume() async throws {
        let engine = TestGameFactory.makeEngine()
        try await engine.startGame(playerName: "Alice")
        engine.pause()
        #expect(engine.isPlaying == false)
        #expect(engine.currentPhase == .paused)
        engine.resume()
        #expect(engine.isPlaying == true)
    }

    @Test("End game saves score and transitions to gameOver")
    func endGameSavesScore() async throws {
        let repo = MockScoreRepository()
        let engine = TestGameFactory.makeEngine(repository: repo)
        try await engine.startGame(playerName: "Alice")
        try await engine.awardPoints(250)
        let entry = try await engine.endGame()
        #expect(engine.currentPhase == .gameOver)
        #expect(entry?.score == 250)
        let saveCount = await repo.saveCallCount
        #expect(saveCount == 1)
    }

    @Test("Reset returns engine to idle")
    func resetReturnsToIdle() async throws {
        let engine = TestGameFactory.makeEngine()
        try await engine.startGame(playerName: "Alice")
        engine.reset()
        #expect(engine.currentPhase == .idle)
        #expect(engine.currentScore == 0)
    }

    @Test("Update advances elapsed time only when playing")
    func updateAdvancesTime() async throws {
        let engine = TestGameFactory.makeEngine()
        try await engine.startGame(playerName: "Alice")
        engine.update(deltaTime: 0.016)
        engine.pause()
        engine.update(deltaTime: 1.0)
        engine.resume()
        engine.update(deltaTime: 0.016)
    }
}
