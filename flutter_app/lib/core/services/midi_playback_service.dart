import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../models/musicxml_model.dart';

/// Service for MIDI playback of MusicXML scores
class MidiPlaybackService extends ChangeNotifier {
  PlaybackState _state = PlaybackState.stopped;
  double _currentPosition = 0.0; // in seconds
  double _duration = 0.0; // in seconds
  int _tempo = 120; // BPM
  double _volume = 0.8;
  MusicXmlScore? _currentScore;
  Timer? _playbackTimer;
  int _currentMeasureIndex = 0;
  int _currentNoteIndex = 0;

  PlaybackState get state => _state;
  double get currentPosition => _currentPosition;
  double get duration => _duration;
  int get tempo => _tempo;
  double get volume => _volume;
  MusicXmlScore? get currentScore => _currentScore;
  int get currentMeasureIndex => _currentMeasureIndex;

  /// Load a score for playback
  Future<void> loadScore(MusicXmlScore score) async {
    _currentScore = score;
    _currentPosition = 0.0;
    _currentMeasureIndex = 0;
    _currentNoteIndex = 0;
    
    // Calculate duration
    _duration = _calculateDuration(score);
    
    // Get tempo from first measure if available
    final firstMeasure = score.parts.isNotEmpty && score.parts.first.measures.isNotEmpty
        ? score.parts.first.measures.first
        : null;
    
    if (firstMeasure?.attributes?.divisions != null) {
      // Use divisions to calculate timing
      // Default to 120 BPM if not specified
      _tempo = 120;
    }
    
    notifyListeners();
  }

  /// Start playback
  Future<void> play() async {
    if (_currentScore == null) return;
    
    if (_state == PlaybackState.paused) {
      _state = PlaybackState.playing;
      _resumePlayback();
    } else {
      _state = PlaybackState.playing;
      _startPlayback();
    }
    
    notifyListeners();
  }

  /// Pause playback
  void pause() {
    if (_state != PlaybackState.playing) return;
    
    _state = PlaybackState.paused;
    _playbackTimer?.cancel();
    notifyListeners();
  }

  /// Stop playback
  void stop() {
    _state = PlaybackState.stopped;
    _playbackTimer?.cancel();
    _currentPosition = 0.0;
    _currentMeasureIndex = 0;
    _currentNoteIndex = 0;
    notifyListeners();
  }

  /// Seek to a specific position (in seconds)
  void seek(double position) {
    if (_currentScore == null) return;
    
    _currentPosition = position.clamp(0.0, _duration);
    _updateMeasureIndexFromPosition();
    notifyListeners();
    
    if (_state == PlaybackState.playing) {
      _playbackTimer?.cancel();
      _resumePlayback();
    }
  }

  /// Set playback tempo (BPM)
  void setTempo(int bpm) {
    _tempo = bpm.clamp(40, 240);
    notifyListeners();
    
    if (_state == PlaybackState.playing) {
      _playbackTimer?.cancel();
      _resumePlayback();
    }
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Start playback from current position
  void _startPlayback() {
    _playbackTimer?.cancel();
    _resumePlayback();
  }

  /// Resume playback
  void _resumePlayback() {
    if (_currentScore == null) return;
    
    // Calculate time per quarter note in seconds
    final secondsPerBeat = 60.0 / _tempo;
    
    // Update position every 100ms for smooth progress
    const updateInterval = Duration(milliseconds: 100);
    final incrementPerUpdate = 0.1; // 100ms in seconds
    
    _playbackTimer = Timer.periodic(updateInterval, (timer) {
      if (_state != PlaybackState.playing) {
        timer.cancel();
        return;
      }
      
      _currentPosition += incrementPerUpdate;
      
      // Check if we've reached the end
      if (_currentPosition >= _duration) {
        stop();
        return;
      }
      
      _updateMeasureIndexFromPosition();
      
      // Trigger note playback based on position
      _playNotesAtCurrentPosition();
      
      notifyListeners();
    });
  }

  /// Play notes at the current playback position
  void _playNotesAtCurrentPosition() {
    // This is a placeholder for actual MIDI note playback
    // In a real implementation, you would:
    // 1. Calculate which notes should be playing at _currentPosition
    // 2. Trigger MIDI events or synthesize audio
    // 3. Use flutter_midi_command or audioplayers to play sounds
    
    if (kDebugMode) {
      // Debug: print current position
      // print('Playing at position: ${_currentPosition.toStringAsFixed(2)}s, measure: $_currentMeasureIndex');
    }
  }

  /// Update the current measure index based on playback position
  void _updateMeasureIndexFromPosition() {
    if (_currentScore == null || _currentScore!.parts.isEmpty) return;
    
    final part = _currentScore!.parts.first;
    if (part.measures.isEmpty) return;
    
    // Calculate approximate measure based on position
    // This is simplified - in reality you'd need to account for varying time signatures
    final secondsPerBeat = 60.0 / _tempo;
    final beatsPerMeasure = 4.0; // Assume 4/4 time for simplicity
    final secondsPerMeasure = secondsPerBeat * beatsPerMeasure;
    
    _currentMeasureIndex = (_currentPosition / secondsPerMeasure).floor().clamp(0, part.measures.length - 1);
  }

  /// Calculate the total duration of the score in seconds
  double _calculateDuration(MusicXmlScore score) {
    if (score.parts.isEmpty) return 0.0;
    
    var maxDuration = 0.0;
    
    for (final part in score.parts) {
      var partDuration = 0.0;
      var divisions = 1; // Default divisions per quarter note
      
      for (final measure in part.measures) {
        // Update divisions if specified
        if (measure.attributes?.divisions != null) {
          divisions = measure.attributes!.divisions!;
        }
        
        // Sum up note durations in this measure
        var measureDuration = 0;
        for (final element in measure.elements) {
          if (element is Note && !element.isChord) {
            measureDuration += element.duration;
          }
        }
        
        // Convert duration to seconds
        // duration is in divisions, convert to quarter notes, then to seconds
        final quarterNotes = measureDuration / divisions;
        final secondsPerBeat = 60.0 / _tempo;
        partDuration += quarterNotes * secondsPerBeat;
      }
      
      if (partDuration > maxDuration) {
        maxDuration = partDuration;
      }
    }
    
    return maxDuration;
  }

  /// Convert MusicXML note to MIDI note number
  int _noteToMidi(Note note) {
    if (note.pitch == null) return 60; // Default to middle C
    
    final pitch = note.pitch!;
    
    // Map step to base MIDI number (C4 = 60)
    const stepToMidi = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };
    
    final baseNote = stepToMidi[pitch.step] ?? 0;
    final octaveOffset = (pitch.octave - 4) * 12;
    final alteration = pitch.alter ?? 0;
    
    return 60 + baseNote + octaveOffset + alteration;
  }

  /// Get duration of a note in seconds
  double _getNoteDuration(Note note, int divisions) {
    final quarterNotes = note.duration / divisions;
    final secondsPerBeat = 60.0 / _tempo;
    return quarterNotes * secondsPerBeat;
  }

  /// Generate a simple tone for demonstration
  /// In a production app, you'd use proper MIDI samples or a synthesizer
  Future<void> _playTone(int midiNote, double duration) async {
    // This is a placeholder
    // In reality, you would:
    // 1. Load MIDI sample files for each note
    // 2. Use flutter_midi_command to play MIDI
    // 3. Or use a synthesis library to generate audio
    
    if (kDebugMode) {
      print('Playing MIDI note $midiNote for ${duration.toStringAsFixed(2)}s');
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

/// Playback state enum
enum PlaybackState {
  stopped,
  playing,
  paused,
}
