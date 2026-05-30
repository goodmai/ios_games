import Foundation

@Observable
@MainActor
final class MenuViewModel {
    private let repository: any ScoreRepository

    private(set) var topScores: [ScoreEntry] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    var playerName: String = ""
    var isReadyToStart: Bool { !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    init(repository: any ScoreRepository) {
        self.repository = repository
    }

    func loadTopScores() {
        isLoading = true
        Task {
            do {
                topScores = try await repository.fetchTopScores(limit: 10)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
