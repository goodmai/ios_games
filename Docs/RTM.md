# Requirements Traceability Matrix (RTM)

**Project:** MorseLight — iOS Morse Code Transmitter / Receiver  
**Branch:** `claude/inspiring-mendel-9pvNL`  
**Last updated:** 2026-06-01 (added Epics E1–E5: FTL, MEM, CV, CTL, HAP — see `Docs/PLAN.md`)

---

## Legend

| Column | Meaning |
|--------|---------|
| **Req ID** | Unique requirement identifier |
| **Feature** | High-level feature area |
| **Requirement** | Specific, testable behaviour |
| **Unit Tests** | `@Test` IDs in `MorseLightTests/` |
| **Manual Tests** | Device / simulator checks |
| **Integration Tests** | End-to-end cross-layer tests |
| **Status** | ✅ Implemented · 🔲 Pending |

---

## 1. Morse Encoding

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| ENC-01 | Encoding | `MorseConverter.morseString(for:)` returns ITU-R dots/dashes for A–Z | `MorseConverter / SOS produces correct Morse string` `/ Single dot for letter E` `/ Digit 1 produces correct Morse code` | – | – | ✅ |
| ENC-02 | Encoding | Lowercase input is normalised to uppercase before encoding | `MorseConverter / Lowercase input is normalised to uppercase` | – | – | ✅ |
| ENC-03 | Encoding | Words in input are separated by `/` in Morse string | `MorseConverter / Words separated by slash in Morse string` | – | – | ✅ |
| ENC-04 | Encoding | Empty input returns empty string | `MorseConverter / Empty input produces empty Morse string` | – | – | ✅ |
| ENC-05 | Encoding | Unknown characters are silently skipped | `MorseConverter / Unknown characters are skipped` | – | – | ✅ |
| ENC-06 | Encoding | `signals(for:)` produces `on`/`off` pairs following ITU timing (dot=1u, dash=3u, elem-gap=1u, letter-gap=3u, word-gap=7u) | `MorseConverter / Signals for E is one on-signal of unit duration` `/ Dash duration is 3x unit` `/ Inter-letter gap is 3x unit` `/ Inter-word gap is 7x unit` `/ On signals alternate with off signals within a letter` | Flashlight blinking at 10 wpm decodes SOS on another device | – | ✅ |
| ENC-07 | Encoding | `signals(for:)` returns empty for empty / whitespace input | `MorseConverter / Signals are empty for empty text` `/ Signals are empty for whitespace-only text` | – | – | ✅ |
| ENC-08 | Encoding | SOS signal count matches ITU structure (17 signals) | `MorseConverter / SOS produces correct signal count` | – | – | ✅ |

---

## 2. Morse Code Tables

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| TBL-01 | Code Table | English table contains all 26 letters | `MorseCode Table / All 26 letters are in the table` `MorseCode.englishTable / English table via language selector has all 26 letters` | – | – | ✅ |
| TBL-02 | Code Table | English table contains digits 0–9 | `MorseCode Table / All digits 0–9 are in the table` | – | – | ✅ |
| TBL-03 | Code Table | All codes contain only `.` and `-` | `MorseCode Table / Every code contains only dots and dashes` | – | – | ✅ |
| TBL-04 | Code Table | No two English characters share the same code | `MorseCode Table / No two letters share the same code` `MorseCode.englishTable / English letter codes are unique` | – | – | ✅ |
| TBL-05 | Code Table | Russian table has all 32 Cyrillic letters | `MorseCode.russianTable / Russian table has exactly 32 Cyrillic letters` | – | – | ✅ |
| TBL-06 | Code Table | Russian table has digits 0–9 | `MorseCode.russianTable / Russian table has digits 0–9` | – | – | ✅ |
| TBL-07 | Code Table | Specific Russian mappings: А=.- Й=.--- Ш=---- Ъ=--.-- Ю=..-- Я=.-.- | `MorseCode.russianTable / Russian A (А) = .-` `/ Russian short-I (Й) = .---` `/ Russian SH (Ш) = ----` `/ Russian hard sign (Ъ) = --.--` `/ Russian YU (Ю) = ..--` `/ Russian YA (Я) = .-.-` | – | – | ✅ |
| TBL-08 | Code Table | Russian letter codes are all dots and dashes | `MorseCode.russianTable / Russian letter codes contain only dots and dashes` | – | – | ✅ |
| TBL-09 | Code Table | No two Russian characters share the same code | `MorseCode.russianTable / Russian letter codes are unique` | – | – | ✅ |
| TBL-10 | Code Table | Spanish table has all 26 Latin letters | `MorseCode.spanishTable / Spanish table has all 26 Latin letters` | – | – | ✅ |
| TBL-11 | Code Table | Spanish table has 5 extensions: Á É Ñ Ó Ü | `MorseCode.spanishTable / Spanish table has 5 special characters` `/ Á = .--.-` `/ É = ..-..` `/ Ñ = --.--` `/ Ó = ---.` `/ Ü = ..--` | – | – | ✅ |
| TBL-12 | Code Table | Spanish letter codes are unique within Spanish alphabet | `MorseCode.spanishTable / Spanish letter codes are unique` | – | – | ✅ |
| TBL-13 | Code Table | Spanish table has digits 0–9 | `MorseCode.spanishTable / Spanish table has digits 0–9` | – | – | ✅ |

