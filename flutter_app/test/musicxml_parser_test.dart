import 'package:flutter_test/flutter_test.dart';
import 'package:sheet_music_reader/core/models/musicxml_model.dart';

void main() {
  group('MusicXML Parser Tests', () {
    test('Parse simple MusicXML score', () {
      const xmlString = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" 
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <movement-title>Test Score</movement-title>
  <identification>
    <creator type="composer">Test Composer</creator>
  </identification>
  <part-list>
    <score-part id="P1">
      <part-name>Piano</part-name>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>1</divisions>
        <key>
          <fifths>0</fifths>
        </key>
        <time>
          <beats>4</beats>
          <beat-type>4</beat-type>
        </time>
        <clef>
          <sign>G</sign>
          <line>2</line>
        </clef>
      </attributes>
      <note>
        <pitch>
          <step>C</step>
          <octave>4</octave>
        </pitch>
        <duration>4</duration>
        <type>whole</type>
      </note>
    </measure>
  </part>
</score-partwise>''';

      final score = MusicXmlScore.parse(xmlString);

      expect(score, isNotNull);
      expect(score!.header.title, 'Test Score');
      expect(score.header.composer, 'Test Composer');
      expect(score.partList.length, 1);
      expect(score.partList[0].name, 'Piano');
      expect(score.parts.length, 1);
      expect(score.parts[0].measures.length, 1);
    });

    test('Parse note with pitch', () {
      const xmlString = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1">
      <part-name>Test</part-name>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <note>
        <pitch>
          <step>A</step>
          <alter>1</alter>
          <octave>5</octave>
        </pitch>
        <duration>2</duration>
        <type>half</type>
      </note>
    </measure>
  </part>
</score-partwise>''';

      final score = MusicXmlScore.parse(xmlString);
      expect(score, isNotNull);

      final note = score!.parts[0].measures[0].elements[0] as Note;
      expect(note.pitch, isNotNull);
      expect(note.pitch!.step, 'A');
      expect(note.pitch!.alter, 1);
      expect(note.pitch!.octave, 5);
      expect(note.pitch.toString(), 'A#5');
      expect(note.duration, 2);
      expect(note.type, 'half');
      expect(note.isRest, false);
    });

    test('Parse rest', () {
      const xmlString = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1">
      <part-name>Test</part-name>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <note>
        <rest/>
        <duration>4</duration>
        <type>whole</type>
      </note>
    </measure>
  </part>
</score-partwise>''';

      final score = MusicXmlScore.parse(xmlString);
      expect(score, isNotNull);

      final note = score!.parts[0].measures[0].elements[0] as Note;
      expect(note.isRest, true);
      expect(note.pitch, isNull);
      expect(note.duration, 4);
    });

    test('Parse time signature', () {
      const xmlString = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1">
      <part-name>Test</part-name>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <time>
          <beats>3</beats>
          <beat-type>4</beat-type>
        </time>
      </attributes>
    </measure>
  </part>
</score-partwise>''';

      final score = MusicXmlScore.parse(xmlString);
      expect(score, isNotNull);

      final attrs = score!.parts[0].measures[0].attributes;
      expect(attrs, isNotNull);
      expect(attrs!.timeSignature, isNotNull);
      expect(attrs.timeSignature!.beats, 3);
      expect(attrs.timeSignature!.beatType, 4);
      expect(attrs.timeSignature.toString(), '3/4');
    });

    test('Parse key signature', () {
      const xmlString = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1">
      <part-name>Test</part-name>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <key>
          <fifths>2</fifths>
          <mode>major</mode>
        </key>
      </attributes>
    </measure>
  </part>
</score-partwise>''';

      final score = MusicXmlScore.parse(xmlString);
      expect(score, isNotNull);

      final attrs = score!.parts[0].measures[0].attributes;
      expect(attrs, isNotNull);
      expect(attrs!.keySignature, isNotNull);
      expect(attrs.keySignature!.fifths, 2);
      expect(attrs.keySignature!.mode, 'major');
      expect(attrs.keySignature.toString(), 'D major');
    });

    test('Parse clef', () {
      const xmlString = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1">
      <part-name>Test</part-name>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <clef>
          <sign>F</sign>
          <line>4</line>
        </clef>
      </attributes>
    </measure>
  </part>
</score-partwise>''';

      final score = MusicXmlScore.parse(xmlString);
      expect(score, isNotNull);

      final attrs = score!.parts[0].measures[0].attributes;
      expect(attrs, isNotNull);
      expect(attrs!.clef, isNotNull);
      expect(attrs.clef!.sign, 'F');
      expect(attrs.clef!.line, 4);
    });
  });
}
