import Testing
import Foundation
@testable import GameTemplate

@Suite("StartGame Use Case")
struct StartGameUseCaseTests {

    @Test("Starting game with valid name creates session")
    func startGameCreatesSession() async throws {
        let useCase = TestGameFactory.makeStartUseCase()
        let session = try await useCase.execute(playerName: "Alice")
        #expect(session.playerName == "Alice")
        #expect(session.player.isAlive == true)
        #expect(session.player.score == 0)
    }

    @Test("Empty player name throws error")
    func emptyNameThrows() async {
        let useCase = TestGameFactory.makeStartUseCase()
        await #expect(throws: GameError.invalidPlayerName) {
            try await useCase.execute(playerName: "")
        }
    }

    @Test("Whitespace-only player name throws error")
    func whitespaceNameThrows() async {
        let useCase = TestGameFactory.makeStartUseCase()
        await #expect(throws: GameError.invalidPlayerName) {
            try await useCase.execute(playerName: "   ")
        }
    }

    @Test("Each game session has a unique ID")
    func sessionsHaveUniqueIDs() async throws {
        let useCase = TestGameFactory.makeStartUseCase()
        let session1 = try await useCase.execute(playerName: "Alice")
        let session2 = try await useCase.execute(playerName: "Alice")
        #expect(session1.id != session2.id)
    }
}
