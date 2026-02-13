import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart';

/// Represents a parsed MusicXML score
class MusicXmlScore {
  final ScoreHeader header;
  final List<Part> parts;
  final List<PartInfo> partList;

  MusicXmlScore({
    required this.header,
    required this.parts,
    required this.partList,
  });

  /// Parse MusicXML from string
  static MusicXmlScore? parse(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;

      if (root.name.local != 'score-partwise' &&
          root.name.local != 'score-timewise') {
        return null;
      }

      // Parse header information
      final header = ScoreHeader.fromXml(root);

      // Parse part list
      final partListElement = root.findElements('part-list').firstOrNull;
      final partList = partListElement != null
          ? _parsePartList(partListElement)
          : <PartInfo>[];

      // Parse parts
      final parts = root
          .findElements('part')
          .map((e) => Part.fromXml(e))
          .whereType<Part>()
          .toList();

      return MusicXmlScore(
        header: header,
        parts: parts,
        partList: partList,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing MusicXML: $e');
      }
      return null;
    }
  }

  static List<PartInfo> _parsePartList(XmlElement partListElement) {
    final partInfos = <PartInfo>[];
    for (final element in partListElement.children.whereType<XmlElement>()) {
      if (element.name.local == 'score-part') {
        final id = element.getAttribute('id') ?? '';
        final name = element.findElements('part-name').firstOrNull?.innerText ?? '';
        final abbreviation =
            element.findElements('part-abbreviation').firstOrNull?.innerText;
        
        partInfos.add(PartInfo(
          id: id,
          name: name,
          abbreviation: abbreviation,
        ));
      }
    }
    return partInfos;
  }
}

/// Header information for a score
class ScoreHeader {
  final String? title;
  final String? composer;
  final String? lyricist;
  final String? rights;
  final String? software;

  ScoreHeader({
    this.title,
    this.composer,
    this.lyricist,
    this.rights,
    this.software,
  });

  factory ScoreHeader.fromXml(XmlElement root) {
    final identification = root.findElements('identification').firstOrNull;
    String? composer;
    String? lyricist;

    if (identification != null) {
      for (final creator in identification.findElements('creator')) {
        final type = creator.getAttribute('type');
        if (type == 'composer') {
          composer = creator.innerText;
        } else if (type == 'lyricist') {
          lyricist = creator.innerText;
        }
      }
    }

    return ScoreHeader(
      title: root.findElements('movement-title').firstOrNull?.innerText,
      composer: composer,
      lyricist: lyricist,
      rights: root.findElements('rights').firstOrNull?.innerText,
      software: identification?.findElements('software').firstOrNull?.innerText,
    );
  }
}

/// Information about a part in the score
class PartInfo {
  final String id;
  final String name;
  final String? abbreviation;

  PartInfo({
    required this.id,
    required this.name,
    this.abbreviation,
  });
}

/// A part in the score (e.g., a single instrument)
class Part {
  final String id;
  final List<Measure> measures;

  Part({
    required this.id,
    required this.measures,
  });

  static Part? fromXml(XmlElement element) {
    final id = element.getAttribute('id');
    if (id == null) return null;

    final measures = element
        .findElements('measure')
        .map((e) => Measure.fromXml(e))
        .whereType<Measure>()
        .toList();

    return Part(id: id, measures: measures);
  }
}

/// A measure in the score
class Measure {
  final int number;
  final List<MusicElement> elements;
  final Attributes? attributes;

  Measure({
    required this.number,
    required this.elements,
    this.attributes,
  });

  static Measure? fromXml(XmlElement element) {
    final numberStr = element.getAttribute('number');
    if (numberStr == null) return null;
    final number = int.tryParse(numberStr);
    if (number == null) return null;

    // Parse attributes (time signature, key, etc.)
    final attributesElement = element.findElements('attributes').firstOrNull;
    final attributes =
        attributesElement != null ? Attributes.fromXml(attributesElement) : null;

    // Parse all music elements (notes, rests, etc.)
    final elements = <MusicElement>[];
    for (final child in element.children.whereType<XmlElement>()) {
      switch (child.name.local) {
        case 'note':
          final note = Note.fromXml(child);
          if (note != null) elements.add(note);
          break;
        case 'backup':
        case 'forward':
          // Handle duration elements
          break;
        case 'direction':
          // Handle directions (dynamics, tempo, etc.)
          break;
      }
    }

    return Measure(
      number: number,
      elements: elements,
      attributes: attributes,
    );
  }
}

/// Base class for musical elements
abstract class MusicElement {
  const MusicElement();
}

/// A note or rest
class Note extends MusicElement {
  final Pitch? pitch; // null for rests
  final int duration;
  final String type; // whole, half, quarter, eighth, etc.
  final bool isRest;
  final bool isChord;
  final int? voice;
  final List<String> notations;

  Note({
    this.pitch,
    required this.duration,
    required this.type,
    this.isRest = false,
    this.isChord = false,
    this.voice,
    this.notations = const [],
  });

