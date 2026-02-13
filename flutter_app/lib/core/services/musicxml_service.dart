import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/musicxml_model.dart';

/// Service for parsing and working with MusicXML files
class MusicXmlService extends ChangeNotifier {
  /// Parse a MusicXML file and return the score
  Future<MusicXmlScore?> parseFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final xmlString = await file.readAsString();
      return MusicXmlScore.parse(xmlString);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing MusicXML file: $e');
      }
      return null;
    }
  }

  /// Parse MusicXML from a string
  MusicXmlScore? parseString(String xmlString) {
    return MusicXmlScore.parse(xmlString);
  }

  /// Validate a MusicXML file
  Future<bool> validateFile(String filePath) async {
    try {
      final score = await parseFile(filePath);
      return score != null && score.parts.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Extract metadata from a MusicXML score
  Map<String, dynamic> extractMetadata(MusicXmlScore score) {
    final metadata = <String, dynamic>{};

    // Basic information
    metadata['title'] = score.header.title;
    metadata['composer'] = score.header.composer;
    metadata['lyricist'] = score.header.lyricist;

    // Count measures across all parts
    final measureCounts = score.parts.map((p) => p.measures.length).toList();
    metadata['measureCount'] = measureCounts.isNotEmpty
        ? measureCounts.reduce((a, b) => a > b ? a : b)
        : 0;

    // Get instruments
    metadata['instruments'] = score.partList.map((p) => p.name).toList();
    metadata['partCount'] = score.parts.length;

    // Get time and key signature from first measure
    if (score.parts.isNotEmpty && score.parts.first.measures.isNotEmpty) {
      final firstMeasure = score.parts.first.measures.first;
      if (firstMeasure.attributes != null) {
        final attrs = firstMeasure.attributes!;
        
        if (attrs.timeSignature != null) {
          metadata['timeSignature'] = attrs.timeSignature.toString();
        }
        
        if (attrs.keySignature != null) {
          metadata['keySignature'] = attrs.keySignature.toString();
        }
      }
    }

    return metadata;
  }

  /// Count the total number of notes in a score
  int countNotes(MusicXmlScore score) {
    var count = 0;
    for (final part in score.parts) {
      for (final measure in part.measures) {
        count += measure.elements.whereType<Note>().where((n) => !n.isRest).length;
      }
    }
    return count;
  }

  /// Get the duration of the score in quarter notes
  int getScoreDuration(MusicXmlScore score) {
    if (score.parts.isEmpty) return 0;

    var maxDuration = 0;
    for (final part in score.parts) {
      var partDuration = 0;
      for (final measure in part.measures) {
        for (final element in measure.elements) {
          if (element is Note && !element.isChord) {
            partDuration += element.duration;
          }
        }
      }
      if (partDuration > maxDuration) {
        maxDuration = partDuration;
      }
    }

    return maxDuration;
  }

  /// Convert MusicXML duration to seconds (approximate)
  double durationToSeconds(int duration, int divisions, int tempo) {
    // duration is in divisions
    // divisions = number of divisions per quarter note
    // tempo = beats per minute (quarter notes per minute)
    final quarterNotes = duration / divisions;
    final minutes = quarterNotes / tempo;
    return minutes * 60;
  }
}
