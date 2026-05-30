# Architecture

## Overview

This project follows **Clean Architecture** with an **Entity-Component-System (ECS)** influence
for game entities and a **MVVM** pattern for the presentation layer.

## Layer Diagram

```
┌────────────────────────────────────────────┐
│             Presentation Layer              │
│                                            │
│  SwiftUI Views ◄──── @Observable VMs       │
│  SpriteKit Scenes ──► GameEngine           │
│                                            │
│  Runs on: @MainActor                       │
└─────────────────────┬──────────────────────┘
                      │ uses
┌─────────────────────▼──────────────────────┐
│                 Core Layer                  │
│                                            │
│  GameEngine    — orchestrates use cases     │
│  GameState     — phase state machine        │
│  GameLoop      — fixed-timestep updates     │
│                                            │
│  Runs on: @MainActor                       │
└─────────────────────┬──────────────────────┘
                      │ calls
┌─────────────────────▼──────────────────────┐
│               Domain Layer                  │
│                                            │
│  Entities   — Player, Enemy (structs)       │
│  UseCases   — StartGame, UpdateScore, …     │
│  Repos      — ScoreRepository (protocol)    │
│                                            │
│  Runs on: Sendable (no actor needed)       │
└─────────────────────┬──────────────────────┘
                      │ implemented by
┌─────────────────────▼──────────────────────┐
│            Infrastructure Layer             │
│                                            │
│  InMemoryScoreRepository (actor)            │
│  SwiftDataScoreRepository (actor)           │
│  AudioManager (actor)                       │
│                                            │
│  Runs on: actor (Swift Concurrency)        │
└────────────────────────────────────────────┘
```

## Dependency Rule

> Source code dependencies point **inward only**.

- Presentation depends on Core and Domain
- Core depends on Domain
- Infrastructure depends on Domain (implements its protocols)
- Domain depends on nothing (no imports from other layers)

This makes Domain 100% testable without any framework.

## Concurrency Model

| Type | Isolation | Rationale |
|------|-----------|-----------|
| Domain Entities | `Sendable` structs | Value semantics — safe by default |
| Use Case Impls | `Sendable` structs | Stateless — thread safe |
| Repository Protocols | `protocol Sendable` | Interface only |
| Repository Impls | `actor` | Protect shared mutable state |
| GameState | `@unchecked Sendable` + `NSLock` | Observable + manual lock |
| GameEngine | `@MainActor` | Coordinates UI-touching state |
| GameViewModel | `@MainActor` | Drives SwiftUI views |
| AudioManager | `actor` | Protect playback state |

## State Machine

`GamePhase` drives all game behavior. Valid transitions:

```
idle      → menu
menu      → playing
playing   → paused, gameOver, victory
paused    → playing, menu
gameOver  → menu, idle
victory   → menu, idle
any       → idle  (emergency reset)
```

Invalid transitions are silently ignored. `GameState.transition(to:)` enforces
this via `isValidTransition(from:to:)`.

## Testing Strategy

| Layer | Test type | Tools |
|-------|-----------|-------|
| Domain Entities | Unit | Swift Testing, no mocks |
| Use Cases | Unit | Swift Testing + MockRepository |
| GameState | Unit | Swift Testing, @MainActor |
| GameEngine | Unit | Swift Testing + Mocks |
| SpriteKit Scenes | Manual + snapshot | Xcode |
| End-to-end | Manual | iPhone Simulator |

Target: **>90% coverage on Domain + Core**. Presentation layer tested manually.

## Adding New Entities

1. Create `struct MyEntity: GameEntity` in `Domain/Entities/`
2. Keep it a value type (`struct`)
3. Write tests covering all mutations before implementation
4. Add factory method to `TestGameFactory`

## Adding New Persistence

1. Add method to `ScoreRepository` protocol (or create new protocol)
2. Add `actor MyRepository: MyProtocol` in `Infrastructure/Persistence/`
3. Wire in `App/GameApp.make()`
4. Add `MockMyRepository` in `TestHelpers/`

## SpriteKit Integration

`GameEngine` is the single source of truth for game logic. The SpriteKit `SKScene`
calls `engine.update(deltaTime:)` each frame and applies the resulting state to nodes.
Never put business logic in `SKScene` — only rendering calls.

```swift
// In SKScene
override func update(_ currentTime: TimeInterval) {
    engine.update(deltaTime: currentTime - lastTime)
    // Apply state to SKNode positions, health bars, etc.
}
```
