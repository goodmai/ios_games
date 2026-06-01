import Foundation

actor InMemoryScoreRepository: ScoreRepository {
    private var entries: [ScoreEntry] = []

    func save(_ entry: ScoreEntry) async throws {
        entries.append(entry)
    }

    func fetchTopScores(limit: Int) async throws -> [ScoreEntry] {
        Array(entries.sorted(by: >).prefix(limit))
    }

    func fetchAllScores() async throws -> [ScoreEntry] {
        entries.sorted(by: >)
    }

    func clear() async throws {
        entries.removeAll()
    }
}
