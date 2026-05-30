import Foundation

protocol UpdateScoreUseCase: Sendable {
    func execute(session: inout GameSession, points: Int) async throws
    func finalize(session: GameSession) async throws -> ScoreEntry
}

struct UpdateScoreUseCaseImpl: UpdateScoreUseCase {
    let repository: ScoreRepository

    func execute(session: inout GameSession, points: Int) async throws {
        guard points > 0 else { throw GameError.invalidScore }
        session.player.addScore(points)
    }

    func finalize(session: GameSession) async throws -> ScoreEntry {
        let entry = ScoreEntry(
            playerName: session.playerName,
            score: session.player.score
        )
        try await repository.save(entry)
        return entry
    }
}