---

## 3. Multi-Language Support

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| LNG-01 | Multi-language | `MorseLanguage` enum has exactly 3 cases: english, spanish, russian | `MorseLanguage / MorseLanguage has exactly three cases` `/ MorseLanguage cases are english, spanish, russian` | – | – | ✅ |
| LNG-02 | Multi-language | `MorseConverter.language` defaults to `.english` | `MorseConverter language support / Default language is english` | – | – | ✅ |
| LNG-03 | Multi-language | Russian encoding: А encodes to `.-` | `MorseConverter language support / Russian А encodes to .-` | – | – | ✅ |
| LNG-04 | Multi-language | Russian encoding: АБВ → `.- -... .--` | `MorseConverter language support / Russian АБВ encodes correctly` | – | – | ✅ |
| LNG-05 | Multi-language | Spanish encoding: Ñ → `--.--` | `MorseConverter language support / Spanish Ñ encodes to --.--` | – | – | ✅ |
| LNG-06 | Multi-language | Spanish encoding: HOLA → `.... --- .-.. .-` | `MorseConverter language support / Spanish HOLA encodes correctly` | – | – | ✅ |
| LNG-07 | Multi-language | English encoding unaffected: SOS → `... --- ...` | `MorseConverter language support / English remains default — SOS unchanged` | – | – | ✅ |
| LNG-08 | Multi-language | Russian А signal pattern matches `.-` timing | `MorseConverter language support / Russian signals for А are same pattern as English A (.-)` | – | – | ✅ |
| LNG-09 | Multi-language | `MorseAudioDecoder.language` defaults to `.english` | `MorseAudioDecoder language support / Default language is english` | – | – | ✅ |
| LNG-10 | Multi-language | Decoder language can be set to `.russian` and `.spanish` | `MorseAudioDecoder language support / Language property can be set to russian` `/ Language property can be set to spanish` | – | – | ✅ |
| LNG-11 | Multi-language | ContentView shows segmented language picker (English / Español / Русский) | – | Open app → Language section shows 3 segments; selecting Español changes preview encoding | – | ✅ |
| LNG-12 | Multi-language | ContentView "Morse Alphabet Table" button opens correspondence sheet | – | Tap "Morse Alphabet Table" → sheet shows char + code for selected language | – | ✅ |

---

## 4. Audio Engine (M4A Export)

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| AUD-01 | Audio | `MorseAudioEngine.exportM4A` produces a valid M4A file at a UUID-named path | `MorseAudioDecoder / Round-trip SOS` `/ Round-trip HI` | Share audio in app → Files shows .m4a | Round-trip encode→decode returns same text | ✅ |
| AUD-02 | Audio | Exported files use UUID filenames to avoid parallel-test collisions | – | – | CI runs all tests concurrently without file conflicts | ✅ |
| AUD-03 | Audio | `generateSamples` produces 700 Hz sine at correct sample rate | – | Open M4A in Audacity → 700 Hz peak visible in spectrum | – | ✅ |
| AUD-04 | Audio | Silence-only signals produce a decodable but empty result | `MorseAudioDecoder / Decoder: pure silence returns empty or no-Morse string` | – | – | ✅ |
| AUD-05 | Audio | Non-existent file throws `MorseDecoderError.cannotReadFile` | `MorseAudioDecoder / Decoder: non-existent file throws cannotReadFile` | – | – | ✅ |
| AUD-06 | Audio | File too short throws `MorseDecoderError.tooShort` | `MorseAudioDecoder / Decoder: too-short audio throws tooShort` | – | – | ✅ |

