import Testing
import Foundation
@testable import GameTemplate

typealias CGPoint = GameTemplate.CGPoint

@Suite("Player Entity")
struct PlayerTests {

    @Test("New player starts with full health and default lives")
    func newPlayerHasDefaultStats() {
        let player = Player()
        #expect(player.health == Player.maxHealth)
        #expect(player.lives == Player.defaultLives)
        #expect(player.score == 0)
        #expect(player.isActive == true)
        #expect(player.isAlive == true)
    }

    @Test("Player takes damage reducing health")
    func playerTakesDamage() {
        var player = Player()
        player.takeDamage(30)
        #expect(player.health == 70)
        #expect(player.isAlive == true)
    }

    @Test("Player health cannot go below zero")
    func playerHealthFloorIsZero() {
        var player = Player(health: 10)
        player.takeDamage(50)
        #expect(player.health >= 0)
    }

    @Test("Player loses a life when health reaches zero")
    func playerLosesLifeAtZeroHealth() {
        var player = Player(health: 10, lives: 3)
        player.takeDamage(10)
        #expect(player.lives == 2)
        #expect(player.health == Player.maxHealth)
    }

    @Test("Player is dead when lives reach zero")
    func playerIsDeadAtZeroLives() {
        var player = Player(health: 10, lives: 1)
        player.takeDamage(100)
        #expect(player.isAlive == false)
        #expect(player.lives == 0)
    }

    @Test("Player heals up to max health")
    func playerHealsWithinMax() {
        var player = Player(health: 50)
        player.heal(30)
        #expect(player.health == 80)
        player.heal(100)
        #expect(player.health == Player.maxHealth)
    }

    @Test("Dead player cannot be healed")
    func deadPlayerCannotHeal() {
        var player = Player(health: 0, lives: 0)
        player.heal(50)
        #expect(player.health == 0)
    }

    @Test("Player score accumulates correctly")
    func playerScoreAccumulates() {
        var player = Player()
        player.addScore(100)
        player.addScore(50)
        #expect(player.score == 150)
    }

    @Test("Non-positive score is ignored")
    func negativeScoreIgnored() {
        var player = Player()
        player.addScore(0)
        player.addScore(-10)
        #expect(player.score == 0)
    }

    @Test("Player moves by delta")
    func playerMovesToNewPosition() {
        var player = Player(position: CGPoint(x: 10, y: 20))
        player.move(by: CGPoint(x: 5, y: -5))
        #expect(player.position.x == 15)
        #expect(player.position.y == 15)
    }

    @Test("Inactive player does not move")
    func inactivePlayerDoesNotMove() {
        var player = Player(position: CGPoint(x: 10, y: 10))
        player.isActive = false
        player.move(by: CGPoint(x: 5, y: 5))
        #expect(player.position.x == 10)
        #expect(player.position.y == 10)
    }

    @Test("CGPoint distance calculation is correct", arguments: [
        (CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4), 5.0),
        (CGPoint(x: 1, y: 1), CGPoint(x: 1, y: 1), 0.0)
    ])
    func cgPointDistance(from: CGPoint, to: CGPoint, expected: Double) {
        #expect(abs(from.distance(to: to) - expected) < 0.001)
    }
}
