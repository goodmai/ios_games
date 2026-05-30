import Foundation

struct Player: GameEntity {
    let id: EntityID
    var position: CGPoint
    var isActive: Bool
    var health: Int
    var score: Int
    var lives: Int
    var speed: Double

    static let maxHealth = 100
    static let defaultLives = 3
    static let defaultSpeed = 5.0

    init(
        id: EntityID = UUID(),
        position: CGPoint = .zero,
        health: Int = maxHealth,
        lives: Int = defaultLives,
        speed: Double = defaultSpeed
    ) {
        self.id = id
        self.position = position
        self.isActive = true
        self.health = health
        self.score = 0
        self.lives = lives
        self.speed = speed
    }

    var isAlive: Bool { health > 0 && lives > 0 }

    mutating func takeDamage(_ amount: Int) {
        guard amount > 0 else { return }
        health = max(0, health - amount)
        if health == 0 {
            lives -= 1
            if lives > 0 { health = Player.maxHealth }
        }
    }

    mutating func heal(_ amount: Int) {
        guard amount > 0, isAlive else { return }
        health = min(Player.maxHealth, health + amount)
    }

    mutating func addScore(_ points: Int) {
        guard points > 0 else { return }
        score += points
    }

    mutating func move(by delta: CGPoint) {
        guard isActive else { return }
        position = position + delta
    }
}
