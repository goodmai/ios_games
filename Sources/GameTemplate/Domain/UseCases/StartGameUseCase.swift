import Foundation

protocol StartGameUseCase: Sendable {
    func execute(playerName: String) async throws -> GameSession
}

struct GameSession: Sendable, Identifiable {
    let id: UUID
    let playerName: String
    var player: Player
    let startTime: Date

    init(playerName: String) {
        self.id = UUID()
        self.playerName = playerName
        self.player = Player()
        self.startTime = Date()
    }
}

struct StartGameUseCaseImpl: StartGameUseCase {
    func execute(playerName: String) async throws -> GameSession {
        guard !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GameError.invalidPlayerName
        }
        return GameSession(playerName: playerName)
    }
}

enum GameError: Error, LocalizedError, Equatable {
    case invalidPlayerName
    case gameNotStarted
    case gameAlreadyOver
    case invalidScore

    var errorDescription: String? {
        switch self {
        case .invalidPlayerName: "Player name cannot be empty"
        case .gameNotStarted: "Game has not been started yet"
        case .gameAlreadyOver: "Game is already over"
        case .invalidScore: "Score value is invalid"
        }
    }
}
