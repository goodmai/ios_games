import Foundation

struct ScoreEntry: Sendable, Identifiable, Comparable {
    let id: UUID
    let playerName: String
    let score: Int
    let date: Date

    init(id: UUID = UUID(), playerName: String, score: Int, date: Date = Date()) {
        self.id = id
        self.playerName = playerName
        self.score = score
        self.date = date
    }

    static func < (lhs: ScoreEntry, rhs: ScoreEntry) -> Bool {
        lhs.score < rhs.score
    }
}

protocol ScoreRepository: Sendable {
    func save(_ entry: ScoreEntry) async throws
    func fetchTopScores(limit: Int) async throws -> [ScoreEntry]
    func fetchAllScores() async throws -> [ScoreEntry]
    func clear() async throws
}

enum ScoreRepositoryError: Error, LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .saveFailed(let msg): "Failed to save score: \(msg)"
        case .fetchFailed(let msg): "Failed to fetch scores: \(msg)"
        case .notFound: "Score not found"
        }
    }
}
