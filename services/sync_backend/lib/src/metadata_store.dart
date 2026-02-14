import 'package:sync_protocol/sync_protocol.dart';

abstract interface class MetadataStore {
  Future<void> initialize();

  Future<List<SyncDocument>> listDocuments({
    required String tenantId,
    int? sinceEventId,
    int limit,
  });

  Future<SyncDocument?> getDocument({
    required String tenantId,
    required String documentId,
  });

  Future<void> upsertDocument(SyncDocument document);

  Future<List<SyncArtifact>> listArtifacts({
    required String tenantId,
    required String documentId,
  });

  Future<SyncArtifact?> getArtifact({
    required String tenantId,
    required String documentId,
    required ArtifactFormat format,
  });

  Future<SyncArtifact> upsertArtifact(SyncArtifact artifact);

  Future<int> appendEvent({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String eventType,
    required int eventVersion,
  });

  Future<List<SyncEvent>> getChanges({
    required String tenantId,
    required int since,
    required int limit,
  });

  Future<void> close();
}
