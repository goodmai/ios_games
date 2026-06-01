import Foundation
@testable import GameTemplate

actor MockScoreRepository: ScoreRepository {
    private var storedEntries: [ScoreEntry] = []
    var shouldThrowOnSave = false
    var shouldThrowOnFetch = false

    var saveCallCount: Int = 0
    var lastSavedEntry: ScoreEntry?

    func save(_ entry: ScoreEntry) async throws {
        if shouldThrowOnSave {
            throw ScoreRepositoryError.saveFailed("Mock save failure")
        }
        saveCallCount += 1
        lastSavedEntry = entry
        storedEntries.append(entry)
    }

    func fetchTopScores(limit: Int) async throws -> [ScoreEntry] {
        if shouldThrowOnFetch {
            throw ScoreRepositoryError.fetchFailed("Mock fetch failure")
        }
        return Array(storedEntries.sorted(by: >).prefix(limit))
    }

    func fetchAllScores() async throws -> [ScoreEntry] {
        if shouldThrowOnFetch {
            throw ScoreRepositoryError.fetchFailed("Mock fetch failure")
        }
        return storedEntries.sorted(by: >)
    }

    func clear() async throws {
        storedEntries.removeAll()
        saveCallCount = 0
        lastSavedEntry = nil
    }
}
