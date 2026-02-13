import 'package:flutter/foundation.dart';
import '../models/musicxml_model.dart';

/// Enum for different editing tools
enum EditingTool {
  select,
  addNote,
  addRest,
  delete,
  changeAccidental,
  changeDuration,
}

/// Enum for note durations
enum NoteDuration {
  whole('whole', 1.0),
  half('half', 0.5),
  quarter('quarter', 0.25),
  eighth('eighth', 0.125),
  sixteenth('16th', 0.0625);

  final String xmlType;
  final double relativeValue;

  const NoteDuration(this.xmlType, this.relativeValue);
}

/// Represents a selected note or rest in the editor
class SelectedNote {
  final int partIndex;
  final int measureIndex;
  final int noteIndex;
  final Note note;

  SelectedNote({
    required this.partIndex,
    required this.measureIndex,
    required this.noteIndex,
    required this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedNote &&
          runtimeType == other.runtimeType &&
          partIndex == other.partIndex &&
          measureIndex == other.measureIndex &&
          noteIndex == other.noteIndex;

  @override
  int get hashCode =>
      partIndex.hashCode ^ measureIndex.hashCode ^ noteIndex.hashCode;
}

/// Service for editing MusicXML scores
class NoteEditingService extends ChangeNotifier {
  MusicXmlScore? _score;
  EditingTool _currentTool = EditingTool.select;
  SelectedNote? _selectedNote;
  NoteDuration _currentDuration = NoteDuration.quarter;
  int? _currentAccidental; // -1 = flat, 0 = natural, 1 = sharp
  bool _isModified = false;

  // History for undo/redo
  final List<MusicXmlScore> _history = [];
  int _historyIndex = -1;
  static const int _maxHistorySize = 50;

  // Getters
  MusicXmlScore? get score => _score;
  EditingTool get currentTool => _currentTool;
  SelectedNote? get selectedNote => _selectedNote;
  NoteDuration get currentDuration => _currentDuration;
  int? get currentAccidental => _currentAccidental;
  bool get isModified => _isModified;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  /// Load a score for editing
  void loadScore(MusicXmlScore score) {
    _score = _deepCopyScore(score);
    _selectedNote = null;
    _currentTool = EditingTool.select;
    _isModified = false;
    _history.clear();
    _history.add(_deepCopyScore(score));
    _historyIndex = 0;
    notifyListeners();
  }

  /// Change the current editing tool
  void setTool(EditingTool tool) {
    _currentTool = tool;
    if (tool != EditingTool.select) {
      _selectedNote = null;
    }
    notifyListeners();
  }

  /// Set the current note duration for adding notes
  void setDuration(NoteDuration duration) {
    _currentDuration = duration;
    notifyListeners();
  }

  /// Set the current accidental for adding notes
  void setAccidental(int? accidental) {
    _currentAccidental = accidental;
    notifyListeners();
  }

  /// Select a note at the given position
  void selectNote(int partIndex, int measureIndex, int noteIndex) {
    if (_score == null) return;
    if (partIndex < 0 || partIndex >= _score!.parts.length) return;
    
    final part = _score!.parts[partIndex];
    if (measureIndex < 0 || measureIndex >= part.measures.length) return;
    
    final measure = part.measures[measureIndex];
    if (noteIndex < 0 || noteIndex >= measure.elements.length) return;
    
    final element = measure.elements[noteIndex];
    if (element is! Note) return;

    _selectedNote = SelectedNote(
      partIndex: partIndex,
      measureIndex: measureIndex,
      noteIndex: noteIndex,
      note: element,
    );
    notifyListeners();
  }

  /// Deselect the current note
  void deselectNote() {
    _selectedNote = null;
    notifyListeners();
  }

  /// Add a note at the specified position
  void addNote({
    required int partIndex,
    required int measureIndex,
    required int noteIndex,
    required String step,
    required int octave,
  }) {
    if (_score == null) return;
    
    _saveToHistory();
    
    // Get the measure's divisions for calculating duration
    final measure = _score!.parts[partIndex].measures[measureIndex];
    final divisions = measure.attributes?.divisions ?? 1;
    
    // Calculate duration in divisions
    final duration = (_currentDuration.relativeValue * 4 * divisions).round();
    
    final newNote = Note(
      pitch: Pitch(
        step: step,
        alter: _currentAccidental,
        octave: octave,
      ),
      duration: duration,
      type: _currentDuration.xmlType,
      isRest: false,
    );

    // Insert the note at the specified position
    final elements = List<MusicElement>.from(measure.elements);
    if (noteIndex >= 0 && noteIndex <= elements.length) {
      elements.insert(noteIndex, newNote);
    } else {
      elements.add(newNote);
    }

    _updateMeasure(partIndex, measureIndex, elements);
    _isModified = true;
    notifyListeners();
  }

  /// Add a rest at the specified position
  void addRest({
    required int partIndex,
    required int measureIndex,
    required int noteIndex,
  }) {
    if (_score == null) return;
    
    _saveToHistory();
    
    // Get the measure's divisions for calculating duration
    final measure = _score!.parts[partIndex].measures[measureIndex];
    final divisions = measure.attributes?.divisions ?? 1;
    
    // Calculate duration in divisions
    final duration = (_currentDuration.relativeValue * 4 * divisions).round();
    
    final newRest = Note(
      duration: duration,
      type: _currentDuration.xmlType,
      isRest: true,
    );

    // Insert the rest at the specified position
    final elements = List<MusicElement>.from(measure.elements);
    if (noteIndex >= 0 && noteIndex <= elements.length) {
      elements.insert(noteIndex, newRest);
    } else {
      elements.add(newRest);
    }

    _updateMeasure(partIndex, measureIndex, elements);
    _isModified = true;
    notifyListeners();
  }

  /// Delete the selected note
  void deleteSelectedNote() {
    if (_selectedNote == null || _score == null) return;
    
    _saveToHistory();
    
    final elements = List<MusicElement>.from(
      _score!.parts[_selectedNote!.partIndex]
          .measures[_selectedNote!.measureIndex]
          .elements,
    );
    
    if (_selectedNote!.noteIndex >= 0 && 
        _selectedNote!.noteIndex < elements.length) {
      elements.removeAt(_selectedNote!.noteIndex);
    }

    _updateMeasure(
      _selectedNote!.partIndex,
      _selectedNote!.measureIndex,
      elements,
    );
    
    _selectedNote = null;
    _isModified = true;
    notifyListeners();
  }

  /// Change the pitch of the selected note
  void changeSelectedNotePitch(String step, int octave) {
    if (_selectedNote == null || _score == null) return;
    if (_selectedNote!.note.isRest) return;
    
    _saveToHistory();
    
    final elements = List<MusicElement>.from(
      _score!.parts[_selectedNote!.partIndex]
          .measures[_selectedNote!.measureIndex]
          .elements,
    );
    
    final oldNote = _selectedNote!.note;
    final newNote = Note(
      pitch: Pitch(
        step: step,
        alter: oldNote.pitch?.alter,
        octave: octave,
      ),
      duration: oldNote.duration,
      type: oldNote.type,
      isRest: false,
      isChord: oldNote.isChord,
      voice: oldNote.voice,
      notations: oldNote.notations,
    );

    elements[_selectedNote!.noteIndex] = newNote;
    _updateMeasure(
      _selectedNote!.partIndex,
      _selectedNote!.measureIndex,
      elements,
    );
    
    // Update selected note reference
    _selectedNote = SelectedNote(
      partIndex: _selectedNote!.partIndex,
      measureIndex: _selectedNote!.measureIndex,
      noteIndex: _selectedNote!.noteIndex,
      note: newNote,
    );
    
    _isModified = true;
    notifyListeners();
  }

  /// Change the accidental of the selected note
  void changeSelectedNoteAccidental(int? alter) {
    if (_selectedNote == null || _score == null) return;
    if (_selectedNote!.note.isRest) return;
    
    _saveToHistory();
    
    final elements = List<MusicElement>.from(
      _score!.parts[_selectedNote!.partIndex]
          .measures[_selectedNote!.measureIndex]
          .elements,
    );
    
    final oldNote = _selectedNote!.note;
    final newNote = Note(
      pitch: Pitch(
        step: oldNote.pitch!.step,
        alter: alter,
        octave: oldNote.pitch!.octave,
      ),
      duration: oldNote.duration,
      type: oldNote.type,
      isRest: false,
      isChord: oldNote.isChord,
      voice: oldNote.voice,
      notations: oldNote.notations,
    );

    elements[_selectedNote!.noteIndex] = newNote;
    _updateMeasure(
      _selectedNote!.partIndex,
      _selectedNote!.measureIndex,
      elements,
    );
    
    // Update selected note reference
    _selectedNote = SelectedNote(
      partIndex: _selectedNote!.partIndex,
      measureIndex: _selectedNote!.measureIndex,
      noteIndex: _selectedNote!.noteIndex,
      note: newNote,
    );
    
    _isModified = true;
    notifyListeners();
  }

  /// Change the duration of the selected note
  void changeSelectedNoteDuration(NoteDuration duration) {
    if (_selectedNote == null || _score == null) return;
    
    _saveToHistory();
    
    final measure = _score!.parts[_selectedNote!.partIndex]
        .measures[_selectedNote!.measureIndex];
    final divisions = measure.attributes?.divisions ?? 1;
    final newDuration = (duration.relativeValue * 4 * divisions).round();
    
    final elements = List<MusicElement>.from(measure.elements);
    
    final oldNote = _selectedNote!.note;
    final newNote = Note(
      pitch: oldNote.pitch,
      duration: newDuration,
      type: duration.xmlType,
      isRest: oldNote.isRest,
      isChord: oldNote.isChord,
      voice: oldNote.voice,
      notations: oldNote.notations,
    );

    elements[_selectedNote!.noteIndex] = newNote;
    _updateMeasure(
      _selectedNote!.partIndex,
      _selectedNote!.measureIndex,
      elements,
    );
    
    // Update selected note reference
    _selectedNote = SelectedNote(
      partIndex: _selectedNote!.partIndex,
      measureIndex: _selectedNote!.measureIndex,
      noteIndex: _selectedNote!.noteIndex,
      note: newNote,
    );
    
    _isModified = true;
    notifyListeners();
  }

  /// Undo the last action
  void undo() {
    if (!canUndo) return;
    
    _historyIndex--;
    _score = _deepCopyScore(_history[_historyIndex]);
    _selectedNote = null;
    _isModified = _historyIndex > 0;
    notifyListeners();
  }

  /// Redo the last undone action
  void redo() {
    if (!canRedo) return;
    
    _historyIndex++;
    _score = _deepCopyScore(_history[_historyIndex]);
    _selectedNote = null;
    _isModified = true;
    notifyListeners();
  }

  /// Save the current state to history
  void _saveToHistory() {
    if (_score == null) return;
    
    // Remove any redo history
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    // Add current state
    _history.add(_deepCopyScore(_score!));
    _historyIndex++;
    
    // Limit history size
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  /// Update a measure with new elements
  void _updateMeasure(
    int partIndex,
    int measureIndex,
    List<MusicElement> elements,
  ) {
    if (_score == null) return;
    
    final parts = List<Part>.from(_score!.parts);
    final part = parts[partIndex];
    final measures = List<Measure>.from(part.measures);
    final measure = measures[measureIndex];
    
    measures[measureIndex] = Measure(
      number: measure.number,
      elements: elements,
      attributes: measure.attributes,
    );
    
    parts[partIndex] = Part(id: part.id, measures: measures);
    
    _score = MusicXmlScore(
      header: _score!.header,
      parts: parts,
      partList: _score!.partList,
    );
  }

  /// Deep copy a score (simplified - in production would need proper cloning)
  MusicXmlScore _deepCopyScore(MusicXmlScore score) {
    // This is a simplified copy. In production, you'd want a proper deep clone
    // For now, we'll create new instances to ensure immutability
    return MusicXmlScore(
      header: score.header,
      parts: score.parts.map((part) => Part(
        id: part.id,
        measures: part.measures.map((measure) => Measure(
          number: measure.number,
          elements: List<MusicElement>.from(measure.elements),
          attributes: measure.attributes,
        )).toList(),
      )).toList(),
      partList: List<PartInfo>.from(score.partList),
    );
  }

  /// Reset modifications flag (after save)
  void markAsSaved() {
    _isModified = false;
    notifyListeners();
  }
}