---

## 5. Audio Decoding (Goertzel + K-means)

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| DEC-01 | Decoding | `MorseAudioDecoder` round-trips single letters E, T, A, S, O | `MorseAudioDecoder / Round-trip single letter E (dit)` `/ Round-trip single letter T (dah)` `/ Round-trip single letter A (.-)` `/ Round-trip single letter S (...)` `/ Round-trip single letter O (---)` | – | – | ✅ |
| DEC-02 | Decoding | Decoder round-trips SOS end-to-end | `MorseAudioDecoder / Round-trip SOS` | – | – | ✅ |
| DEC-03 | Decoding | Decoder round-trips HI end-to-end | `MorseAudioDecoder / Round-trip HI` | – | – | ✅ |
| DEC-04 | Decoding | Default `toneFrequency` = 700 Hz | `MorseAudioDecoder / Decoder: toneFrequency default is 700 Hz` | – | – | ✅ |
| DEC-05 | Decoding | Default `windowDuration` = 10 ms | `MorseAudioDecoder / Decoder: windowDuration default is 10ms` | – | – | ✅ |
| DEC-06 | Decoding | Default `energyThreshold` = 0.008 | `MorseAudioDecoder / Decoder: energyThreshold default is 0.008` | – | – | ✅ |
| DEC-07 | Decoding | Russian А round-trip via audio | `MorseAudioDecoder language support / Round-trip Russian А via audio` | – | – | ✅ |
| DEC-08 | Decoding | Spanish Ñ round-trip via audio | `MorseAudioDecoder language support / Round-trip Spanish Ñ via audio` | – | – | ✅ |
| DEC-09 | Decoding | Russian ЭТО round-trip via audio | `MorseAudioDecoder language support / Round-trip Russian ЭТО via audio` | – | – | ✅ |

---

## 6. AES-256-GCM Cipher

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| CIP-01 | Cipher | `MorseCipher.encrypt(_:seed:)` returns uppercase hex string | `MorseCipher / encrypt returns uppercase hex string` | – | – | ✅ |
| CIP-02 | Cipher | `MorseCipher.decrypt(_:seed:)` round-trips to original plaintext | `MorseCipher / decrypt round-trips plaintext` | – | – | ✅ |
| CIP-03 | Cipher | Same plaintext + seed → different ciphertext each call (random nonce) | `MorseCipher / same plaintext different ciphertexts with different nonces` | – | – | ✅ |
| CIP-04 | Cipher | Wrong seed → `decryptionFailed` error | `MorseCipher / wrong seed throws decryptionFailed` | – | – | ✅ |
| CIP-05 | Cipher | Invalid hex input → `invalidHexInput` error | `MorseCipher / invalid hex throws invalidHexInput` | – | – | ✅ |
| CIP-06 | Cipher | Ciphertext contains only hex chars (only dots and dashes exist in Morse for 0–9 A–F) | `MorseCipher / ciphertext only hex chars` | – | – | ✅ |
| CIP-07 | Cipher | Key derivation uses SHA-256 (32-byte key from seed) | `MorseCipher / symmetric key length is 32 bytes` | – | – | ✅ |
| CIP-08 | Cipher | Cipher works with empty seed | `MorseCipher / empty seed encrypts and decrypts` | – | – | ✅ |
| CIP-09 | Cipher | Cipher works with UTF-8 seed phrase | `MorseCipher / utf8 seed works` | – | – | ✅ |
| CIP-10 | Cipher | "SOS" encrypts to 62-char hex (12 nonce + 3 cipher + 16 tag = 31 bytes → 62 hex chars) | `MorseCipher / SOS encrypts to 62 hex chars` | – | – | ✅ |
| CIP-11 | Cipher | Encrypted Morse hex only contains chars with valid Morse codes | `MorseCipher / encrypted hex chars all have Morse codes` | – | – | ✅ |
| CIP-12 | Cipher | UI: seed field toggles lock icon and AES label | – | Enter seed → lock icon fills, AES badge appears | – | ✅ |
| CIP-13 | Cipher | UI: clear button removes seed | – | Tap ✕ → seed cleared, lock opens | – | ✅ |
| CIP-14 | Cipher | Cipher round-trip across encode→transmit→decode pipeline | – | Encode "HELLO" with seed, share M4A, import and decode with same seed | Cipher.encrypt → Converter.signals → Engine.exportM4A → Decoder.decode → Cipher.decrypt = "HELLO" | ✅ |

