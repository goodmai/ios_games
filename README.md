# iOS Game Template — Swift TDD

A production-ready starter template for building iPhone games with Swift,
following strict TDD and Clean Architecture principles.

## Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9+ / Swift 6 |
| Package manager | Swift Package Manager |
| Testing | Swift Testing (`@Test`, `@Suite`) |
| Game rendering | SpriteKit |
| UI / HUD | SwiftUI + Observation |
| Concurrency | async/await, actors |
| Persistence | SwiftData / in-memory |
| Linting | SwiftLint |
| CI | GitHub Actions (macOS runner) |

## Requirements

| Tool | Minimum version |
|------|----------------|
| Xcode | 15.0+ |
| Swift | 5.9+ |
| iOS deployment target | 17.0 |
| macOS (for CLI tests) | 14.0 |

## Quick Start

### Clone and setup
```bash
git clone https://github.com/goodmai/ios_games.git
cd ios_games
bash Scripts/setup.sh
```

### Run all tests (terminal, no Xcode needed)
```bash
swift test
```

### Run tests with verbose output
```bash
bash Scripts/test.sh
```

### Watch mode — tests re-run on every file save
```bash
bash Scripts/test-watch.sh
# Requires: brew install fswatch  (macOS)
#           apt install inotify-tools  (Linux)
```

### Open in Xcode (macOS)
```bash
open Package.swift
# Xcode opens the SPM package as a project
# Cmd+U to run all tests
# Cmd+R to run on iPhone Simulator
```

### Run linter
```bash
bash Scripts/lint.sh
# Requires: brew install swiftlint
```

## Project Structure

```
ios_games/
├── Sources/
│   └── GameTemplate/
│       ├── App/                    # Composition root — wires all deps
│       ├── Core/
│       │   ├── GameState.swift     # Phase state machine
│       │   ├── GameEngine.swift    # Orchestrates use cases
│       │   └── GameLoop.swift      # Fixed-timestep update loop
│       ├── Domain/
│       │   ├── Entities/           # Player, Enemy, … (pure value types)
│       │   ├── UseCases/           # StartGame, UpdateScore, …
│       │   └── Repositories/       # Protocol interfaces for data
│       ├── Infrastructure/
│       │   ├── Persistence/        # InMemory + SwiftData repositories
│       │   └── Audio/              # AudioManager (AVFoundation wrapper)
│       └── Presentation/
│           ├── Game/               # GameViewModel + SpriteKit scene hook
│           └── Menu/               # MenuViewModel
├── Tests/
│   └── GameTemplateTests/
│       ├── Core/                   # GameState, GameEngine tests
│       ├── Domain/
│       │   ├── Entities/           # Player, … tests
│       │   └── UseCases/           # StartGame, UpdateScore tests
│       └── TestHelpers/            # Mocks, factories
├── Docs/
│   ├── Architecture.md
│   ├── TDD-Guide.md
│   └── Backlog.md
├── Scripts/
│   ├── setup.sh
│   ├── test.sh
│   ├── test-watch.sh
│   └── lint.sh
├── CLAUDE.md                       # AI workflow guide
├── Package.swift
├── .swiftlint.yml
└── .claude/settings.json
```

## TDD Workflow

Every feature is written **test first**:

```
1. Write failing test (RED)
   swift test  →  fails ✓

2. Write minimum code (GREEN)
   swift test  →  passes ✓

3. Refactor (CLEAN)
   swift test  →  still passes ✓

4. Commit
   git commit -m "test: player loses life at zero health"
   git commit -m "feat: player lose-life mechanic"
```

See [CLAUDE.md](CLAUDE.md) for the full workflow Claude follows.

## Architecture

```
            ┌─────────────────────────┐
            │      Presentation        │  SwiftUI + SpriteKit
            │  GameView / MenuView     │  @Observable ViewModels
            └────────────┬────────────┘
                         │ depends on
            ┌────────────▼────────────┐
            │          Core           │  @MainActor
            │  GameEngine / GameState │  Orchestration + State Machine
            └────────────┬────────────┘
                         │ depends on
            ┌────────────▼────────────┐
            │          Domain         │  Pure Swift, no imports
            │  Entities / UseCases    │  Sendable value types
            │  Repository Protocols   │  Protocol-driven
            └────────────┬────────────┘
                         │ implements
            ┌────────────▼────────────┐
            │      Infrastructure     │  actor
            │  Persistence / Audio    │  SwiftData / AVFoundation
            └─────────────────────────┘
```

**Dependency rule:** arrows point inward only. Domain has zero imports from outer layers.

## Game State Machine

```
    idle ──► menu ──► playing ◄──► paused
                         │
                    ┌────┴────┐
                 gameOver   victory
                    └────┬────┘
                        menu
```

## Adding a New Game

1. Duplicate and rename `GameTemplate` sources
2. Define your entities in `Domain/Entities/`
3. Define use cases in `Domain/UseCases/`
4. Add SpriteKit scene in `Presentation/Game/`
5. Wire in `App/GameApp.swift`
6. Write tests first — always

## Working with Claude

This repo includes `CLAUDE.md` — a detailed guide for Claude Code sessions.
Claude will follow TDD strictly, write tests before code, and follow the
SDLC phases defined there.

```bash
# Start Claude Code session
claude

# Claude will:
# 1. Run swift test (baseline check)
# 2. Read Docs/Backlog.md for current sprint
# 3. Guide Red → Green → Refactor cycles
```

## Commit Conventions

```
test: <what the test covers>
feat: <feature added>
fix: <bug fixed>
refactor: <cleanup>
docs: <doc change>
chore: <config / scripts>
```

Always commit the test separately from the implementation.

## License

MIT — see [LICENSE](LICENSE)
