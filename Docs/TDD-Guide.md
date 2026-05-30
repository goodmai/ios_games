# TDD Guide for iOS Game Development

## Why TDD for Games?

Game logic is surprisingly complex: collision detection, state machines, scoring rules,
physics interactions, AI behavior. TDD forces you to define exact expected behavior
*before* coding it, catching bugs that would otherwise hide in rendering noise.

## The Three Laws of TDD

1. **You may not write production code unless it is to make a failing test pass.**
2. **You may not write more of a test than is sufficient to fail.**
3. **You may not write more production code than is sufficient to pass the currently failing test.**

## Red → Green → Refactor in Detail

### RED Phase — Write the Smallest Failing Test

```swift
// Bad: testing too many things at once
@Test("Player works correctly")
func playerWorks() {
    var player = Player()
    player.takeDamage(30)
    player.heal(10)
    player.addScore(100)
    #expect(player.health == 80)
    #expect(player.score == 100)
}

// Good: one behavior per test
@Test("Player health decreases by damage amount")
func playerHealthDecreasesByDamageAmount() {
    var player = Player(health: 100)
    player.takeDamage(30)
    #expect(player.health == 70)
}
```

Verify the test fails for the **right reason**:
- Compile error = type doesn't exist yet → OK
- Assertion failure with clear message → OK
- Wrong assertion failure → rewrite the test

### GREEN Phase — Minimum Code to Pass

```swift
// First pass — this is fine for GREEN
struct Player {
    var health: Int = 100
    mutating func takeDamage(_ amount: Int) {
        health -= amount
    }
}
```

Do NOT add edge case handling, validation, or extra methods during GREEN.
Add them when a test demands it.

### REFACTOR Phase — Clean Without Changing Behavior

Signs you need to refactor:
- Duplication between test setups → extract to `TestGameFactory`
- Magic numbers → name them (`Player.maxHealth`)
- Long method → extract private helper
- Weak name → rename for clarity

After every refactor step: `swift test` must still pass.

## Testing Patterns

### Parameterized Tests (many inputs, one behavior)

```swift
@Test("Damage cannot reduce health below zero", arguments: [
    (100, 200, 0),
    (50, 50, 0),
    (10, 5, 5)
])
func damageFloorIsZero(startHealth: Int, damage: Int, expectedHealth: Int) {
    var player = Player(health: startHealth)
    player.takeDamage(damage)
    #expect(player.health == expectedHealth)
}
```

### Async Tests

```swift
@Test("Use case saves score to repository")
func useCaseSavesScore() async throws {
    let repo = MockScoreRepository()
    let useCase = UpdateScoreUseCaseImpl(repository: repo)
    var session = GameSession(playerName: "Alice")
    try await useCase.execute(session: &session, points: 100)
    let count = await repo.saveCallCount
    #expect(count == 0)  // save happens on finalize, not execute
}
```

### Testing Errors

```swift
@Test("Empty name throws invalidPlayerName")
func emptyNameThrows() async {
    let useCase = StartGameUseCaseImpl()
    await #expect(throws: GameError.invalidPlayerName) {
        try await useCase.execute(playerName: "")
    }
}
```

### Testing State Machines

Test each valid and invalid transition explicitly:

```swift
@Test("Cannot pause when not playing")
func cannotPauseWhenIdle() {
    let state = GameState()
    // state is .idle
    state.pause()
    #expect(state.phase == .idle)  // transition rejected
}
```

## Test Organization

```
Tests/GameTemplateTests/
├── Core/
│   ├── GameStateTests.swift     — one @Suite per production file
│   └── GameEngineTests.swift
├── Domain/
│   ├── Entities/
│   │   └── PlayerTests.swift
│   └── UseCases/
│       ├── StartGameUseCaseTests.swift
│       └── UpdateScoreUseCaseTests.swift
└── TestHelpers/
    ├── MockScoreRepository.swift
    └── TestGameFactory.swift
```

Rules:
- One `@Suite` struct per production type
- One `@Test` per behavior (not per method)
- Arrange → Act → Assert structure in every test
- No logic in tests (no `if`, `for`, `switch`) — use `arguments:` instead
- `TestGameFactory` for all object construction — avoids brittle constructor calls

## Test Naming Convention

Format: `[Subject] [action] [outcome]`

```swift
// Good
@Test("Player loses a life when health reaches zero")
@Test("Empty player name throws error")
@Test("Score accumulates across multiple awards")

// Bad
@Test("testPlayerHealth")
@Test("test1")
@Test("it works")
```

## Common Game TDD Scenarios

### Collision Detection
```swift
@Test("Player collides with enemy when within collision radius")
func collisionDetectedWithinRadius() {
    let player = Player(position: CGPoint(x: 0, y: 0))
    let enemy = Enemy(position: CGPoint(x: 10, y: 0), collisionRadius: 15)
    #expect(enemy.collides(with: player))
}

@Test("No collision when outside radius")
func noCollisionOutsideRadius() {
    let player = Player(position: CGPoint(x: 0, y: 0))
    let enemy = Enemy(position: CGPoint(x: 20, y: 0), collisionRadius: 15)
    #expect(!enemy.collides(with: player))
}
```

### Scoring Rules
```swift
@Test("Combo multiplier doubles score for 5 consecutive hits")
func comboMultiplierDoublesScore() {
    var session = GameSession(playerName: "Alice")
    for _ in 0..<5 { session.registerHit() }
    session.player.addScore(100)
    #expect(session.player.score == 200)
}
```

### Physics / Movement
```swift
@Test("Player cannot move beyond left boundary")
func playerBoundaryLeft() {
    var player = Player(position: CGPoint(x: 5, y: 0))
    let world = GameWorld(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
    world.move(player: &player, by: CGPoint(x: -10, y: 0))
    #expect(player.position.x >= 0)
}
```

## What NOT to Test

- Private implementation details (test via public API)
- SpriteKit node positions (test the data, not the rendering)
- Third-party library internals
- Rendering / animations
- Random number generation outcomes (inject a seeded RNG)

## Test Speed Budget

Tests must run in **< 5 seconds** total. If they slow down:
- Check for `sleep()` or real `Date()` usage in tests — use injected clocks
- Move slow integration tests to a separate target
- Use `InMemoryScoreRepository` instead of disk-based in tests