---

## 7. Duress PIN Security

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| PIN-01 | PIN Setup | `isSetup` is `false` before any setup call | `PINManager / isSetup is false before any setup` | – | – | ✅ |
| PIN-02 | PIN Setup | `failedAttempts` is 0 before setup | `PINManager / failedAttempts is 0 before any setup` | – | – | ✅ |
| PIN-03 | PIN Setup | Setup throws `pinsMatch` when PIN A == PIN B | `PINManager / setup throws pinsMatch when PIN A == PIN B` | – | – | ✅ |
| PIN-04 | PIN Setup | Setup throws `invalidLength` for PINs shorter than 6 digits | `PINManager / setup throws invalidLength for short PIN` | – | – | ✅ |
| PIN-05 | PIN Setup | Setup succeeds with valid, different 6-digit PINs | `PINManager / setup succeeds with valid different PINs` | Fresh install → 4-step setup flow completes | – | ✅ |
| PIN-06 | PIN Setup | `failedAttempts` resets to 0 after successful setup | `PINManager / failedAttempts resets to 0 after setup` | – | – | ✅ |
| PIN-07 | PIN Verify | PIN A returns `.unlocked` | `PINManager / verify with PIN A returns .unlocked` | Enter PIN A → main screen shown | – | ✅ |
| PIN-08 | PIN Verify | PIN A resets `failedAttempts` to 0 | `PINManager / verify with PIN A resets failed attempts` | Fail once, then succeed with A → counter gone | – | ✅ |
| PIN-09 | PIN Verify | PIN B returns `.wiped` and clears `isSetup` | `PINManager / verify with PIN B returns .wiped and clears isSetup` | Enter PIN B → "All data erased" shown | – | ✅ |
| PIN-10 | PIN Verify | Wrong PIN returns `.wrong(attemptsLeft: N)` with correct count | `PINManager / verify with wrong PIN returns correct attemptsLeft` `/ successive wrong PINs decrement attemptsLeft` | Fail 3 times → "7 attempts remaining" shown | – | ✅ |
| PIN-11 | PIN Wipe | 10th consecutive wrong PIN triggers wipe | `PINManager / 10th wrong PIN triggers wipe` | Fail 10 times → data erased, setup flow shown again | – | ✅ |
| PIN-12 | PIN Wipe | `wipeAll` clears Keychain, UserDefaults, temp files | `PINManager / wipeAll resets isSetup and failedAttempts` | After wipe: app restarts to setup, seed phrase gone | – | ✅ |
| PIN-13 | PIN Persist | `isSetup` reflects Keychain state across re-init | `PINManager / isSetup reflects Keychain state on re-init` | Kill app, reopen → lock screen shown | – | ✅ |
| PIN-14 | PIN Verify | Verify before setup returns `.wrong(attemptsLeft: maxAttempts)` | `PINManager / verify before setup returns .wrong with max attempts` | – | – | ✅ |
| PIN-15 | PIN UI | First launch shows 4-step PIN setup (enterA → confirmA → enterB → confirmB) | – | Fresh install → setup wizard with correct labels and step progression | – | ✅ |
| PIN-16 | PIN UI | Wrong PIN flashes red dots for 350 ms | – | Enter wrong PIN → red flash then clear | – | ✅ |
| PIN-17 | PIN UI | Wipe event shows "All data erased" for 1.5 s then transitions to setup | – | Enter PIN B → trash icon + message → setup | – | ✅ |
| PIN-18 | PIN UI | Attempt counter appears after first failure, turns red at ≤3 | – | Fail once → counter shown; fail 7 times → counter red | – | ✅ |

---

## 8. Flashlight Control

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| TOR-01 | Flashlight | Manual torch toggle turns on/off | – | Tap flashlight toggle → torch state matches | – | ✅ |
| TOR-02 | Flashlight | Brightness slider (0.01–1.0) adjusts torch level | – | Drag slider → visible brightness change | – | ✅ |
| TOR-03 | Flashlight | Morse transmission disables manual toggle during transmission | – | Start transmission → toggle greyed out | – | ✅ |
| TOR-04 | Flashlight | Manual torch is automatically turned off before Morse transmission | – | Toggle torch on, tap "Via Light" → torch stays off during transmission | – | ✅ |
| TOR-05 | Flashlight | "Torch unavailable" warning on devices without torch | – | Run on iPhone simulator → warning label visible | – | ✅ |

