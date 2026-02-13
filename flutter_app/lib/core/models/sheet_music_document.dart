import 'package:flutter/material.dart' show Color, Offset, Size;

/// Represents a complete sheet music document
class SheetMusicDocument {
  final String id;
  final String title;
  final String? composer;
  final String? arranger;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? sourcePath; // Original PDF/image path
  final String musicXmlPath; // Path to MusicXML file
  final List<String> tags;
  final DocumentMetadata metadata;

  SheetMusicDocument({
    required this.id,
    required this.title,
    this.composer,
    this.arranger,
    required this.createdAt,
    required this.modifiedAt,
    this.sourcePath,
    required this.musicXmlPath,
    this.tags = const [],
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'composer': composer,
        'arranger': arranger,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'sourcePath': sourcePath,
        'musicXmlPath': musicXmlPath,
        'tags': tags,
        'metadata': metadata.toJson(),
      };

  factory SheetMusicDocument.fromJson(Map<String, dynamic> json) {
    return SheetMusicDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      composer: json['composer'] as String?,
      arranger: json['arranger'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      sourcePath: json['sourcePath'] as String?,
      musicXmlPath: json['musicXmlPath'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: DocumentMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  SheetMusicDocument copyWith({
    String? id,
    String? title,
    String? composer,
    String? arranger,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? sourcePath,
    String? musicXmlPath,
    List<String>? tags,
    DocumentMetadata? metadata,
  }) {
    return SheetMusicDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      arranger: arranger ?? this.arranger,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      sourcePath: sourcePath ?? this.sourcePath,
      musicXmlPath: musicXmlPath ?? this.musicXmlPath,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Metadata about the document
class DocumentMetadata {
  final int pageCount;
  final String? timeSignature;
  final String? keySignature;
  final int? tempo;
  final List<String> instruments;
  final int? measureCount;

  DocumentMetadata({
    required this.pageCount,
    this.timeSignature,
    this.keySignature,
    this.tempo,
    this.instruments = const [],
    this.measureCount,
  });

  Map<String, dynamic> toJson() => {
        'pageCount': pageCount,
        'timeSignature': timeSignature,
        'keySignature': keySignature,
        'tempo': tempo,
        'instruments': instruments,
        'measureCount': measureCount,
      };

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      pageCount: json['pageCount'] as int,
      timeSignature: json['timeSignature'] as String?,
      keySignature: json['keySignature'] as String?,
      tempo: json['tempo'] as int?,
      instruments: (json['instruments'] as List<dynamic>?)?.cast<String>() ?? [],
      measureCount: json['measureCount'] as int?,
    );
  }
}

/// User annotations on sheet music
class Annotation {
  final String id;
  final String documentId;
  final int page;
  final AnnotationType type;
  final String? text;
  final Color? color;
  final Offset position;
  final Size? size;
  final DateTime createdAt;

  Annotation({
    required this.id,
    required this.documentId,
    required this.page,
    required this.type,
    this.text,
    this.color,
    required this.position,
    this.size,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentId': documentId,
        'page': page,
        'type': type.toString(),
        'text': text,
        // ignore: deprecated_member_use
        'color': color?.value,
        'position': {'dx': position.dx, 'dy': position.dy},
        'size': size != null ? {'width': size!.width, 'height': size!.height} : null,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Annotation.fromJson(Map<String, dynamic> json) {
    final posMap = json['position'] as Map<String, dynamic>;
    final sizeMap = json['size'] as Map<String, dynamic>?;

    return Annotation(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      page: json['page'] as int,
      type: AnnotationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AnnotationType.note,
      ),
      text: json['text'] as String?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      position: Offset(posMap['dx'] as double, posMap['dy'] as double),
      size: sizeMap != null
          ? Size(sizeMap['width'] as double, sizeMap['height'] as double)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum AnnotationType {
  note,
  highlight,
  drawing,
  fingering,
  dynamics,
}
