# Editing Interface - Quick Visual Reference

## Screen Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Edit: Simple C Major Scale                    [-] [100%] [+] │ ← App Bar
│ Test Composer                                      [💾 Save]  │
├─────────────────────────────────────────────────────────────┤
│ 👆 🎵 ⏸ 🗑️ | Duration: 𝅝 𝅗𝅥 ♩ ♪ 𝅘𝅥𝅯 | Accidental: ♭ ♮ ♯ [None] | ↶ ↷ | 🔴 Unsaved │ ← Toolbar
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ═══════════════════════════════════════════════════════    │
│  ───────────────────────────────────────────────────────    │ ← Staff
│  ───────────────────────────────────────────────────────    │
│  ───────────────────────────────────────────────────────    │
│  ───────────────────────────────────────────────────────    │
│  ───────────────────────────────────────────────────────    │
│                                                               │
│     𝄞  4/4  │ ♩ ♩ ♩ ♩ │ ♩ ♩ ♩ ♩ │ 𝄼 ♩ ♩ │ 𝅝 │              │ ← Notes
│              ▲                                                │
│              └─ Selected (blue highlight)                    │
│                                                               │
│                          [Scrollable Canvas]                 │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Toolbar Sections

### 1. Tools (Left)
```
👆 Select    - Click to select notes/rests
🎵 Add Note  - Click staff to add notes
⏸ Add Rest  - Click measure to add rests
🗑️ Delete    - Click to delete notes/rests
```

### 2. Duration Selector (Center-Left)
```
Duration: [𝅝] [𝅗𝅥] [♩] [♪] [𝅘𝅥𝅯]
          │    │    │   │    └─ 16th note
          │    │    │   └───── Eighth note
          │    │    └───────── Quarter note (default)
          │    └───────────── Half note
          └─────────────────── Whole note
```

### 3. Accidental Selector (Center)
```
Accidental: [♭] [♮] [♯] [None]
             │   │   │    └─ No accidental
             │   │   └────── Sharp (+1 semitone)
             │   └────────── Natural (cancel)
             └────────────── Flat (-1 semitone)
```

### 4. History (Center-Right)
```
[↶] Undo  - Reverse last action (up to 50)
[↷] Redo  - Restore undone action
```

### 5. Status (Right)
```
🔴 Unsaved changes  - Appears when edits made
                      (disappears after save)
```

## Interaction Patterns

### Selecting a Note
```
Before:                After:
   ♩                     ⭕
   │                     │ ♩ │
   │                     └───┘
(normal)              (blue highlight)
```

### Adding a Note
```
1. Click "Add Note" tool
2. Select duration (e.g., ♩)
3. Optional: Select accidental (e.g., ♯)
4. Click on staff:

   ───────────────     ───────────────
   ─────────👆────  →  ─────♯─♩───────  (new note added)
   ───────────────     ───────────────
```

### Deleting a Note
```
1. Click "Delete" tool
2. Click on note:

   ♩ ♩ 👆 ♩          ♩ ♩ ♩
   │ │  │  │    →    │ │ │   (middle note removed)
```

### Changing Duration
```
1. Select tool → Click note
2. Click duration in toolbar:

   Selected: ♩        Selected: 𝅗𝅥
   │                  │
   Click [𝅗𝅥]    →     Note changed!
```

### Adding Accidental
```
1. Select tool → Click note
2. Click accidental in toolbar:

   Selected: ♩        Selected: ♯♩
   │                  │
   Click [♯]     →    Sharp added!
```

## Music Symbol Reference

### Note Durations
```
𝅝  = Whole note (4 beats in 4/4)
𝅗𝅥  = Half note (2 beats)
♩  = Quarter note (1 beat)
♪  = Eighth note (0.5 beat)
𝅘𝅥𝅯 = 16th note (0.25 beat)
```

### Rest Symbols
```
𝄻 = Whole rest
𝄼 = Half rest
𝄽 = Quarter rest
𝄾 = Eighth rest
𝄿 = 16th rest
```

### Accidentals
```
♯ = Sharp (raises pitch 1 semitone)
♭ = Flat (lowers pitch 1 semitone)
♮ = Natural (cancels sharp/flat)
```

### Common Notation
```
𝄞 = Treble clef (G clef)
𝄢 = Bass clef (F clef)
4/4 = Time signature (4 beats per measure, quarter note gets 1 beat)
```

## Color Coding

```
Blue    = Selected element (can be edited)
Black   = Normal notation
Red dot = Unsaved changes indicator
Gray    = Disabled buttons
```

## Click Targets

### Where to Click
```
✅ Click on note heads (ovals)
✅ Click on rest symbols
✅ Click on staff lines to add notes
✅ Click between notes to insert

❌ Don't click on stems only
❌ Don't click on clefs/time signatures (not editable)
❌ Don't click on measure numbers
```

## Typical Workflow

```
1. Import Document
   └─> Library Tab → Import button

2. Open Viewer
   └─> Library Tab → Click document card

3. Enter Edit Mode
   └─> Viewer → Click Edit button (pencil)

4. Make Changes
   ├─> Select tool → Click notes
   ├─> Add Note → Click staff
   ├─> Delete → Click notes
   └─> Change duration/accidental

5. Save
   └─> Click Save button
   
6. Verify
   └─> Close editor → Reopen to check persistence
```

## Keyboard Shortcuts (Future)

```
(Not yet implemented, but planned:)

Ctrl+Z = Undo
Ctrl+Y = Redo
Ctrl+S = Save
Delete = Delete selected note
1-5    = Select duration (1=whole, 2=half, etc.)
Esc    = Deselect / Exit tool
```

## Tips for Best Results

1. **Start with Select tool** to explore the score
2. **Zoom in** for precise clicking (100-150% recommended)
3. **Use Undo liberally** - it's there to help!
4. **Save frequently** to avoid losing work
5. **Click precisely** on note heads for selection
6. **Try different durations** to see visual changes
7. **Test accidentals** on various notes
8. **Check persistence** by reopening after save

## Common Scenarios

### Correcting OCR Error (Wrong Note)
```
1. Select tool
2. Click wrong note
3. Delete tool → Click it (or just use Delete tool directly)
4. Add Note tool
5. Select correct duration/accidental
6. Click correct position on staff
7. Save
```

### Fixing Missing Note
```
1. Add Note tool
2. Select duration (match surrounding notes)
3. Add accidental if needed
4. Click where note should be
5. Save
```

### Removing Extra Rest
```
1. Delete tool
2. Click on rest symbol
3. Save
```

### Changing Note Pitch
```
Current limitation: Must delete and re-add
(Direct pitch editing in progress)

1. Note position (Delete + Re-add at different staff position)
2. Save
```

---

**Ready to test?** Follow the steps in `EDITING_TEST_GUIDE.md` and refer to this visual guide as needed!
