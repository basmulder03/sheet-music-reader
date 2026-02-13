import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/musicxml_model.dart';
import '../../core/services/note_editing_service.dart';

/// Interactive widget for rendering and editing MusicXML
class InteractiveMusicRenderer extends StatefulWidget {
  final MusicXmlScore score;
  final double zoom;
  final bool isEditMode;

  const InteractiveMusicRenderer({
    super.key,
    required this.score,
    this.zoom = 1.0,
    this.isEditMode = false,
  });

  @override
  State<InteractiveMusicRenderer> createState() => _InteractiveMusicRendererState();
}

class _InteractiveMusicRendererState extends State<InteractiveMusicRenderer> {
  final ScrollController _scrollController = ScrollController();
  Offset? _hoverPosition;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteEditingService>(
      builder: (context, editingService, _) {
        return MouseRegion(
          onHover: widget.isEditMode ? (event) {
            setState(() {
              _hoverPosition = event.localPosition / widget.zoom;
            });
          } : null,
          onExit: (_) {
            if (widget.isEditMode) {
              setState(() {
                _hoverPosition = null;
              });
            }
          },
          child: GestureDetector(
            onTapDown: widget.isEditMode ? (details) {
              _handleTap(context, editingService, details.localPosition / widget.zoom);
            } : null,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Transform.scale(
                  scale: widget.zoom,
                  alignment: Alignment.topLeft,
                  child: CustomPaint(
                    painter: _InteractiveScorePainter(
                      widget.score,
                      Theme.of(context),
                      editingService.selectedNote,
                      _hoverPosition,
                      widget.isEditMode,
                    ),
                    size: _calculateScoreSize(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Size _calculateScoreSize() {
    final measureCount = widget.score.parts.isEmpty 
        ? 0 
        : widget.score.parts.first.measures.length;
    final partCount = widget.score.parts.length;
    
    const measuresPerLine = 4.0;
    const measureWidth = 200.0;
    const systemHeight = 150.0;
    final lines = (measureCount / measuresPerLine).ceil();
    
    return Size(
      measuresPerLine * measureWidth + 100,
      lines * systemHeight * partCount + 100,
    );
  }

  void _handleTap(BuildContext context, NoteEditingService editingService, Offset position) {
    final result = _findNoteAtPosition(position);
    
    if (result != null) {
      if (editingService.currentTool == EditingTool.select) {
        editingService.selectNote(
          result['partIndex'] as int,
          result['measureIndex'] as int,
          result['noteIndex'] as int,
        );
      } else if (editingService.currentTool == EditingTool.delete) {
        editingService.selectNote(
          result['partIndex'] as int,
          result['measureIndex'] as int,
          result['noteIndex'] as int,
        );
        editingService.deleteSelectedNote();
      }
    } else if (editingService.currentTool == EditingTool.addNote ||
               editingService.currentTool == EditingTool.addRest) {
      _handleAddNote(context, editingService, position);
    }
  }

  Map<String, dynamic>? _findNoteAtPosition(Offset position) {
    const staffLineSpacing = 10.0;
    const measuresPerLine = 4.0;
    const measureWidth = 200.0;
    var yOffset = 50.0;

    for (var partIndex = 0; partIndex < widget.score.parts.length; partIndex++) {
      final part = widget.score.parts[partIndex];
      var xOffset = 50.0;
      var lineYOffset = yOffset;

      for (var measureIndex = 0; measureIndex < part.measures.length; measureIndex++) {
        if (measureIndex > 0 && measureIndex % measuresPerLine == 0) {
          xOffset = 50.0;
          lineYOffset += 150.0;
        }

        final measure = part.measures[measureIndex];
        final notes = measure.elements.whereType<Note>().toList();
        final noteSpacing = (measureWidth - 80) / (notes.length + 1);
        var noteX = xOffset + 60;

        for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
          final note = notes[noteIndex];
          final noteY = lineYOffset + (note.pitch != null 
              ? (4 - _getLinePosition(note.pitch!.step, note.pitch!.octave)) * staffLineSpacing / 2
              : 2 * staffLineSpacing);

          // Check if position is within note bounds
          final noteRect = Rect.fromCenter(
            center: Offset(noteX, noteY),
            width: 20,
            height: 20,
          );

          if (noteRect.contains(position)) {
            return {
              'partIndex': partIndex,
              'measureIndex': measureIndex,
              'noteIndex': noteIndex,
              'note': note,
            };
          }

          noteX += noteSpacing;
        }

        xOffset += measureWidth;
      }

      yOffset += 150.0 * ((part.measures.length / measuresPerLine).ceil());
    }

    return null;
  }

  void _handleAddNote(BuildContext context, NoteEditingService editingService, Offset position) {
    // Find the measure and calculate pitch from Y position
    const staffLineSpacing = 10.0;
    const measuresPerLine = 4.0;
    const measureWidth = 200.0;
    var yOffset = 50.0;

    for (var partIndex = 0; partIndex < widget.score.parts.length; partIndex++) {
      final part = widget.score.parts[partIndex];
      var xOffset = 50.0;
      var lineYOffset = yOffset;

      for (var measureIndex = 0; measureIndex < part.measures.length; measureIndex++) {
        if (measureIndex > 0 && measureIndex % measuresPerLine == 0) {
          xOffset = 50.0;
          lineYOffset += 150.0;
        }

        // Check if click is within this measure
        final measureRect = Rect.fromLTWH(
          xOffset,
          lineYOffset,
          measureWidth,
          staffLineSpacing * 4,
        );

        if (measureRect.contains(position)) {
          // Calculate pitch from Y position
          final relativeY = position.dy - lineYOffset;
          final linePosition = ((staffLineSpacing * 4 - relativeY) / (staffLineSpacing / 2)).round();
          final pitchInfo = _getPitchFromLinePosition(linePosition);

          if (editingService.currentTool == EditingTool.addNote) {
            // Find position in measure for insertion
            final measure = part.measures[measureIndex];
            final notes = measure.elements.whereType<Note>().toList();
            final noteSpacing = (measureWidth - 80) / (notes.length + 1);
            var noteX = xOffset + 60;
            var insertIndex = notes.length;

            for (var i = 0; i < notes.length; i++) {
              if (position.dx < noteX + noteSpacing / 2) {
                insertIndex = i;
                break;
              }
              noteX += noteSpacing;
            }

            editingService.addNote(
              partIndex: partIndex,
              measureIndex: measureIndex,
              noteIndex: insertIndex,
              step: pitchInfo['step'] as String,
              octave: pitchInfo['octave'] as int,
            );
          } else if (editingService.currentTool == EditingTool.addRest) {
            final measure = part.measures[measureIndex];
            final notes = measure.elements.whereType<Note>().toList();
            
            editingService.addRest(
              partIndex: partIndex,
              measureIndex: measureIndex,
              noteIndex: notes.length,
            );
          }
          return;
        }

        xOffset += measureWidth;
      }

      yOffset += 150.0 * ((part.measures.length / measuresPerLine).ceil());
    }
  }

  int _getLinePosition(String step, int octave) {
    const steps = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final stepIndex = steps.indexOf(step);
    return (octave - 4) * 7 + stepIndex;
  }

  Map<String, dynamic> _getPitchFromLinePosition(int linePosition) {
    const steps = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final octave = 4 + (linePosition / 7).floor();
    final stepIndex = linePosition % 7;
    return {
      'step': steps[stepIndex < 0 ? stepIndex + 7 : stepIndex],
      'octave': octave,
    };
  }
}

/// Custom painter for interactive score rendering
class _InteractiveScorePainter extends CustomPainter {
  final MusicXmlScore score;
  final ThemeData theme;
  final SelectedNote? selectedNote;
  final Offset? hoverPosition;
  final bool isEditMode;

  _InteractiveScorePainter(
    this.score,
    this.theme,
    this.selectedNote,
    this.hoverPosition,
    this.isEditMode,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.onSurface
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    var yOffset = 50.0;

    for (var partIndex = 0; partIndex < score.parts.length; partIndex++) {
      final part = score.parts[partIndex];
      _drawPart(canvas, size, part, partIndex, yOffset, paint, textPainter);
      yOffset += 150.0 * ((part.measures.length / 4).ceil());
    }
  }

  void _drawPart(Canvas canvas, Size size, Part part, int partIndex, double startY, 
      Paint paint, TextPainter textPainter) {
    const staffLineSpacing = 10.0;
    const measuresPerLine = 4.0;
    const measureWidth = 200.0;
    var xOffset = 50.0;
    var yOffset = startY;

    for (var measureIndex = 0; measureIndex < part.measures.length; measureIndex++) {
      if (measureIndex > 0 && measureIndex % measuresPerLine == 0) {
        xOffset = 50.0;
        yOffset += 150.0;
      }

      final measure = part.measures[measureIndex];
      _drawMeasure(canvas, measure, partIndex, measureIndex, xOffset, yOffset, 
          staffLineSpacing, measureWidth, paint, textPainter);
      xOffset += measureWidth;
    }
  }

  void _drawMeasure(Canvas canvas, Measure measure, int partIndex, int measureIndex,
      double x, double y, double staffLineSpacing, double measureWidth, 
      Paint paint, TextPainter textPainter) {
    
    // Draw staff lines
    for (var i = 0; i < 5; i++) {
      final lineY = y + i * staffLineSpacing;
      canvas.drawLine(
        Offset(x, lineY),
        Offset(x + measureWidth, lineY),
        paint,
      );
    }

    // Draw measure number
    textPainter.text = TextSpan(
      text: measure.number.toString(),
      style: TextStyle(
        color: paint.color,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - 20));

    // Draw attributes (clef, time, key)
    if (measure.attributes?.clef != null) {
      _drawClef(canvas, measure.attributes!.clef!, x + 10, y, 
          staffLineSpacing, paint, textPainter);
    }

    if (measure.attributes?.timeSignature != null) {
      final clefWidth = measure.attributes?.clef != null ? 30.0 : 0.0;
      _drawTimeSignature(canvas, measure.attributes!.timeSignature!, 
          x + 10 + clefWidth, y, staffLineSpacing, paint, textPainter);
    }

    if (measure.attributes?.keySignature != null) {
      final clefWidth = measure.attributes?.clef != null ? 30.0 : 0.0;
      final timeWidth = measure.attributes?.timeSignature != null ? 30.0 : 0.0;
      _drawKeySignature(canvas, measure.attributes!.keySignature!, 
          x + 10 + clefWidth + timeWidth, y, staffLineSpacing, paint, textPainter);
    }

    // Draw notes
    var noteX = x + 60;
    final notes = measure.elements.whereType<Note>().toList();
    final noteSpacing = (measureWidth - 80) / (notes.length + 1);

    for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
      final note = notes[noteIndex];
      final isSelected = selectedNote != null &&
          selectedNote!.partIndex == partIndex &&
          selectedNote!.measureIndex == measureIndex &&
          selectedNote!.noteIndex == noteIndex;

      if (note.pitch != null && !note.isRest) {
        _drawNote(canvas, note, noteX, y, staffLineSpacing, paint, 
            textPainter, isSelected);
      } else if (note.isRest) {
        _drawRest(canvas, note, noteX, y, staffLineSpacing, paint, 
            textPainter, isSelected);
      }
      noteX += noteSpacing;
    }

    // Draw measure end barline
    canvas.drawLine(
      Offset(x + measureWidth, y),
      Offset(x + measureWidth, y + 4 * staffLineSpacing),
      paint,
    );
  }

  void _drawClef(Canvas canvas, Clef clef, double x, double y, 
      double staffLineSpacing, Paint paint, TextPainter textPainter) {
    var clefSymbol = '';
    var yOffset = 0.0;

    if (clef.sign == 'G') {
      clefSymbol = '𝄞';
      yOffset = staffLineSpacing * 2;
    } else if (clef.sign == 'F') {
      clefSymbol = '𝄢';
      yOffset = staffLineSpacing * 1;
    } else if (clef.sign == 'C') {
      clefSymbol = '𝄡';
      yOffset = staffLineSpacing * 2;
    }

    textPainter.text = TextSpan(
      text: clefSymbol,
      style: TextStyle(
        color: paint.color,
        fontSize: 40,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y + yOffset - 15));
  }

  void _drawTimeSignature(Canvas canvas, TimeSignature time, double x, double y, 
      double staffLineSpacing, Paint paint, TextPainter textPainter) {
    textPainter.text = TextSpan(
      text: time.beats.toString(),
      style: TextStyle(
        color: paint.color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y + staffLineSpacing * 1 - 8));

    textPainter.text = TextSpan(
      text: time.beatType.toString(),
      style: TextStyle(
        color: paint.color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y + staffLineSpacing * 3 - 8));
  }

  void _drawKeySignature(Canvas canvas, KeySignature key, double x, double y, 
      double staffLineSpacing, Paint paint, TextPainter textPainter) {
    final fifths = key.fifths;
    if (fifths == 0) return;

    final isSharp = fifths > 0;
    final count = fifths.abs();
    final symbol = isSharp ? '♯' : '♭';

    for (var i = 0; i < count && i < 7; i++) {
      textPainter.text = TextSpan(
        text: symbol,
        style: TextStyle(
          color: paint.color,
          fontSize: 20,
        ),
      );
      textPainter.layout();
      
      final lineOffset = _getAccidentalPosition(isSharp, i);
      textPainter.paint(canvas, Offset(x + i * 10, y + lineOffset * staffLineSpacing));
    }
  }

  int _getAccidentalPosition(bool isSharp, int index) {
    if (isSharp) {
      const sharpPositions = [1, 3, 0, 2, 4, 1, 3];
      return sharpPositions[index % sharpPositions.length];
    } else {
      const flatPositions = [3, 1, 4, 2, 0, 3, 1];
      return flatPositions[index % flatPositions.length];
    }
  }

  void _drawNote(Canvas canvas, Note note, double x, double y, 
      double staffLineSpacing, Paint paint, TextPainter textPainter, bool isSelected) {
    final pitch = note.pitch!;
    final linePosition = _getLinePosition(pitch.step, pitch.octave);
    final noteY = y + (4 - linePosition) * staffLineSpacing / 2;

    // Draw selection highlight
    if (isSelected && isEditMode) {
      final highlightPaint = Paint()
        ..color = theme.colorScheme.primary.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, noteY), 10, highlightPaint);
    }

    // Draw ledger lines if needed
    if (linePosition < 0) {
      for (var i = 0; i > linePosition; i -= 2) {
        canvas.drawLine(
          Offset(x - 6, y + (4 - i) * staffLineSpacing / 2),
          Offset(x + 6, y + (4 - i) * staffLineSpacing / 2),
          paint,
        );
      }
    } else if (linePosition > 8) {
      for (var i = 8; i < linePosition; i += 2) {
        canvas.drawLine(
          Offset(x - 6, y + (4 - i) * staffLineSpacing / 2),
          Offset(x + 6, y + (4 - i) * staffLineSpacing / 2),
          paint,
        );
      }
    }

    // Draw note head
    final notePaint = Paint()
      ..color = isSelected ? theme.colorScheme.primary : paint.color
      ..style = note.type == 'whole' || note.type == 'half' 
          ? PaintingStyle.stroke 
          : PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, noteY),
        width: 8,
        height: 6,
      ),
      notePaint,
    );

    // Draw stem
    if (note.type != 'whole') {
      final stemHeight = staffLineSpacing * 3.5;
      final stemUp = linePosition >= 6;
      final stemX = stemUp ? x + 4 : x - 4;
      final stemY1 = noteY;
      final stemY2 = stemUp ? noteY - stemHeight : noteY + stemHeight;
      
      canvas.drawLine(
        Offset(stemX, stemY1),
        Offset(stemX, stemY2),
        notePaint..style = PaintingStyle.stroke,
      );

      // Draw flag for eighth notes
      if (note.type == 'eighth' || note.type == '16th') {
        textPainter.text = TextSpan(
          text: stemUp ? '𝅘𝅥𝅮' : '𝅘𝅥𝅯',
          style: TextStyle(
            color: isSelected ? theme.colorScheme.primary : paint.color,
            fontSize: 20,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(stemX - 5, stemY2 - 10));
      }
    }

    // Draw accidental
    if (pitch.alter != null) {
      final accidental = pitch.alter! > 0 ? '♯' : '♭';
      textPainter.text = TextSpan(
        text: accidental,
        style: TextStyle(
          color: isSelected ? theme.colorScheme.primary : paint.color,
          fontSize: 16,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 15, noteY - 8));
    }
  }

  void _drawRest(Canvas canvas, Note note, double x, double y, 
      double staffLineSpacing, Paint paint, TextPainter textPainter, bool isSelected) {
    // Draw selection highlight
    if (isSelected && isEditMode) {
      final highlightPaint = Paint()
        ..color = theme.colorScheme.primary.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y + 2 * staffLineSpacing), 10, highlightPaint);
    }

    var restSymbol = '';
    switch (note.type) {
      case 'whole':
        restSymbol = '𝄻';
        break;
      case 'half':
        restSymbol = '𝄼';
        break;
      case 'quarter':
        restSymbol = '𝄽';
        break;
      case 'eighth':
        restSymbol = '𝄾';
        break;
      case '16th':
        restSymbol = '𝄿';
        break;
      default:
        restSymbol = '𝄽';
    }

    textPainter.text = TextSpan(
      text: restSymbol,
      style: TextStyle(
        color: isSelected ? theme.colorScheme.primary : paint.color,
        fontSize: 20,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - 5, y + staffLineSpacing - 5));
  }

  int _getLinePosition(String step, int octave) {
    const steps = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final stepIndex = steps.indexOf(step);
    return (octave - 4) * 7 + stepIndex;
  }

  @override
  bool shouldRepaint(_InteractiveScorePainter oldDelegate) {
    return oldDelegate.selectedNote != selectedNote ||
           oldDelegate.hoverPosition != hoverPosition;
  }
}
