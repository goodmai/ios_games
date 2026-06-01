# MorseLight — Resilience & Reach Plan

> Plan of record for the next development cycle. Five epics extending MorseLight's
> decoding robustness, memory profile, and accessibility surface.
> Every story is delivered **test-first** (RED → GREEN → REFACTOR) per `CLAUDE.md`.
>
> **Environment note:** `MorseLight` is an iOS app target (AVFoundation, Vision,
> CoreHaptics, WidgetKit). It builds and tests **only in Xcode on macOS** via
> `Cmd+U` (or `xcodebuild test`). The Linux/SPM `swift test` runner covers the
> separate `GameTemplate` library only. Pure-logic types below are designed so the
> algorithm is unit-testable without device hardware; framework wrappers are thin
> and verified by the listed manual/device checks.

---

## Epic Overview

| Epic | Theme | Layer | RTM Block | Risk |
|------|-------|-------|-----------|------|
| **E1** | Doppler-resilient decoding (band peak search before Goertzel) | Infrastructure/Domain | 11 (FTL-*) | Medium — DSP correctness |
| **E2** | Streaming buffer reads (4096-frame chunks) | Infrastructure | 12 (MEM-*) | Low — behavior-preserving refactor |
| **E3** | Visual decoding of light flashes (Vision) | Domain/Infrastructure | 13 (CV-*) | High — device CV, manual-verified |
| **E4** | Control Center widget (iOS 18) | Presentation | 14 (CTL-*) | Medium — new OS API, integration |
| **E5** | Haptic Morse output (CHHapticEngine) | Domain/Infrastructure | 15 (HAP-*) | Low — pure pattern + thin engine |

---

## E1 — Algorithmic Fault Tolerance (Doppler / off-frequency tolerance)

**Problem:** `MorseAudioDecoder` runs Goertzel at a fixed 700 Hz. Device motion
(Doppler) or third-party transmitters whose tone drifts (600–800 Hz) fall outside
the bin and fail to decode.

**Solution:** A `FrequencyPeakDetector` sweeps the 600–800 Hz band (Goertzel over
the loudest window) and returns the dominant tone. The decoder gains an
`autoTuneFrequency` flag that retunes to that peak before segmentation.

### Stories
- **E1.1** `FrequencyPeakDetector.dominantFrequency` finds a synthesized tone in band → `FTL-01,02`
- **E1.2** Returns `nil` for silence / sub-noise-floor input → `FTL-03`
- **E1.3** Default band is 600–800 Hz; configurable resolution → `FTL-04`
- **E1.4** `MorseAudioDecoder.autoTuneFrequency` retunes to the detected peak (off-frequency round-trip) → `FTL-05`
- **E1.5** Shared `Goertzel.power` extracted; decoder + detector reuse it (refactor) → `FTL-06`

**Files:** `Infrastructure/Goertzel.swift`, `Infrastructure/FrequencyPeakDetector.swift`,
`Infrastructure/MorseAudioDecoder.swift` · Tests: `FrequencyPeakDetectorTests.swift`

---

## E2 — Memory Optimization (streaming reads)

**Problem:** `decode()` allocates one `AVAudioPCMBuffer` sized to the whole file
(capped at 2 min) → large peak memory on long recordings.

**Solution:** Read the file in fixed 4096-frame chunks, mixing each chunk to mono
and appending, so peak buffer memory is bounded by the chunk, not the file.

### Stories
- **E2.1** `decode()` reads via `streamingChunkFrames` (default 4096); existing round-trips stay green → `MEM-01`
- **E2.2** Chunked path is behavior-equivalent to the single-buffer path (SOS/HI/silence) → `MEM-02`

**Files:** `Infrastructure/MorseAudioDecoder.swift` · Tests: existing `MorseAudioDecoderTests` + new chunk-config test

---

## E3 — Visual Decoding (Computer Vision)

**Problem:** Decoding Morse from a camera light source is a differentiator (only the
open-source MorseTorch prototype offers it).

**Solution:** Keep the algorithm pure and testable: `LightSignalDecoder` turns a
per-frame brightness timeline into text (threshold → on/off segments → shared
segment decoder). A thin `VisionFlashDetector` feeds it the luminance timeline from
`VNDetectTrajectoriesRequest` / ROI sampling on device.

### Stories
- **E3.1** `LightSignalDecoder` round-trips E / SOS / HI from a synthetic brightness timeline → `CV-01,02,03`
- **E3.2** Configurable `brightnessThreshold` and `minSegmentDuration` reject flicker noise → `CV-04`
- **E3.3** `LightSignalDecoder` reuses `MorseSegmentDecoder` (no duplicated timing logic) → `CV-05`
- **E3.4** `VisionFlashDetector` scaffold bridges Vision output → decoder (device-verified) → `CV-06`

**Files:** `Domain/LightSignalDecoder.swift`, `Infrastructure/VisionFlashDetector.swift`
· Tests: `LightSignalDecoderTests.swift`

---

## E4 — Control Center Widget (iOS 18)

**Problem:** iOS 18 introduces custom Control Center controls; a one-tap "SOS via
torch" control matches the new system pattern.

**Solution:** A `ControlWidget` (`MorseTorchControl`) with an `AppIntent`
(`SendSOSIntent`) wired to the flashlight transmitter in Phase 4 integration.
No pure-logic unit surface — verified by device/manual checks.

### Stories
- **E4.1** `MorseTorchControl` declares a Control Center button control → `CTL-01` (manual)
- **E4.2** `SendSOSIntent.perform()` triggers an SOS torch transmission → `CTL-02` (manual)

**Files:** `Presentation/MorseControlWidget.swift`

---

## E5 — Haptic Feedback (CHHapticEngine)

**Problem:** Deaf-blind / low-vision users can't perceive light or sound output.

**Solution:** `MorseHapticPattern` (pure) maps `[MorseSignal]` to a timed haptic
event list (on → continuous haptic, off → gap). A thin `MorseHapticPlayer` plays it
through `CHHapticEngine`.

### Stories
- **E5.1** `MorseHapticPattern.events` emits one event per `.on`, none for `.off` → `HAP-01`
- **E5.2** Event times are monotonic and match cumulative signal timing → `HAP-02`
- **E5.3** `totalDuration` equals the sum of all signal durations → `HAP-03`
- **E5.4** Intensity / sharpness are configurable; default intensity 1.0 → `HAP-04`
- **E5.5** `MorseHapticPlayer` scaffold plays the pattern on supported hardware (device-verified) → `HAP-05`

**Files:** `Domain/MorseHapticPattern.swift`, `Infrastructure/MorseHapticPlayer.swift`
· Tests: `MorseHapticPatternTests.swift`

---

## Sprint Mapping

| Sprint | Epics | TDD deliverables |
|--------|-------|------------------|
| **2** | E1, E2, E5 | `Goertzel`, `FrequencyPeakDetector`, streaming decode, `MorseHapticPattern` + suites |
| **3** | E3 | `MorseSegmentDecoder` extraction, `LightSignalDecoder` + suite, Vision scaffold |
| **4** | E4 | Control Center widget + Phase-4 transmitter wiring (Xcode integration) |

## Definition of Done (per story)
1. Failing test committed first (`test: …`).
2. Minimum implementation makes it pass (`feat: …`).
3. Refactor with suite green.
4. RTM row added/flipped to ✅ (or 🔲 + manual note for device-only work).
5. `Cmd+U` green on macOS before merge.
</content>
</invoke>
