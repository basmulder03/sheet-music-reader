# Manual Editing Interface - Testing Guide

## Prerequisites

Before testing, ensure:
1. **Developer Mode is enabled** on Windows:
   - Press `Windows + I` to open Settings
   - Go to: Update & Security > For developers
   - Turn ON "Developer Mode"
   - OR run: `start ms-settings:developers` in PowerShell

## Starting the Application

1. Open PowerShell or Command Prompt
2. Navigate to the project:
   ```bash
   cd D:\github\basmulder03\sheet-music-reader\flutter_app
   ```

3. Run the app:
   ```bash
   C:\tools\flutter\bin\flutter run -d windows
   ```

4. Wait for the app to compile and launch (first run may take 2-5 minutes)

## Testing Workflow

### Phase 1: Import a Test Document

**Option A: Use Provided Test File**
1. Click the **"Import"** tab in the app
2. Click **"Import PDF/Images"** button
3. Navigate to: `D:\github\basmulder03\sheet-music-reader\test_files\`
4. Select `simple_scale.xml`
5. Wait for processing (should be instant since it's already MusicXML)

**Option B: Import Your Own PDF** (requires Audiveris setup)
1. Place a PDF in a convenient location
2. Import via the Import tab
3. Wait for OMR processing

### Phase 2: View the Document

1. Click the **"Library"** tab
2. You should see your imported document listed
3. Click on the document card to open it
4. **Document Viewer opens** showing:
   - Sheet music rendered on canvas
   - Zoom controls in top-right (+/-)
   - Edit button in top-right
   - Playback controls at bottom

### Phase 3: Enter Editing Mode

1. In the Document Viewer, click the **"Edit"** button (pencil icon) in the top-right
2. **Document Editor opens** with:
   - Editing toolbar at the top
   - Interactive music canvas below
   - Save button in top-right (initially disabled)

## Testing the Editing Tools

### Test 1: Select Tool (Default)

**Purpose:** Click notes to select them

1. Ensure **Select tool** is active (touch icon, should be highlighted)
2. Click on any note in the score
3. **Expected:** Note becomes highlighted in blue
4. Click on a different note
5. **Expected:** Previous selection clears, new note highlighted
6. Click on empty space
7. **Expected:** Selection clears

### Test 2: Add Note Tool

**Purpose:** Add new notes at specific pitches

1. Click the **"Add Note"** tool (music note icon)
2. Select a duration from toolbar (e.g., Quarter note ♩)
3. Optionally select an accidental (Sharp ♯, Flat ♭, or Natural ♮)
4. Click on the staff at the desired pitch
   - Higher on staff = higher pitch
   - Click between existing notes
5. **Expected:** New note appears where you clicked
6. Try different durations and accidentals
7. **Expected:** Notes appear with correct symbols

### Test 3: Add Rest Tool

**Purpose:** Add rests to measures

1. Click the **"Add Rest"** tool (pause icon)
2. Select a duration (e.g., Quarter note)
3. Click in a measure
4. **Expected:** Rest symbol appears (𝄽 for quarter rest)
5. Try different rest durations
6. **Expected:** Different rest symbols appear

### Test 4: Delete Tool

**Purpose:** Remove notes/rests

1. Click the **"Delete"** tool (trash icon)
2. Click on any note or rest
3. **Expected:** Note/rest disappears immediately
4. Try deleting several notes
5. **Expected:** Each click removes the clicked element

### Test 5: Duration Changes

**Purpose:** Change note durations

1. Switch to **Select tool**
2. Click a note to select it
3. In the toolbar, click different durations:
   - **Whole note (𝅝)** - open oval
   - **Half note (𝅗𝅥)** - open oval with stem
   - **Quarter note (♩)** - filled oval with stem
   - **Eighth note (♪)** - filled oval with stem and flag
4. **Expected:** Selected note changes duration on each click

### Test 6: Accidental Changes

**Purpose:** Add/change sharps and flats

1. Switch to **Select tool**
2. Click a note to select it
3. In the toolbar, click accidentals:
   - **Flat (♭)** - adds flat symbol
   - **Natural (♮)** - removes accidental
   - **Sharp (♯)** - adds sharp symbol
   - **None button** - removes accidental completely
4. **Expected:** Note shows appropriate accidental symbol to the left

### Test 7: Undo/Redo

**Purpose:** Test history management

1. Make several changes (add notes, delete notes, etc.)
2. Click **Undo** button (↶ icon)
3. **Expected:** Last action is reversed
4. Click Undo multiple times
5. **Expected:** Actions reversed in order
6. Click **Redo** button (↷ icon)
7. **Expected:** Undone actions are restored
8. Note: History limit is 50 actions

### Test 8: Zoom Controls

**Purpose:** Test canvas zoom

1. Click the **"-"** button in top-right
2. **Expected:** Music gets smaller (50% minimum)
3. Click the **"+"** button
4. **Expected:** Music gets larger (200% maximum)
5. Percentage shown between buttons updates

### Test 9: Save Changes

**Purpose:** Persist edits to file

1. Make any edit (add, delete, or modify a note)
2. **Expected:** 
   - Red dot appears in top-right
   - "Unsaved changes" text appears
   - Save button becomes enabled
3. Click **"Save"** button
4. **Expected:**
   - Green snackbar: "Score saved successfully"
   - Red dot disappears
   - Save button becomes disabled
5. Close the editor (back button)
6. Reopen the document from Library
7. Click Edit again
8. **Expected:** Your changes are still there

### Test 10: Multiple Tools Workflow

**Purpose:** Complete editing session

1. **View initial score** in editing mode
2. **Delete** a wrong note using Delete tool
3. **Add** a correct note using Add Note tool
4. **Select** the new note
5. **Change its duration** to eighth note
6. **Add a sharp** to it
7. **Undo** the sharp
8. **Add a rest** in measure 3
9. **Redo** to bring back the sharp
10. **Save** the changes
11. **Verify** all edits persisted

## Expected Behavior Summary

### Visual Feedback
- ✅ Selected notes highlight in blue
- ✅ Hover shows cursor changes in edit mode
- ✅ Unsaved changes indicator (red dot)
- ✅ Save button enables/disables appropriately
- ✅ Loading spinners during save

### Tool States
- ✅ Active tool highlighted in toolbar
- ✅ Duration buttons show current selection
- ✅ Accidental buttons show current selection
- ✅ Undo/Redo buttons enable/disable based on history

### Music Notation
- ✅ Notes render correctly (filled/open ovals, stems, flags)
- ✅ Rests render with proper symbols
- ✅ Accidentals appear left of notes
- ✅ Ledger lines for notes outside staff
- ✅ Clef, time signature, key signature preserved

## Troubleshooting

### Issue: "Developer Mode required" error
**Solution:** Enable Developer Mode in Windows Settings (see Prerequisites)

### Issue: App won't compile
**Solution:** 
```bash
cd flutter_app
C:\tools\flutter\bin\flutter clean
C:\tools\flutter\bin\flutter pub get
C:\tools\flutter\bin\flutter run -d windows
```

### Issue: Can't see test file
**Solution:** The test file is at `D:\github\basmulder03\sheet-music-reader\test_files\simple_scale.xml`

### Issue: Notes not appearing when clicked
**Solution:** 
- Ensure "Add Note" tool is selected (highlighted)
- Click directly on the staff lines area
- Try clicking between existing notes

### Issue: Selection not working
**Solution:**
- Switch to Select tool (touch icon)
- Click directly on note heads (oval shapes)
- Not all elements may be clickable yet (WIP)

### Issue: Save fails
**Solution:**
- Check file permissions on MusicXML file
- Ensure file path is valid
- Check console for error messages

## Known Limitations

1. **No drag-and-drop** - Must delete and re-add to move notes
2. **No chord support** - Single note line editing only
3. **No barline editing** - Measure structure is fixed
4. **No time/key signature editing** - These are preserved from import
5. **Click precision** - May need to click precisely on note heads

## Success Criteria

After testing, you should have:
- ✅ Successfully imported a document
- ✅ Opened it in editing mode
- ✅ Selected multiple notes
- ✅ Added at least one new note
- ✅ Added at least one rest
- ✅ Deleted at least one element
- ✅ Changed note duration and accidental
- ✅ Used undo and redo
- ✅ Saved changes successfully
- ✅ Verified changes persisted after reopen

## Next Steps After Testing

Once testing is complete, report:
1. What worked well
2. Any bugs or unexpected behavior
3. UI/UX improvements needed
4. Additional features desired

Then we can proceed to implement the **Desktop Local Server** (final Phase 2 feature).
