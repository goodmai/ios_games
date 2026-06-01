# CLAUDE.md — iOS Game Development with Swift TDD

> This file is the source of truth for Claude when working in this repository.
> Read it fully before making any code changes.

---

## Project Context

This is a **Swift iOS game project** built on a Clean Architecture + ECS foundation with
strict TDD discipline. Every feature is developed test-first. The codebase targets
iOS 17+ and macOS 14+ (for CI test execution).

**Stack:**
- Swift 5.9+ / Swift 6 strict concurrency
- Swift Package Manager (no CocoaPods, no Carthage)
- Swift Testing framework (`@Test`, `@Suite`) — not XCTest
- SpriteKit for 2D rendering (Xcode only; logic layer is SPM-testable)
- SwiftUI for menus, HUD, settings
- `@Observable` macro (Observation framework, iOS 17+)
- Swift Structured Concurrency (`async/await`, `actor`)

---

## Architecture

```
Sources/GameTemplate/
├── App/                        # Composition root (dependency wiring)
├── Core/                       # Game loop, state machine, engine
├── Domain/
│   ├── Entities/               # Pure value types: Player, Enemy, etc.
│   ├── UseCases/               # Business logic protocols + implementations
│   └── Repositories/           # Data access protocols (interfaces only)
├── Infrastructure/
│   ├── Persistence/            # Repository implementations (SwiftData, memory)
│   └── Audio/                  # AVFoundation / SpriteKit audio wrappers
└── Presentation/
    ├── Game/                   # GameScene (SpriteKit) + GameViewModel
    └── Menu/                   # SwiftUI views + ViewModels
```

**Dependency rule:** outer layers depend inward. Domain never imports Infrastructure.

**Concurrency model:**
- `Domain` types are `Sendable` value types or `actor`
- `GameEngine`, `GameViewModel` run on `@MainActor`
- `ScoreRepository` implementations are `actor`
- Never use `DispatchQueue` — use Swift concurrency exclusively

---

## TDD Workflow — Red → Green → Refactor

### RULE: Tests are written BEFORE implementation.

Every feature goes through exactly three steps:

### Step 1 — RED (Write the failing test)
1. Identify the smallest behavior to implement.
2. Write a `@Test` in the appropriate test file.
3. Run `swift test` — confirm it fails to compile OR fails with a clear assertion error.
4. Do NOT write any production code yet.

```swift
// Example: new feature "enemy takes damage"
@Test("Enemy health decreases when hit")
func enemyTakesDamage() {
    var enemy = Enemy(health: 50)
    enemy.takeDamage(20)
    #expect(enemy.health == 30)
}
// -> Fails: 'Enemy' is undefined  ✓ RED
```

### Step 2 — GREEN (Write minimum code to pass)
1. Write the simplest code that makes the test pass.
2. No over-engineering. No extra methods. No future-proofing.
3. Run `swift test` — all tests must pass.

```swift
// Minimum implementation
struct Enemy {
    var health: Int
    mutating func takeDamage(_ amount: Int) {
        health = max(0, health - amount)
    }
}
// -> All tests pass  ✓ GREEN
```

### Step 3 — REFACTOR (Clean up)
1. Remove duplication. Clarify names. Extract if needed.
2. Run `swift test` after every change — must stay green.
3. Do not add behavior during refactor.

---

## SDLC Phases

### Phase 1: Discovery & Planning
**Goal:** Define what the game is before writing code.

Tasks for Claude:
- Ask: What type of game? (platformer, puzzle, shooter, endless runner, etc.)
- Generate a minimal Game Design Document in `Docs/GDD.md`
- Break the game into user stories in `Docs/Backlog.md`
- Identify the domain entities (Player, Enemy, Level, Obstacle, etc.)
- Identify core use cases (StartGame, PauseGame, CollectItem, TakeDamage, etc.)

Deliverable: `Docs/GDD.md` + `Docs/Backlog.md` with prioritized stories

### Phase 2: Architecture Design
**Goal:** Define layer structure before writing game-specific code.

Tasks for Claude:
- Map user stories to Domain entities and Use Cases
- Define repository protocols for persistence needs
- Define `GamePhase` state machine transitions
- Identify `Sendable` boundaries and concurrency model

Deliverable: updated `Docs/Architecture.md`

### Phase 3: TDD Feature Development (repeating cycle)

For each user story, Claude follows this exact sequence:

```
1. Pick top story from Docs/Backlog.md
2. Write failing test(s) in Tests/
3. swift test → confirm RED
4. Write minimum production code in Sources/
5. swift test → confirm GREEN
6. Refactor if needed → swift test → confirm GREEN
7. Mark story done in Docs/Backlog.md
8. Commit: "test: <story>" then "feat: <story>"
9. Repeat
```

### Phase 4: Integration & Scene Wiring
**Goal:** Connect domain logic to SpriteKit/SwiftUI in Xcode.

This phase happens in Xcode on a Mac. Claude's role:
- Guide SpriteKit `SKScene` setup
- Help wire `GameEngine` to scene update loop
- Help overlay SwiftUI HUD on SpriteKit
- Ensure all wiring is tested via integration tests where possible

### Phase 5: Polish & Release
**Goal:** Performance, accessibility, App Store submission.

