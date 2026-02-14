# Cross-Device Annotation TODOs (PDF + Rendered Music)

## Scope

- [ ] Ensure annotation features work on **all devices** (mobile, tablet, desktop).
- [ ] Support both document types:
  - [ ] PDF source documents
  - [ ] Rendered sheet music (MusicXML renderer)

## Common Annotation Foundation

- [ ] Define unified annotation data model shared by PDF and rendered views.
- [ ] Store annotation anchors robustly (page + normalized coordinates + zoom-independent transforms).
- [ ] Add input abstraction for finger, stylus, and mouse.
- [ ] Add annotation layer renderer reusable across PDF and MusicXML views.
- [ ] Add undo/redo stack for annotation operations.

## PDF Annotation Features

- [ ] Implement freehand drawing on PDF pages (finger/stylus).
- [ ] Add stylus pressure/width handling where platform supports it.
- [ ] Add stamp palette for common notation marks (e.g., fermata, accent, breath, fingerings).
- [ ] Support stamp placement, move, resize, rotate, and delete.
- [ ] Add quick recent/favorite stamps strip.
- [ ] Persist PDF annotation overlays and sync across devices.

## Rendered Music (MusicXML) Annotation Features

- [ ] Implement freehand drawing overlay on rendered notation.
- [ ] Add "small edit mode" for in-place quick edits on rendered sheet music.
- [ ] In edit mode, allow replacing stamp workflow with lightweight direct edit controls.
- [ ] Keep edits/overlays aligned after zoom, reflow, and layout mode changes.
- [ ] Persist rendered-sheet annotation/edit data and sync across devices.

## Tools + UX

- [ ] Add annotation toolbar with pen, highlighter, eraser, lasso/select, stamp, and edit mode.
- [ ] Add palm-rejection-friendly drawing behavior on touch devices.
- [ ] Add per-tool settings (color, width, opacity, smoothing).
- [ ] Add lock/unlock annotation layer toggle to prevent accidental edits during performance.

## Cross-Platform + Sync

- [ ] Ensure annotation import/export format is platform-neutral.
- [ ] Add conflict handling for concurrent annotation edits from multiple devices.
- [ ] Add offline annotation queueing and later sync reconciliation.
- [ ] Add migration strategy for existing annotation storage.

## Performance + Reliability

- [ ] Batch and throttle annotation point streams for smooth rendering.
- [ ] Add chunked persistence for long drawing strokes.
- [ ] Add stress tests for dense annotation pages.
- [ ] Add crash-safe autosave while annotating.

## Testing

- [ ] Add BDD scenarios for PDF freehand drawing and stamp placement.
- [ ] Add BDD scenarios for rendered-sheet small edit mode.
- [ ] Add integration tests for cross-device sync of annotations.
- [ ] Add regression tests for annotation alignment after zoom/rotation/layout changes.