---

## 9. App Lifecycle & Navigation

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| APP-01 | Lifecycle | On first launch (no PINs): startup → setup phase | – | Fresh install → PinSetupView shown | – | ✅ |
| APP-02 | Lifecycle | On subsequent launches (PINs set): startup → locked phase | – | Kill + reopen → PinLockView shown | – | ✅ |
| APP-03 | Lifecycle | After successful setup: directly unlocked (no re-entry required) | – | Complete setup → ContentView immediately shown | – | ✅ |
| APP-04 | Lifecycle | After wipe event: transition to setup phase | – | Wipe → PinSetupView shown | – | ✅ |
| APP-05 | Navigation | ContentView sections: Flashlight, Language, Message, Cipher, Transmit, Decode Audio, Permissions | – | Scroll ContentView → all sections visible | – | ✅ |

---

## 10. Permissions

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| PRM-01 | Permissions | Camera permission status displayed in Permissions section | – | Permissions section shows correct status for Camera | – | ✅ |
| PRM-02 | Permissions | Microphone permission status displayed | – | Mic status shown | – | ✅ |
| PRM-03 | Permissions | Photo Library permission status displayed | – | Photo status shown | – | ✅ |
| PRM-04 | Permissions | "Request" button triggers system permission dialog for each type | – | Tap Request → iOS dialog appears | – | ✅ |

---

## 11. Algorithmic Fault Tolerance — Doppler / Off-Frequency Auto-Tune (Epic E1)

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| FTL-01 | Auto-tune | `FrequencyPeakDetector.dominantFrequency` returns the nominal 700 Hz tone within band | `FrequencyPeakDetector / Detects the nominal 700 Hz tone within the band` | – | – | ✅ |
| FTL-02 | Auto-tune | Detector finds Doppler-shifted / off-tune tones (620 Hz, 760 Hz) inside 600–800 Hz | `FrequencyPeakDetector / Detects a Doppler-shifted 760 Hz tone` `/ Detects a low-edge 620 Hz tone` | Walk toward/away from a 700 Hz transmitter → message still decodes | – | ✅ |
| FTL-03 | Auto-tune | Silence / empty input returns `nil` (no false tone below noise floor) | `FrequencyPeakDetector / Returns nil for pure silence` `/ Returns nil for empty input` | – | – | ✅ |
| FTL-04 | Auto-tune | Default search band is 600–800 Hz | `FrequencyPeakDetector / Default band is 600–800 Hz` | – | – | ✅ |
| FTL-05 | Auto-tune | `MorseAudioDecoder.autoTuneFrequency` retunes detection to the band peak (default off) | `MorseAudioDecoder / Decoder: autoTuneFrequency defaults to false` `/ Auto-tune enabled still round-trips a nominal 700 Hz file` | Import a third-party Morse clip with drifted tone → decodes with auto-tune on | `MorseLightUITests / testDecodeSelfTestWithAutoTuneRoundTripsSOS` | ✅ |
| FTL-07 | Auto-tune UI | Decode section exposes an "Auto-tune (600–800 Hz)" toggle wired to the decode pipeline | – | Toggle Auto-tune in Decode section → state flips | `MorseLightUITests / testAutoTuneToggleExistsAndToggles` | ✅ |
| FTL-06 | Auto-tune | Shared `Goertzel.power` used by both decoder and detector (no duplicated DSP) | Covered transitively by `MorseAudioDecoder` + `FrequencyPeakDetector` suites | – | – | ✅ |

---

## 12. Memory Optimization — Streaming Buffer Reads (Epic E2)

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| MEM-01 | Streaming | `MorseAudioDecoder` reads in 4096-frame chunks; `streamingChunkFrames` default is 4096 | `MorseAudioDecoder / Decoder: streamingChunkFrames defaults to 4096` | Decode a multi-minute file → peak memory stays bounded (Instruments Allocations) | – | ✅ |
| MEM-02 | Streaming | Chunked path is behavior-equivalent across chunk boundaries | `MorseAudioDecoder / Small chunk size still decodes SOS (chunk-boundary equivalence)` `/ Round-trip SOS` `/ Round-trip HI` | – | `MorseLightUITests / testDecodeSelfTestRoundTripsSOS` | ✅ |