Tasks:
- Instruments profiling guidance
- GameplayKit AI integration
- Game Center leaderboards via `GKLeaderboard`
- App Store metadata

---

## How Claude Should Behave

### Starting a session
1. Run `swift test` to verify baseline health.
2. Read `Docs/Backlog.md` for current sprint status.
3. Report: tests passing, next story to implement.

### When asked to add a feature
1. Ask which layer it belongs to (Domain / Infrastructure / Presentation).
2. Write the test first. Show the failing output.
3. Implement minimum code. Show the passing output.
4. Refactor if obvious duplication exists.
5. Never skip the RED step — even for "trivial" features.

### When asked to fix a bug
1. Write a test that reproduces the bug first (it will fail — RED).
2. Fix the bug (GREEN).
3. Ensure no regressions.

### When asked a design question
Answer in 2–3 sentences with a recommendation and the main tradeoff.
Do not implement unless the user agrees.

### Commit conventions
```
test: describe what test covers
feat: describe feature added
fix: describe bug fixed
refactor: describe what was cleaned up
docs: describe doc change
chore: dependency / config / scripts
```

Always separate test commit from implementation commit.

---

## Running the Project

### Full test suite
```bash
swift test
# or
swift Scripts/test.swift
```

### Specific test suite
```bash
swift test --filter PlayerTests
swift test --filter GameEngineTests
swift test --filter "StartGame Use Case"
```

### Watch mode (auto-rerun on file change)
```bash
swift Scripts/test-watch.swift
```

### Linting
```bash
swift Scripts/lint.swift
```

### Build check (no tests)
```bash
swift build
```

### In Xcode (macOS)
```
Cmd+U  → Run all tests
Cmd+R  → Run on simulator
```

---

## Code Rules

### Naming
- Types: `UpperCamelCase`
- Functions/vars: `lowerCamelCase`
- Test suites: describe the type (`@Suite("Player Entity")`)
- Test names: full English sentences (`@Test("Player loses a life when health reaches zero")`)

### Tests
- Use Swift Testing (`import Testing`) — never XCTest in new tests
- One `@Suite` per production type
- Use `@Test` with descriptive strings, not function names alone
- Use `arguments:` for parameterized cases
- Use `MockXxx` naming for test doubles
- Mocks live in `Tests/GameTemplateTests/TestHelpers/`
- Use `TestGameFactory` for object creation to avoid constructor churn

### Production code
- Prefer `struct` over `class` for domain entities
- Use `actor` for shared mutable state
- Use `@MainActor` for UI-touching code
- Protocols drive all cross-layer dependencies
- No `force_unwrap` (`!`) in production code — use `guard` or `throw`
- No `DispatchQueue` — use `async/await`
- No `@objc` in domain layer

### What NOT to do
- Do not add error handling for impossible cases
- Do not add parameters "for future flexibility"
- Do not create abstractions for single use cases
- Do not write comments explaining WHAT the code does — name it well instead
- Do not commit failing tests

---

## Files Claude Must Know About

| File | Purpose |
|------|---------|
| `Package.swift` | SPM manifest — add new targets/dependencies here |
| `Sources/GameTemplate/Core/GameState.swift` | State machine — add phases here |
| `Sources/GameTemplate/Core/GameEngine.swift` | Orchestrator — connects use cases |
| `Sources/GameTemplate/Domain/Entities/` | Add new game entities here |
| `Sources/GameTemplate/Domain/UseCases/` | Add new use cases here |
| `Sources/GameTemplate/Domain/Repositories/` | Add new repository protocols here |
| `Sources/GameTemplate/Infrastructure/Persistence/` | Add repository implementations |
| `Tests/GameTemplateTests/TestHelpers/MockScoreRepository.swift` | Reusable mock |
| `Tests/GameTemplateTests/TestHelpers/TestGameFactory.swift` | Object factory for tests |
| `Docs/Backlog.md` | Current sprint stories |
| `.swiftlint.yml` | Lint rules |

---

## Adding a New Game Entity (Checklist)

- [ ] Create `Sources/GameTemplate/Domain/Entities/MyEntity.swift`
- [ ] Conform to `GameEntity` protocol (or define new protocol)
- [ ] Create `Tests/GameTemplateTests/Domain/Entities/MyEntityTests.swift`
- [ ] Test: construction with defaults
- [ ] Test: all mutations (each method gets at least one test)
- [ ] Test: edge cases (zero, negative, boundary values)
- [ ] Run `swift test` → all green
- [ ] Lint: `swift Scripts/lint.swift`

## Adding a New Use Case (Checklist)

- [ ] Define protocol in `Sources/GameTemplate/Domain/UseCases/`
- [ ] Write tests in `Tests/.../UseCases/` — use mocks for dependencies
- [ ] Implement `struct MyUseCaseImpl` — make tests pass
- [ ] Wire into `GameEngine` if needed
- [ ] Wire into `GameApp.make()` (composition root)
- [ ] Run `swift test` → all green

---

## Sprint Template

Each sprint targets 1–3 user stories. Template in `Docs/Sprints.md`.

Sprint structure:
1. Pick stories from backlog
2. For each story: RED → GREEN → REFACTOR → commit
3. Integration test pass
4. Demo / screenshot
5. Retrospective note in `Docs/Sprints.md`
