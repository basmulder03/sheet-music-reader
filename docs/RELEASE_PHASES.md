# Release Phases (Based on Open TODOs)

This plan consolidates all currently open TODO backlogs:

- `flutter_app/features/RENDERING_LAYOUT_TODOS.md`
- `flutter_app/features/ANNOTATION_TODOS.md`
- `flutter_app/features/METRONOME_TUNER_TODOS.md`
- `services/sync_backend/ADMIN_UI_TODOS.md` (optional track)

## Phase 0 - Foundation and Contracts

### Goal

Stabilize shared models/settings and reduce rework before major feature work.

### Scope

- Finalize cross-platform settings contract for:
  - viewer layout mode + navigation behavior
  - annotation/tool defaults
  - metronome/tuner defaults
- Finalize backend/client DTO strategy for future sync extensions.
- Establish baseline performance budgets for:
  - viewer rendering
  - annotation latency
  - metronome timing drift
  - tuner update interval

### Exit Criteria

- Shared DTO/settings schema documented and versioned.
- Basic integration tests for settings persistence pass on desktop + mobile.

## Phase 1 - Viewer Layout MVP (All Devices)

### Goal

Ship reliable portrait/landscape viewing with essential navigation behavior.

### Scope

- Portrait and landscape mode selector + persistent preference.
- Toolbar quick toggle for layout mode.
- Portrait half-screen navigation (next/previous half).
- Step-size options (`half-screen`, `full-page`).
- Input mapping for touch + keyboard + pedal in half-screen mode.

### Subsections

#### 1.1 Portrait Navigation

- One half-screen chunk view.
- Visual indicator for current half-screen position.
- Swipe behavior tuned for half-screen steps.

#### 1.2 Landscape Navigation

- Baseline landscape layout behavior.
- Correct page turn behavior when switching orientation.

#### 1.3 Quality + UX

- Adjacent segment pre-render.
- Larger previous/next hit zones.
- Onboarding hint for half-screen mode.

### Exit Criteria

- Layout mode works consistently on desktop + mobile.
- Regression tests for zoom + layout mode pass.

## Phase 2 - Annotation v1 (Cross-Device, PDF + Rendered)

### Goal

Ship first production-grade annotation layer on both PDF and rendered music.

### Scope

- Unified annotation model + normalized anchors.
- Cross-input support (finger/stylus/mouse).
- Freehand drawing on PDF and rendered sheet music.
- Undo/redo and autosave.

### Subsections

#### 2.1 PDF Annotation Kit

- Freehand strokes.
- Stamp palette with common notation marks.
- Stamp placement/move/resize/delete.

#### 2.2 Rendered Sheet Annotation + Small Edit Mode

- Drawing overlay on MusicXML renderer.
- Small in-place edit mode for quick notation edits.
- Alignment stability across zoom/reflow/layout changes.

#### 2.3 Sync and Offline

- Offline annotation queueing.
- Sync reconciliation and conflict handling.
- Migration path for existing annotation records.

### Exit Criteria

- Annotate same score on multiple devices and sync correctly.
- Alignment and persistence regression tests pass.

## Phase 3 - Viewer Advanced Modes

### Goal

Extend layout system for advanced reading workflows.

### Scope

- Portrait two-page visibility mode (stacked preview).
- Landscape two-page spread mode (left/right pages).
- Robust navigation in all combinations.
- Performance fallback for low-memory devices.

### Exit Criteria

- Two-page modes are stable and performant on target devices.
- BDD/integration scenarios for portrait/landscape advanced modes pass.

## Phase 4 - Practice Tools v1 (Metronome + Tuner)

### Goal

Ship built-in metronome and tuner usable with and without audible output.

### Scope

- Shared practice-tools module and UI entry points.
- Metronome core: BPM, subdivisions, accents, count-in, tap tempo.
- Tuner core: pitch detection, note mapping, cent deviation meter, A4 calibration.

### Subsections

#### 4.1 Metronome Output Modes

- Audible click mode.
- Silent visual pulse mode.
- Haptic mode (supported devices).
- Hybrid modes (audio+visual or visual+haptic).

#### 4.2 Tuner Output Modes

- Mic-listening visual meter mode.
- Silent visual-only feedback mode.
- Optional reference tone mode.
- Haptic in-tune cue.

#### 4.3 Device Integration

- Mic permission and lifecycle flows.
- Desktop input-device selection.
- Graceful fallback without microphone/audio device.

### Exit Criteria

- Metronome and tuner function on all target platforms.
- Silent and audible workflows both validated.

## Phase 5 - Self-Hosted Sync Hardening

### Goal

Make self-hosted sync reliable for broad real-world usage.

### Scope

- Improve artifact sync reliability for PDF/MusicXML + annotations.
- Add stronger conflict resolution + retry semantics.
- Expand integration and regression coverage for offline-to-online flows.
- Harden observability and operational docs.

### Exit Criteria

- Multi-device sync reliability targets met.
- Offline edits reconcile correctly after reconnect.

## Phase 6 - Optional Admin Management UI Track

### Goal

Enable a dedicated admin UI without blocking core user features.

### Scope

- Read-only admin APIs (`summary`, `documents`, `events`, `health`).
- Admin action APIs (reindex, cleanup, replay, vacuum).
- Scoped admin auth (`admin_read`, `admin_write`).
- Operational endpoints (metrics, backup/restore support).
- Stable admin DTOs/OpenAPI contract for external UI.

### Exit Criteria

- Admin dashboard can monitor and maintain server safely.
- Admin routes protected by scoped auth and audited.

## Suggested Release Packaging

### Release A

- Phase 0 + Phase 1

### Release B

- Phase 2

### Release C

- Phase 3 + Phase 4

### Release D

- Phase 5

### Optional Release E

- Phase 6