  static Note? fromXml(XmlElement element) {
    final isRest = element.findElements('rest').isNotEmpty;
    final isChord = element.findElements('chord').isNotEmpty;

    Pitch? pitch;
    if (!isRest) {
      final pitchElement = element.findElements('pitch').firstOrNull;
      if (pitchElement != null) {
        pitch = Pitch.fromXml(pitchElement);
      }
    }

    final durationStr = element.findElements('duration').firstOrNull?.innerText;
    final duration = durationStr != null ? int.tryParse(durationStr) ?? 0 : 0;

    final type = element.findElements('type').firstOrNull?.innerText ?? 'quarter';
    final voiceStr = element.findElements('voice').firstOrNull?.innerText;
    final voice = voiceStr != null ? int.tryParse(voiceStr) : null;

    return Note(
      pitch: pitch,
      duration: duration,
      type: type,
      isRest: isRest,
      isChord: isChord,
      voice: voice,
    );
  }
}

/// Musical pitch
class Pitch {
  final String step; // C, D, E, F, G, A, B
  final int? alter; // -1 for flat, 1 for sharp
  final int octave;

  Pitch({
    required this.step,
    this.alter,
    required this.octave,
  });

  static Pitch? fromXml(XmlElement element) {
    final step = element.findElements('step').firstOrNull?.innerText;
    final octaveStr = element.findElements('octave').firstOrNull?.innerText;
    
    if (step == null || octaveStr == null) return null;
    
    final octave = int.tryParse(octaveStr);
    if (octave == null) return null;

    final alterStr = element.findElements('alter').firstOrNull?.innerText;
    final alter = alterStr != null ? int.tryParse(alterStr) : null;

    return Pitch(step: step, alter: alter, octave: octave);
  }

  @override
  String toString() {
    var result = step;
    if (alter != null) {
      result += alter! > 0 ? '#' : 'b';
    }
    result += octave.toString();
    return result;
  }
}

/// Musical attributes (time signature, key signature, clef, etc.)
class Attributes {
  final int? divisions; // divisions per quarter note
  final TimeSignature? timeSignature;
  final KeySignature? keySignature;
  final Clef? clef;
  final int? staves;

  Attributes({
    this.divisions,
    this.timeSignature,
    this.keySignature,
    this.clef,
    this.staves,
  });

  static Attributes fromXml(XmlElement element) {
    final divisionsStr = element.findElements('divisions').firstOrNull?.innerText;
    final divisions = divisionsStr != null ? int.tryParse(divisionsStr) : null;

    final timeElement = element.findElements('time').firstOrNull;
    final timeSignature =
        timeElement != null ? TimeSignature.fromXml(timeElement) : null;

    final keyElement = element.findElements('key').firstOrNull;
    final keySignature =
        keyElement != null ? KeySignature.fromXml(keyElement) : null;

    final clefElement = element.findElements('clef').firstOrNull;
    final clef = clefElement != null ? Clef.fromXml(clefElement) : null;

    final stavesStr = element.findElements('staves').firstOrNull?.innerText;
    final staves = stavesStr != null ? int.tryParse(stavesStr) : null;

    return Attributes(
      divisions: divisions,
      timeSignature: timeSignature,
      keySignature: keySignature,
      clef: clef,
      staves: staves,
    );
  }
}

/// Time signature
class TimeSignature {
  final int beats;
  final int beatType;

  TimeSignature({required this.beats, required this.beatType});

  static TimeSignature? fromXml(XmlElement element) {
    final beatsStr = element.findElements('beats').firstOrNull?.innerText;
    final beatTypeStr = element.findElements('beat-type').firstOrNull?.innerText;

    if (beatsStr == null || beatTypeStr == null) return null;

    final beats = int.tryParse(beatsStr);
    final beatType = int.tryParse(beatTypeStr);

    if (beats == null || beatType == null) return null;

    return TimeSignature(beats: beats, beatType: beatType);
  }

  @override
  String toString() => '$beats/$beatType';
}

/// Key signature
class KeySignature {
  final int fifths; // -7 to 7, negative for flats, positive for sharps
  final String mode; // major or minor

  KeySignature({required this.fifths, this.mode = 'major'});

  static KeySignature? fromXml(XmlElement element) {
    final fifthsStr = element.findElements('fifths').firstOrNull?.innerText;
    if (fifthsStr == null) return null;

    final fifths = int.tryParse(fifthsStr);
    if (fifths == null) return null;

    final mode = element.findElements('mode').firstOrNull?.innerText ?? 'major';

    return KeySignature(fifths: fifths, mode: mode);
  }

  @override
  String toString() {
    final keys = {
      -7: 'Cb', -6: 'Gb', -5: 'Db', -4: 'Ab', -3: 'Eb', -2: 'Bb', -1: 'F',
      0: 'C', 1: 'G', 2: 'D', 3: 'A', 4: 'E', 5: 'B', 6: 'F#', 7: 'C#',
    };
    return '${keys[fifths]} $mode';
  }
}

/// Clef
class Clef {
  final String sign; // G, F, C
  final int line; // 1-5

  Clef({required this.sign, required this.line});

  static Clef? fromXml(XmlElement element) {
    final sign = element.findElements('sign').firstOrNull?.innerText;
    final lineStr = element.findElements('line').firstOrNull?.innerText;

    if (sign == null || lineStr == null) return null;

    final line = int.tryParse(lineStr);
    if (line == null) return null;

    return Clef(sign: sign, line: line);
  }

  @override
  String toString() => '$sign clef on line $line';
}
