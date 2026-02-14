import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sync_protocol/sync_protocol.dart';

import 'metadata_store.dart';

class SqliteMetadataStore implements MetadataStore {
  SqliteMetadataStore({required this.dataDirectoryPath});

  final String dataDirectoryPath;
  Database? _db;

  @override
  Future<void> initialize() async {
    final dir = Directory(dataDirectoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dbPath = p.join(dir.path, 'sync_backend.db');
    _db = sqlite3.open(dbPath);
    _db!.execute('PRAGMA journal_mode=WAL;');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT NOT NULL,
        tenant_id TEXT NOT NULL,
        title TEXT NOT NULL,
        composer TEXT,
        arranger TEXT,
        metadata_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        PRIMARY KEY (tenant_id, id)
      );
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS artifacts (
        tenant_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        format TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        version INTEGER NOT NULL,
        storage_key TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (tenant_id, document_id, format)
      );
    ''');

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS sync_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        event_version INTEGER NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('Metadata store not initialized');
    }
    return db;
  }

  @override
  Future<List<SyncDocument>> listDocuments({
    required String tenantId,
    int? sinceEventId,
    int limit = 50,
  }) async {
    final db = _database;
    if (sinceEventId != null) {
      final stmt = db.prepare('''
        SELECT DISTINCT d.*
        FROM documents d
        JOIN sync_events e ON e.entity_id = d.id AND e.tenant_id = d.tenant_id
        WHERE d.tenant_id = ? AND e.id > ?
        ORDER BY d.updated_at DESC
        LIMIT ?
      ''');
      final rows = stmt.select([tenantId, sinceEventId, limit]);
      stmt.dispose();
      return rows.map(_documentFromRow).toList();
    }

    final stmt = db.prepare('''
      SELECT * FROM documents
      WHERE tenant_id = ?
      ORDER BY updated_at DESC
      LIMIT ?
    ''');
    final rows = stmt.select([tenantId, limit]);
    stmt.dispose();
    return rows.map(_documentFromRow).toList();
  }

  @override
  Future<SyncDocument?> getDocument({
    required String tenantId,
    required String documentId,
  }) async {
    final stmt = _database.prepare('''
      SELECT * FROM documents WHERE tenant_id = ? AND id = ?
    ''');
    final rows = stmt.select([tenantId, documentId]);
    stmt.dispose();
    if (rows.isEmpty) {
      return null;
    }
    return _documentFromRow(rows.first);
  }

  @override
  Future<void> upsertDocument(SyncDocument document) async {
    _database.execute('''
      INSERT INTO documents (
        id, tenant_id, title, composer, arranger, metadata_json, updated_at, deleted_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(tenant_id, id)
      DO UPDATE SET
        title = excluded.title,
        composer = excluded.composer,
        arranger = excluded.arranger,
        metadata_json = excluded.metadata_json,
        updated_at = excluded.updated_at,
        deleted_at = excluded.deleted_at
    ''', [
      document.id,
      document.tenantId,
      document.title,
      document.composer,
      document.arranger,
      jsonEncode(document.metadata),
      document.updatedAt.toIso8601String(),
      document.deletedAt?.toIso8601String(),
    ]);
  }

  @override
  Future<List<SyncArtifact>> listArtifacts({
    required String tenantId,
    required String documentId,
  }) async {
    final stmt = _database.prepare('''
      SELECT * FROM artifacts
      WHERE tenant_id = ? AND document_id = ?
      ORDER BY format ASC
    ''');
    final rows = stmt.select([tenantId, documentId]);
    stmt.dispose();
    return rows.map(_artifactFromRow).toList();
  }

  @override
  Future<SyncArtifact?> getArtifact({
    required String tenantId,
    required String documentId,
    required ArtifactFormat format,
  }) async {
    final stmt = _database.prepare('''
      SELECT * FROM artifacts
      WHERE tenant_id = ? AND document_id = ? AND format = ?
    ''');
    final rows = stmt.select([tenantId, documentId, format.name]);
    stmt.dispose();
    if (rows.isEmpty) {
      return null;
    }
    return _artifactFromRow(rows.first);
  }

  @override
  Future<SyncArtifact> upsertArtifact(SyncArtifact artifact) async {
    _database.execute('''
      INSERT INTO artifacts (
        tenant_id, document_id, format, mime_type, size, checksum, version, storage_key, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(tenant_id, document_id, format)
      DO UPDATE SET
        mime_type = excluded.mime_type,
        size = excluded.size,
        checksum = excluded.checksum,
        version = excluded.version,
        storage_key = excluded.storage_key,
        updated_at = excluded.updated_at
    ''', [
      artifact.tenantId,
      artifact.documentId,
      artifact.format.name,
      artifact.mimeType,
      artifact.size,
      artifact.checksum,
      artifact.version,
      artifact.storageKey,
      artifact.updatedAt.toIso8601String(),
    ]);
    return artifact;
  }

  @override
  Future<int> appendEvent({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String eventType,
    required int eventVersion,
  }) async {
    _database.execute('''
      INSERT INTO sync_events (
        tenant_id, entity_type, entity_id, event_type, event_version, created_at
      ) VALUES (?, ?, ?, ?, ?, ?)
    ''', [
      tenantId,
      entityType,
      entityId,
      eventType,
      eventVersion,
      DateTime.now().toUtc().toIso8601String(),
    ]);

    final row = _database.select('SELECT last_insert_rowid() AS id').first;
    return row['id'] as int;
  }

  @override
  Future<List<SyncEvent>> getChanges({
    required String tenantId,
    required int since,
    int limit = 100,
  }) async {
    final stmt = _database.prepare('''
      SELECT * FROM sync_events
      WHERE tenant_id = ? AND id > ?
      ORDER BY id ASC
      LIMIT ?
    ''');
    final rows = stmt.select([tenantId, since, limit]);
    stmt.dispose();
    return rows.map((row) {
      return SyncEvent(
        id: row['id'] as int,
        tenantId: row['tenant_id'] as String,
        entityType: row['entity_type'] as String,
        entityId: row['entity_id'] as String,
        eventType: row['event_type'] as String,
        eventVersion: row['event_version'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  SyncDocument _documentFromRow(Row row) {
    return SyncDocument(
      id: row['id'] as String,
      tenantId: row['tenant_id'] as String,
      title: row['title'] as String,
      composer: row['composer'] as String?,
      arranger: row['arranger'] as String?,
      metadata: (jsonDecode(row['metadata_json'] as String) as Map)
          .cast<String, dynamic>(),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      deletedAt: row['deleted_at'] != null
          ? DateTime.parse(row['deleted_at'] as String)
          : null,
    );
  }

  SyncArtifact _artifactFromRow(Row row) {
    return SyncArtifact(
      documentId: row['document_id'] as String,
      tenantId: row['tenant_id'] as String,
      format: ArtifactFormat.fromString(row['format'] as String),
      mimeType: row['mime_type'] as String,
      size: row['size'] as int,
      checksum: row['checksum'] as String,
      version: row['version'] as int,
      storageKey: row['storage_key'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Future<void> close() async {
    _db?.dispose();
    _db = null;
  }
}
