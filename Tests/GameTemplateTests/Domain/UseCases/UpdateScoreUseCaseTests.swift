import Testing
import Foundation
@testable import GameTemplate

@Suite("UpdateScore Use Case")
struct UpdateScoreUseCaseTests {

    @Test("Adding positive score updates session player score")
    func addingPositiveScore() async throws {
        let repo = MockScoreRepository()
        let useCase = TestGameFactory.makeUpdateScoreUseCase(repository: repo)
        var session = TestGameFactory.makeSession()
        try await useCase.execute(session: &session, points: 100)
        #expect(session.player.score == 100)
    }

    @Test("Adding zero points throws invalid score error")
    func zeroPointsThrows() async throws {
        let repo = MockScoreRepository()
        let useCase = TestGameFactory.makeUpdateScoreUseCase(repository: repo)
        var session = TestGameFactory.makeSession()
        await #expect(throws: GameError.invalidScore) {
            try await useCase.execute(session: &session, points: 0)
        }
    }

    @Test("Finalizing game saves score entry to repository")
    func finalizeGameSavesEntry() async throws {
        let repo = MockScoreRepository()
        let useCase = TestGameFactory.makeUpdateScoreUseCase(repository: repo)
        var session = TestGameFactory.makeSession(playerName: "Bob")
        try await useCase.execute(session: &session, points: 500)
        let entry = try await useCase.finalize(session: session)
        #expect(entry.playerName == "Bob")
        #expect(entry.score == 500)
        let saveCount = await repo.saveCallCount
        #expect(saveCount == 1)
    }

    @Test("Multiple score additions accumulate correctly")
    func multipleScoreAdditions() async throws {
        let repo = MockScoreRepository()
        let useCase = TestGameFactory.makeUpdateScoreUseCase(repository: repo)
        var session = TestGameFactory.makeSession()
        try await useCase.execute(session: &session, points: 100)
        try await useCase.execute(session: &session, points: 200)
        try await useCase.execute(session: &session, points: 50)
        #expect(session.player.score == 350)
    }

    @Test("Repository failure propagates on finalize")
    func repositoryFailurePropagates() async throws {
        let repo = MockScoreRepository()
        await repo.setShouldThrowOnSave(true)
        let useCase = TestGameFactory.makeUpdateScoreUseCase(repository: repo)
        let session = TestGameFactory.makeSession()
        await #expect(throws: ScoreRepositoryError.self) {
            try await useCase.finalize(session: session)
        }
    }
}

private extension MockScoreRepository {
    func setShouldThrowOnSave(_ value: Bool) {
        shouldThrowOnSave = value
    }
}
