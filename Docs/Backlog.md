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

## Sprint 2 — Resilience & Accessibility (Epics E1, E2, E5)

> Full epic breakdown in `Docs/PLAN.md`. RTM blocks 11, 12, 15.

- [x] **[E1.1]** `FrequencyPeakDetector.dominantFrequency` finds a tone in 600–800 Hz (`FTL-01,02`)
  - Tests: `FrequencyPeakDetectorTests.swift`
- [x] **[E1.2]** Detector returns `nil` for silence / sub-noise input (`FTL-03`)
- [x] **[E1.3]** Default band 600–800 Hz, configurable resolution (`FTL-04`)
- [x] **[E1.4]** `MorseAudioDecoder.autoTuneFrequency` retunes to the peak (`FTL-05`)
- [x] **[E1.5]** Extract shared `Goertzel.power`; decoder + detector reuse it (`FTL-06`)
- [x] **[E2.1]** Decoder streams in 4096-frame chunks (`MEM-01`)
- [x] **[E2.2]** Chunked path is behavior-equivalent (`MEM-02`)
- [x] **[E5.1]** `MorseHapticPattern.events` — one event per on-signal (`HAP-01`)
- [x] **[E5.2]** Monotonic event times matching signal timing (`HAP-02`)
- [x] **[E5.3]** `totalDuration` sums signal durations (`HAP-03`)
- [x] **[E5.4]** Configurable intensity / sharpness, default 1.0 (`HAP-04`)
- [x] **[E5.6]** "Via Haptics" button wired in transmit UI (`HAP-06`)
- [ ] **[E5.5]** `MorseHapticPlayer` plays on device (`HAP-05` — device)

---

## Sprint 3 — Visual Decoding (Epic E3)

> RTM block 13.

- [x] **[E3.1]** `LightSignalDecoder` round-trips E / SOS / HI from brightness (`CV-01,02,03`)
- [x] **[E3.2]** Configurable threshold + flicker rejection (`CV-04`)
- [x] **[E3.3]** Reuse `MorseSegmentDecoder` (extract shared segment→text) (`CV-05`)
- [x] **[E3.5]** `CameraLightCapture` + `LightDecodeView` camera flow wired (`CV-07`)
- [ ] **[E3.4]** `VisionFlashDetector` device bridge (`CV-06` — device)

---

## Sprint 4 — Control Center (Epic E4)

> RTM block 14. `MorseLightWidget` app-extension target added; device-verified on iOS 18.

- [x] **[E4.3]** `MorseLightWidget` extension target + `WidgetBundle` + embed in app
- [x] **[E4.4]** `SendSOSIntent.perform()` flashes SOS via torch (logic wired)
- [ ] **[E4.1]** Control appears in Control Center editor (`CTL-01` — device)
- [ ] **[E4.2]** Tapping the control blinks the torch (`CTL-02` — device)

---

## Backlog (Future Sprints)

- [ ] Live camera preview overlay with decoded text (E3 UI)
- [ ] Settings: per-message haptic intensity preset
- [ ] Game Center / leaderboard removed — not applicable to MorseLight
- [ ] iCloud sync of saved transmissions (CloudKit)
- [ ] Accessibility: VoiceOver labels across all sections

---

## Done

- Sprint 1 — Foundation (see above)
- Sprint 2 — Epics E1, E2, E5 pure-logic stories (device stories pending Xcode)
- Sprint 3 — Epic E3 pure-logic stories (Vision bridge pending device)