---

## 13. Visual Decoding — Light-Flash Decode (Epic E3)

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| CV-01 | Light decode | `LightSignalDecoder` round-trips E from a brightness timeline | `LightSignalDecoder / Round-trips single letter E from a brightness timeline` | – | – | ✅ |
| CV-02 | Light decode | `LightSignalDecoder` round-trips SOS | `LightSignalDecoder / Round-trips SOS from a brightness timeline` | Point camera at another phone flashing SOS → "SOS" decoded | – | ✅ |
| CV-03 | Light decode | `LightSignalDecoder` round-trips HI | `LightSignalDecoder / Round-trips HI from a brightness timeline` | – | – | ✅ |
| CV-04 | Light decode | Sub-`minSegmentDuration` flicker is rejected; default threshold 0.5 | `LightSignalDecoder / Sub-threshold flicker shorter than minSegmentDuration is ignored` `/ Default brightness threshold is 0.5` `/ Empty timeline decodes to empty string` | – | – | ✅ |
| CV-05 | Light decode | Light + audio share `MorseSegmentDecoder` timing logic | `MorseSegmentDecoder / Decodes SOS from ideal segments` `/ Russian language decodes Cyrillic from ideal segments` | – | – | ✅ |
| CV-06 | Light decode | `VisionFlashDetector` bridges `VNDetectTrajectoriesRequest` ROI luminance → decoder | – | Capture a blinking torch on device → trajectory tracked, message decoded | – | 🔲 (device) |

---

## 14. Control Center Widget — iOS 18 (Epic E4)

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| CTL-01 | Control | `MorseTorchControl` registers an SOS button control in Control Center | – | iOS 18 → add "Morse SOS" control in Control Center editor → appears with flashlight icon | – | 🔲 (device) |
| CTL-02 | Control | `SendSOSIntent.perform()` flashes SOS via the torch | – | Tap the control → torch blinks `... --- ...` | – | 🔲 (Phase 4) |

---

## 15. Haptic Feedback — CHHapticEngine (Epic E5)

| Req ID | Feature | Requirement | Unit Tests | Manual Tests | Integration Tests | Status |
|--------|---------|-------------|-----------|-------------|-------------------|--------|
| HAP-01 | Haptics | `MorseHapticPattern.events` emits one event per on-signal, none for gaps | `MorseHapticPattern / Emits one haptic event per on-signal, none for gaps` `/ Single dot (E) yields exactly one event` `/ Empty text yields no events` | – | – | ✅ |
| HAP-02 | Haptics | Event times are monotonic and match cumulative signal timing | `MorseHapticPattern / Event times are strictly increasing` `/ First event starts at time zero` | – | – | ✅ |
| HAP-03 | Haptics | `totalDuration` equals the sum of all signal durations | `MorseHapticPattern / totalDuration equals the sum of all signal durations` | – | – | ✅ |
| HAP-04 | Haptics | Intensity / sharpness configurable; default intensity 1.0 | `MorseHapticPattern / Default intensity is 1.0 and applied to every event` `/ Custom intensity and sharpness propagate to events` | – | – | ✅ |
| HAP-05 | Haptics | `MorseHapticPlayer` plays the pattern on supported hardware | – | Transmit on iPhone with haptics → feel dot/dash buzzes in time | – | 🔲 (device) |

---

## Test File Index

| File | Suite(s) | Test count |
|------|---------|-----------|
| `MorseLightTests/MorseConverterTests.swift` | `MorseConverter`, `MorseCode Table` | 19 |
| `MorseLightTests/MorseCodeLanguageTests.swift` | `MorseLanguage`, `MorseCode.englishTable`, `MorseCode.russianTable`, `MorseCode.spanishTable`, `MorseConverter language support`, `MorseAudioDecoder language support` | 34 |
| `MorseLightTests/MorseAudioDecoderTests.swift` | `MorseAudioDecoder` | 17 |
| `MorseLightTests/MorseCipherTests.swift` | `MorseCipher` | 14 |
| `MorseLightTests/PINManagerTests.swift` | `PINManager` | 18 |
| `MorseLightTests/FrequencyPeakDetectorTests.swift` | `FrequencyPeakDetector` | 6 |
| `MorseLightTests/MorseSegmentDecoderTests.swift` | `MorseSegmentDecoder` | 5 |
| `MorseLightTests/MorseHapticPatternTests.swift` | `MorseHapticPattern` | 8 |
| `MorseLightTests/LightSignalDecoderTests.swift` | `LightSignalDecoder` | 6 |
| **Total** | | **127** |

