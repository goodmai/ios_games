# Sprint Log

## Sprint 1 — Foundation
**Goal:** Create the full template structure with TDD baseline.
**Status:** Complete

### Delivered
- Clean Architecture layer structure (Domain, Core, Infrastructure, Presentation)
- Player entity with full TDD coverage (health, lives, score, movement)
- GameState phase machine with valid transition guards
- GameEngine orchestrator connected to use cases
- StartGame + UpdateScore use cases with mocks
- Swift Testing suite: PlayerTests, GameStateTests, GameEngineTests, UseCaseTests
- CLAUDE.md workflow guide
- Scripts: setup, test, watch, lint

### Retrospective
- Template is intentionally game-agnostic; clone and replace entities for each game
- GameLoop uses `Timer` for SPM compatibility; swap for `CADisplayLink` in Xcode

---

## Sprint 2 — Resilience & Accessibility
**Goal:** Make decoding robust to Doppler / off-tune transmitters (E1), bound
decode memory on long files (E2), and add a haptic output channel (E5).
**Status:** Logic complete (device stories pending Xcode/hardware)

### Stories

| # | Story | RTM | Status |
|---|-------|-----|--------|
| 2.1 | Band peak detector (600–800 Hz) | FTL-01..04 | [x] |
| 2.2 | Decoder `autoTuneFrequency` + shared `Goertzel` | FTL-05,06 | [x] |
| 2.3 | Streaming 4096-frame reads | MEM-01,02 | [x] |
| 2.4 | `MorseHapticPattern` (signals → events) | HAP-01..04 | [x] |
| 2.5 | `MorseHapticPlayer` (CHHapticEngine) | HAP-05 | [ ] device |

### Notes
- `MorseLight` compiles/tests only in Xcode (AVFoundation/CoreHaptics). Pure-logic
  types (`Goertzel`, `FrequencyPeakDetector`, `MorseHapticPattern`) are unit-tested;
  framework wrappers are thin and device-verified.
- `MorseAudioEngine` emits a fixed 700 Hz tone, so the off-frequency round-trip is
  covered by synthetic-sine detector tests rather than an exported file.

### Retrospective
- Extracting `Goertzel` removed duplicated DSP and unblocked the band sweep cleanly.
- Streaming read is a behavior-preserving refactor — existing round-trips guard it.

---

## Sprint 3 — Visual Decoding
**Goal:** Decode Morse from a camera light source (E3).
**Status:** Logic complete (Vision bridge pending device)

### Stories

| # | Story | RTM | Status |
|---|-------|-----|--------|
| 3.1 | Extract `MorseSegmentDecoder` (shared timing) | CV-05 | [x] |
| 3.2 | `LightSignalDecoder` (brightness → text) | CV-01..04 | [x] |
| 3.3 | `VisionFlashDetector` (VNDetectTrajectoriesRequest bridge) | CV-06 | [ ] device |

### Retrospective
- Sharing `MorseSegmentDecoder` between audio and light paths means timing fixes
  land in one place.

---

## Sprint 4 — Control Center (iOS 18)
**Goal:** One-tap SOS torch control (E4).
**Status:** Scaffold in place; wiring is Phase 4 (Xcode integration).

### Stories

| # | Story | RTM | Status |
|---|-------|-----|--------|
| 4.1 | `MorseTorchControl` ControlWidget | CTL-01 | [ ] |
| 4.2 | `SendSOSIntent` → torch transmission | CTL-02 | [ ] |
