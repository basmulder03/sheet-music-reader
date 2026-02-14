# Sheet Music Rendering Layout TODOs

## Core Layout Modes

- [ ] Add a viewer layout selector with `Portrait` and `Landscape` modes.
- [ ] Persist the selected layout mode per device using settings.
- [ ] Add quick toggle button in viewer toolbar for fast switching.

## Portrait Mode Behavior

- [ ] Implement portrait rendering optimized for vertical reading.
- [ ] Add half-screen navigation in portrait mode (next/previous half page).
- [ ] Add option to show one half-screen chunk at a time in portrait mode.
- [ ] Add option to show two pages in portrait mode (stacked preview mode).
- [ ] Add visual indicator for current half-screen segment position.

## Landscape Mode Behavior

- [ ] Implement landscape rendering optimized for wider page display.
- [ ] Add optional two-page spread in landscape mode (left/right pages).
- [ ] Ensure page-turn/navigation works correctly in spread mode.

## Navigation + Input

- [ ] Map swipe gestures to half-screen navigation when portrait half-screen mode is active.
- [ ] Map keyboard/midi pedal navigation to half-screen steps when enabled.
- [ ] Add configurable step size (`half-screen`, `full-page`) in viewer settings.

## Rendering Quality + Performance

- [ ] Pre-render adjacent half-screen segments for smooth scrolling/turning.
- [ ] Cache layout computations separately for portrait and landscape modes.
- [ ] Add fallback behavior for low-memory devices (reduce pre-render window).

## UX + Accessibility

- [ ] Add onboarding tooltip explaining half-screen navigation.
- [ ] Add larger tap zones for previous/next half-screen controls.
- [ ] Keep annotation alignment correct across all layout modes.

## Testing

- [ ] Add BDD scenarios for portrait half-screen navigation.
- [ ] Add BDD scenarios for portrait two-page visibility mode.
- [ ] Add BDD scenarios for landscape two-page spread mode.
- [ ] Add regression tests for zoom + layout mode interaction.