---

## Manual Test Checklist (Device / Simulator)

### MT-01: First-Launch PIN Setup
1. Delete app / fresh install
2. Launch → PinSetupView appears with "Set Access PIN" header
3. Enter 6 digits → moves to "Confirm Access PIN"
4. Enter same digits → moves to "Set Duress PIN"
5. Attempt to enter same PIN as A → red flash, error message
6. Enter different 6 digits → moves to "Confirm Duress PIN"
7. Confirm → ContentView appears immediately (no re-entry)

### MT-02: PIN Lock Screen
1. Background + reopen app → PinLockView shown
2. Enter wrong PIN → red dot flash, "Incorrect PIN" message, attempt counter
3. Enter correct PIN A → ContentView unlocked
4. Background + reopen → enter PIN B → "All data erased" with trash icon → setup wizard

### MT-03: Language Picker & Morse Table
1. Open ContentView → Language section shows 3 segments
2. Select Русский → type "АБВ" → preview shows `.- -... .--`
3. Tap "Morse Alphabet Table" → sheet with 32 Cyrillic rows + digits
4. Select Español → type "Ñ" → preview shows `--.--`
5. Tap table → sheet shows Á É Ñ Ó Ü rows among Latin letters

### MT-04: Audio Round-Trip
1. Select English, type "SOS", tap "Via Sound" → audible Morse
2. Tap "Share Audio (M4A)" → system share sheet, save to Files
3. Tap "Import Audio File", select the saved file → decoded "SOS" appears
4. Tap "Use as Input" → "SOS" transferred to input field

### MT-05: Cipher Round-Trip
1. Enter seed "hello", type "SOS"
2. Morse preview shows "[AES-256-GCM encrypted — 3 chars]"
3. Share M4A → save to Files
4. Set same seed "hello" → Import → decoded "SOS" appears
5. Change seed to "wrong" → Import → "[Decryption failed — wrong seed?]"

### MT-06: 10-Attempt Lockout
1. On lock screen, enter wrong PIN 9 times → counter reaches "1 attempt remaining" in red
2. Enter wrong PIN 10th time → "All data erased" screen → setup wizard

---

## Integration Test Index

| ID | Description | Test File | Status |
|----|-------------|-----------|--------|
| INT-01 | English round-trip: text → M4A → decoded text | `MorseAudioDecoderTests / Round-trip SOS` | ✅ |
| INT-02 | Russian round-trip: А → M4A → А | `MorseCodeLanguageTests / Round-trip Russian А via audio` | ✅ |
| INT-03 | Russian word round-trip: ЭТО → M4A → ЭТО | `MorseCodeLanguageTests / Round-trip Russian ЭТО via audio` | ✅ |
| INT-04 | Spanish round-trip: Ñ → M4A → Ñ | `MorseCodeLanguageTests / Round-trip Spanish Ñ via audio` | ✅ |
| INT-05 | Cipher + decode: encrypt → signals → M4A → decode → decrypt | Manual MT-05 | ✅ |
| INT-06 | PIN persistence: setup → re-init → isSetup=true | `PINManagerTests / isSetup reflects Keychain state on re-init` | ✅ |
| INT-07 | UI: app shell reachable, message → live Morse preview | `MorseLightUITests / testTypingMessageUpdatesMorsePreview` | ✅ |
| INT-08 | UI: E1+E2 decode round-trip "SOS" through the live pipeline | `MorseLightUITests / testDecodeSelfTestRoundTripsSOS` | ✅ |
| INT-09 | UI: E1 auto-tune decode round-trip "SOS" | `MorseLightUITests / testDecodeSelfTestWithAutoTuneRoundTripsSOS` | ✅ |

> **CI policy:** unit tests run locally on Mac (`Cmd+U`); CI builds the app and runs
> the `MorseLightUITests` integration target on a simulator (see
> `.github/workflows/ios-build.yml`).
