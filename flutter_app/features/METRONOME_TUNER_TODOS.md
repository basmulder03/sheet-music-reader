# Built-in Metronome + Tuner TODOs (Cross-Device)

## Product Goals

- [ ] Add built-in **metronome** available on mobile, tablet, and desktop.
- [ ] Add built-in **tuner** available on mobile, tablet, and desktop.
- [ ] Ensure both tools support use with and without audible output.

## Shared Foundation

- [ ] Define shared practice-tools module (services + models) reusable across platforms.
- [ ] Add persisted settings for metronome/tuner preferences (tempo, tuning reference, mode, etc.).
- [ ] Add common UI entry point from document viewer and main navigation.

## Metronome Core

- [ ] Implement high-precision tempo engine (BPM, subdivision, time signature accents).
- [ ] Add support for common subdivisions (quarter, eighth, triplet, sixteenth).
- [ ] Add tap-tempo and tempo ramp/increment training modes.
- [ ] Add count-in and start/stop controls.

## Metronome Output Modes (With and Without Sound)

- [ ] Audible mode: click samples with accent levels and selectable click sounds.
- [ ] Silent mode: visual pulse indicator (flash/bar/beat ring) synced to tempo.
- [ ] Silent mode: haptic pulse option on supported devices.
- [ ] Hybrid mode: visual + sound or visual + haptics.

## Tuner Core

- [ ] Implement pitch-detection engine (FFT/autocorrelation) with stable note estimation.
- [ ] Add tuning reference control (A4 = 440 default, configurable range).
- [ ] Add cent deviation meter with clear in-tune threshold.
- [ ] Add instrument presets (guitar, violin, ukulele, chromatic, etc.).

## Tuner Output Modes (With and Without Sound)

- [ ] Mic-listening mode with real-time visual needle/meter.
- [ ] Silent feedback mode using only visual cues (no generated sound).
- [ ] Optional reference tone playback per selected note (for ear tuning).
- [ ] Haptic cue on in-tune lock for supported devices.

## Cross-Platform Device Integration

- [ ] Mobile/tablet: microphone permissions and lifecycle handling.
- [ ] Desktop: microphone device selection and fallback behavior.
- [ ] Add graceful fallback when microphone/audio device unavailable.

## Performance + Reliability

- [ ] Ensure metronome timing drift stays within acceptable limits across devices.
- [ ] Keep tuner frame processing efficient for low-end devices.
- [ ] Handle audio interruptions (calls/bluetooth route changes/app backgrounding).
- [ ] Add battery-aware mode for long practice sessions.

## UX + Accessibility

- [ ] Large, stage-friendly controls and high-contrast visual beat/tuning indicators.
- [ ] Keyboard shortcuts and MIDI/pedal mappings for start/stop and tempo adjustments.
- [ ] Colorblind-safe tuner and beat indicator options.

## Sync + Profiles (Optional)

- [ ] Save per-user practice presets (metronome and tuner settings).
- [ ] Optional sync of presets across devices via self-hosted backend.

## Testing

- [ ] Add unit tests for tempo timing, subdivision logic, and tap-tempo averaging.
- [ ] Add unit/integration tests for pitch detection stability and note mapping.
- [ ] Add BDD scenarios for silent metronome usage and visual-only tuner workflows.
- [ ] Add cross-platform regression tests for permissions and device availability.
