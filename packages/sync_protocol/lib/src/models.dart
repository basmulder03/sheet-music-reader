enum ArtifactFormat {
  musicxml,
  pdf,
  image,
  midi,
  unknown;

  static ArtifactFormat fromString(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'musicxml':
      case 'xml':
        return ArtifactFormat.musicxml;
      case 'pdf':
        return ArtifactFormat.pdf;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return ArtifactFormat.image;
      case 'midi':
      case 'mid':
        return ArtifactFormat.midi;
      default:
        return ArtifactFormat.unknown;
    }
  }
}

class SyncDocument {
  const SyncDocument({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.updatedAt,
    this.composer,
    this.arranger,
    this.metadata = const <String, dynamic>{},
    this.deletedAt,
  });

  final String id;
  final String tenantId;
  final String title;
  final String? composer;
  final String? arranger;
  final Map<String, dynamic> metadata;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'tenantId': tenantId,
      'title': title,
      'composer': composer,
      'arranger': arranger,
      'metadata': metadata,
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory SyncDocument.fromJson(Map<String, dynamic> json) {
    return SyncDocument(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String? ?? 'default',
      title: json['title'] as String,
      composer: json['composer'] as String?,
      arranger: json['arranger'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }
}

class SyncArtifact {
  const SyncArtifact({
    required this.documentId,
    required this.tenantId,
    required this.format,
    required this.mimeType,
    required this.size,
    required this.checksum,
    required this.version,
    required this.storageKey,
    required this.updatedAt,
  });

  final String documentId;
  final String tenantId;
  final ArtifactFormat format;
  final String mimeType;
  final int size;
  final String checksum;
  final int version;
  final String storageKey;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'documentId': documentId,
      'tenantId': tenantId,
      'format': format.name,
      'mimeType': mimeType,
      'size': size,
      'checksum': checksum,
      'version': version,
      'storageKey': storageKey,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SyncArtifact.fromJson(Map<String, dynamic> json) {
    return SyncArtifact(
      documentId: json['documentId'] as String,
      tenantId: json['tenantId'] as String? ?? 'default',
      format: ArtifactFormat.fromString(json['format'] as String),
      mimeType: json['mimeType'] as String,
      size: json['size'] as int,
      checksum: json['checksum'] as String,
      version: json['version'] as int,
      storageKey: json['storageKey'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class SyncEvent {
  const SyncEvent({
    required this.id,
    required this.tenantId,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.eventVersion,
    required this.createdAt,
  });

  final int id;
  final String tenantId;
  final String entityType;
  final String entityId;
  final String eventType;
  final int eventVersion;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'tenantId': tenantId,
      'entityType': entityType,
      'entityId': entityId,
      'eventType': eventType,
      'eventVersion': eventVersion,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
