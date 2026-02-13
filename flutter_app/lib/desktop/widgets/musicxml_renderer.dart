import 'package:flutter/material.dart';
import '../../core/models/musicxml_model.dart';

/// Widget for rendering MusicXML as visual sheet music
class MusicXmlRenderer extends StatefulWidget {
  final MusicXmlScore score;
  final double zoom;
  final VoidCallback? onTap;

  const MusicXmlRenderer({
    super.key,
    required this.score,
    this.zoom = 1.0,
    this.onTap,
  });

  @override
  State<MusicXmlRenderer> createState() => _MusicXmlRendererState();
}

class _MusicXmlRendererState extends State<MusicXmlRenderer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Transform.scale(
            scale: widget.zoom,
            alignment: Alignment.topLeft,
            child: CustomPaint(
              painter: _ScorePainter(widget.score, Theme.of(context)),
              size: _calculateScoreSize(),
            ),
          ),
        ),
      ),
    );
  }

  Size _calculateScoreSize() {
    // Calculate approximate size based on measures and parts
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
}

/// Custom painter for rendering musical notation
class _ScorePainter extends CustomPainter {
  final MusicXmlScore score;
  final ThemeData theme;

  _ScorePainter(this.score, this.theme);

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

    for (final part in score.parts) {
      _drawPart(canvas, size, part, yOffset, paint, textPainter);
      yOffset += 150.0 * ((part.measures.length / 4).ceil());
    }
  }

  void _drawPart(Canvas canvas, Size size, Part part, double startY, Paint paint, TextPainter textPainter) {
    const staffLineSpacing = 10.0;
    const measuresPerLine = 4.0;
    const measureWidth = 200.0;
    var xOffset = 50.0;
    var yOffset = startY;
    var measureIndex = 0;

    for (final measure in part.measures) {
      // Start new line after every 4 measures
      if (measureIndex > 0 && measureIndex % measuresPerLine == 0) {
        xOffset = 50.0;
        yOffset += 150.0;
      }

      _drawMeasure(canvas, measure, xOffset, yOffset, staffLineSpacing, measureWidth, paint, textPainter);
      xOffset += measureWidth;
      measureIndex++;
    }
  }

  void _drawMeasure(Canvas canvas, Measure measure, double x, double y, 
      double staffLineSpacing, double measureWidth, Paint paint, TextPainter textPainter) {
    
    // Draw staff lines (5 lines)
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

    // Draw clef if present
    if (measure.attributes?.clef != null) {
      _drawClef(canvas, measure.attributes!.clef!, x + 10, y, staffLineSpacing, paint, textPainter);
    }

    // Draw time signature if present
    if (measure.attributes?.timeSignature != null) {
      final clefWidth = measure.attributes?.clef != null ? 30.0 : 0.0;
      _drawTimeSignature(canvas, measure.attributes!.timeSignature!, x + 10 + clefWidth, y, staffLineSpacing, paint, textPainter);
    }

    // Draw key signature if present
    if (measure.attributes?.keySignature != null) {
      final clefWidth = measure.attributes?.clef != null ? 30.0 : 0.0;
      final timeWidth = measure.attributes?.timeSignature != null ? 30.0 : 0.0;
      _drawKeySignature(canvas, measure.attributes!.keySignature!, x + 10 + clefWidth + timeWidth, y, staffLineSpacing, paint, textPainter);
    }

    // Draw notes
    var noteX = x + 60; // Start after clef, time, key
    final notes = measure.elements.whereType<Note>().toList();
    final noteSpacing = (measureWidth - 80) / (notes.length + 1);

    for (final note in notes) {
      if (note.pitch != null && !note.isRest) {
        _drawNote(canvas, note, noteX, y, staffLineSpacing, paint, textPainter);
      } else if (note.isRest) {
        _drawRest(canvas, note, noteX, y, staffLineSpacing, paint, textPainter);
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

  void _drawClef(Canvas canvas, Clef clef, double x, double y, double staffLineSpacing, Paint paint, TextPainter textPainter) {
    var clefSymbol = '';
    var yOffset = 0.0;

    if (clef.sign == 'G') {
      clefSymbol = '𝄞'; // Treble clef
      yOffset = staffLineSpacing * 2;
    } else if (clef.sign == 'F') {
      clefSymbol = '𝄢'; // Bass clef
      yOffset = staffLineSpacing * 1;
    } else if (clef.sign == 'C') {
      clefSymbol = '𝄡'; // Alto clef
      yOffset = staffLineSpacing * 2;
    }

    textPainter.text = TextSpan(
      text: clefSymbol,
      style: TextStyle(
        color: paint.color,
        fontSize: 40,
        fontFamily: 'Noto Music', // Use music font if available
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y + yOffset - 15));
  }

  void _drawTimeSignature(Canvas canvas, TimeSignature time, double x, double y, double staffLineSpacing, Paint paint, TextPainter textPainter) {
    // Draw beats
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

    // Draw beat type
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

  void _drawKeySignature(Canvas canvas, KeySignature key, double x, double y, double staffLineSpacing, Paint paint, TextPainter textPainter) {
    final fifths = key.fifths;
    if (fifths == 0) return; // C major / A minor

    // Draw sharps or flats
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
      
      // Position accidentals on appropriate staff lines
      final lineOffset = _getAccidentalPosition(isSharp, i);
      textPainter.paint(canvas, Offset(x + i * 10, y + lineOffset * staffLineSpacing));
    }
  }

  int _getAccidentalPosition(bool isSharp, int index) {
    // Simplified positioning - in a real implementation, this would follow
    // the circle of fifths pattern for proper placement
    if (isSharp) {
      const sharpPositions = [1, 3, 0, 2, 4, 1, 3];
      return sharpPositions[index % sharpPositions.length];
    } else {
      const flatPositions = [3, 1, 4, 2, 0, 3, 1];
      return flatPositions[index % flatPositions.length];
    }
  }

  void _drawNote(Canvas canvas, Note note, double x, double y, double staffLineSpacing, Paint paint, TextPainter textPainter) {
    final pitch = note.pitch!;
    final linePosition = _getLinePosition(pitch.step, pitch.octave);
    final noteY = y + (4 - linePosition) * staffLineSpacing / 2;

    // Draw note head
    final notePaint = Paint()
      ..color = paint.color
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

    // Draw stem (except for whole notes)
    if (note.type != 'whole') {
      final stemHeight = staffLineSpacing * 3.5;
      final stemUp = linePosition >= 6;
      final stemX = stemUp ? x + 4 : x - 4;
      final stemY1 = noteY;
      final stemY2 = stemUp ? noteY - stemHeight : noteY + stemHeight;

      canvas.drawLine(
        Offset(stemX, stemY1),
        Offset(stemX, stemY2),
        paint,
      );
    }

    // Draw accidental if present
    if (pitch.alter != null && pitch.alter != 0) {
      var accidental = '';
      if (pitch.alter! > 0) {
        accidental = '♯';
      } else if (pitch.alter! < 0) {
        accidental = '♭';
      }

      textPainter.text = TextSpan(
        text: accidental,
        style: TextStyle(
          color: paint.color,
          fontSize: 16,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 15, noteY - 8));
    }

    // Draw ledger lines if needed
    _drawLedgerLines(canvas, x, linePosition, staffLineSpacing, paint);
  }

  void _drawRest(Canvas canvas, Note note, double x, double y, double staffLineSpacing, Paint paint, TextPainter textPainter) {
    var restSymbol = '';
    
    // Simplified rest symbols
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
      default:
        restSymbol = '𝄽'; // Default to quarter rest
    }

    textPainter.text = TextSpan(
      text: restSymbol,
      style: TextStyle(
        color: paint.color,
        fontSize: 24,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - 8, y + staffLineSpacing * 1.5 - 12));
  }

  void _drawLedgerLines(Canvas canvas, double x, int linePosition, double staffLineSpacing, Paint paint) {
    // Draw ledger lines above staff
    if (linePosition > 8) {
      for (var i = 10; i <= linePosition; i += 2) {
        final lineY = (8 - i) * staffLineSpacing / 2;
        canvas.drawLine(
          Offset(x - 6, lineY),
          Offset(x + 6, lineY),
          paint,
        );
      }
    }
    
    // Draw ledger lines below staff
    if (linePosition < 0) {
      for (var i = -2; i >= linePosition; i -= 2) {
        final lineY = (8 - i) * staffLineSpacing / 2;
        canvas.drawLine(
          Offset(x - 6, lineY),
          Offset(x + 6, lineY),
          paint,
        );
      }
    }
  }

  int _getLinePosition(String step, int octave) {
    // Position on the staff (0 = bottom line, 8 = top line for treble clef)
    // This is simplified for treble clef
    const stepPositions = {
      'C': 0,
      'D': 1,
      'E': 2,
      'F': 3,
      'G': 4,
      'A': 5,
      'B': 6,
    };

    final basePosition = stepPositions[step] ?? 0;
    final octaveOffset = (octave - 4) * 7; // Adjust for octave relative to C4
    
    return basePosition + octaveOffset;
  }

  @override
  bool shouldRepaint(covariant _ScorePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.theme != theme;
  }
}
