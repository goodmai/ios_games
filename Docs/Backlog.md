# Product Backlog

> Stories are prioritized top-to-bottom. Implement in order.
> Status: [ ] TODO  [x] DONE  [~] IN PROGRESS

---

## Sprint 1 — Foundation (Template baseline)

- [x] Project structure and Package.swift
- [x] GameEntity protocol and CGPoint value type
- [x] Player entity with health, lives, score, movement
- [x] GamePhase state machine (GameState)
- [x] GameSession value type
- [x] StartGame use case
- [x] UpdateScore use case
- [x] ScoreRepository protocol + InMemory implementation
- [x] GameEngine orchestrator
- [x] GameLoop fixed-timestep timer
- [x] AudioManager actor
- [x] GameViewModel (Observation)
- [x] MenuViewModel (Observation)
- [x] Composition root (GameApp.make)

---

## Sprint 2 — Your First Game Feature

> Replace this section with your game-specific stories.
> Each story should be small enough to implement in one TDD cycle (< 2 hours).

### Example: Endless Runner

- [ ] **[Story 2.1]** Player auto-moves right at constant speed
  - Acceptance: Player position.x increases by `speed * deltaTime` each tick
  - Tests: `PlayerMovementTests.swift`

- [ ] **[Story 2.2]** Obstacle spawns at the right edge of the world
  - Acceptance: `ObstacleSpawner` creates `Obstacle` at x = worldWidth
  - Tests: `ObstacleSpawnerTests.swift`

- [ ] **[Story 2.3]** Player can jump (single jump, gravity pulls down)
  - Acceptance: pressing jump sets upward velocity; gravity reduces it each tick
  - Tests: `JumpMechanicTests.swift`

- [ ] **[Story 2.4]** Collision with obstacle ends the game
  - Acceptance: when player overlaps obstacle, `GameEngine.endGame()` is called
  - Tests: `CollisionTests.swift`

- [ ] **[Story 2.5]** Score increases by 1 every 10 meters traveled
  - Acceptance: score increments at the correct distance milestone
  - Tests: `DistanceScoreTests.swift`

---

## Backlog (Future Sprints)

- [ ] Enemy AI that follows player (GameplayKit)
- [ ] Power-up pickup increases speed temporarily
- [ ] Game Center leaderboard integration
- [ ] Settings screen: mute audio, change controls
- [ ] Haptic feedback on collision (CoreHaptics)
- [ ] iCloud save sync (CloudKit)
- [ ] Accessibility: VoiceOver support for menus

---

## Done

See Sprint 1 above.
