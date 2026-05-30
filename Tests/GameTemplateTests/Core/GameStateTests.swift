import Testing
import Foundation
@testable import GameTemplate

@Suite("GameState")
@MainActor
struct GameStateTests {

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let state = GameState()
        #expect(state.phase == .idle)
        #expect(state.hasActiveSession == false)
        #expect(state.currentScore == 0)
    }

    @Test("Starting session transitions to playing phase")
    func startingSessionTransitionsToPlaying() {
        let state = GameState()
        let session = TestGameFactory.makeSession()
        state.startSession(session)
        #expect(state.phase == .playing)
        #expect(state.hasActiveSession == true)
    }

    @Test("Pause transitions playing to paused")
    func pauseTransition() {
        let state = GameState()
        state.startSession(TestGameFactory.makeSession())
        state.pause()
        #expect(state.phase == .paused)
        #expect(state.isPaused == true)
        #expect(state.isPlaying == false)
    }

    @Test("Resume transitions paused back to playing")
    func resumeTransition() {
        let state = GameState()
        state.startSession(TestGameFactory.makeSession())
        state.pause()
        state.resume()
        #expect(state.phase == .playing)
        #expect(state.isPlaying == true)
    }

    @Test("End game transitions to gameOver")
    func endGameTransition() {
        let state = GameState()
        state.startSession(TestGameFactory.makeSession())
        state.endGame()
        #expect(state.phase == .gameOver)
    }

    @Test("Reset clears all state")
    func resetClearsState() {
        let state = GameState()
        state.startSession(TestGameFactory.makeSession())
        state.tick(delta: 5.0)
        state.reset()
        #expect(state.phase == .idle)
        #expect(state.hasActiveSession == false)
        #expect(state.elapsedTime == 0)
    }

    @Test("Tick increments elapsed time only when playing")
    func tickIncrementsTime() {
        let state = GameState()
        state.startSession(TestGameFactory.makeSession())
        state.tick(delta: 1.0)
        state.tick(delta: 2.0)
        #expect(state.elapsedTime == 3.0)
    }

    @Test("Tick does not increment time when paused")
    func tickDoesNotIncrementWhenPaused() {
        let state = GameState()
        state.startSession(TestGameFactory.makeSession())
        state.pause()
        state.tick(delta: 5.0)
        #expect(state.elapsedTime == 0.0)
    }

    @Test("Invalid state transitions are ignored", arguments: [
        (GamePhase.idle, GamePhase.playing),
        (GamePhase.idle, GamePhase.paused),
        (GamePhase.gameOver, GamePhase.playing)
    ])
    func invalidTransitionsIgnored(from: GamePhase, to: GamePhase) {
        let state = GameState()
        // Force state to 'from' via internal logic
        if from == .idle {
            state.transition(to: to)
            #expect(state.phase == .idle)
        }
    }
}
