import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sync_protocol/sync_protocol.dart';

import 'blob_store.dart';
import 'filesystem_blob_store.dart';
import 'metadata_store.dart';
import 'sqlite_metadata_store.dart';

class SyncBackendServer {
  SyncBackendServer({
    required this.dataDirectoryPath,
    required this.apiToken,
  })  : _metadataStore =
            SqliteMetadataStore(dataDirectoryPath: dataDirectoryPath),
        _blobStore = FileSystemBlobStore(baseDirectoryPath: dataDirectoryPath);

  final String dataDirectoryPath;
  final String apiToken;
  final MetadataStore _metadataStore;
  final BlobStore _blobStore;
  HttpServer? _server;

  static const String _defaultTenantId = 'default';

  Future<void> start({required String host, required int port}) async {
    await _metadataStore.initialize();
    if (_blobStore is FileSystemBlobStore) {
      await (_blobStore as FileSystemBlobStore).ensureInitialized();
    }

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_authMiddleware)
        .addHandler(_router.call);

    _server = await shelf_io.serve(handler, host, port);

    stdout.writeln(
      '[sync_backend] listening on http://${_server!.address.host}:${_server!.port}',
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    await _metadataStore.close();
  }

  Middleware get _authMiddleware {
    return (inner) {
      return (request) async {
        if (request.url.path == 'v1/health') {
          return inner(request);
        }

        final token = request.headers['authorization'];
        final expected = 'Bearer $apiToken';
        if (token != expected) {
          return Response.unauthorized(
            jsonEncode(<String, dynamic>{'error': 'unauthorized'}),
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return inner(request);
      };
    };
  }

  Router get _router {
    final router = Router();

    router.get('/v1/health', (Request request) {
      return _jsonResponse(<String, dynamic>{
        'status': 'ok',
        'service': 'sync_backend',
        'storage': 'filesystem+sqlite',
        'tenantMode': 'single',
      });
    });

    router.get('/v1/documents', (Request request) async {
      final since = int.tryParse(request.url.queryParameters['since'] ?? '');
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 50;

      final docs = await _metadataStore.listDocuments(
        tenantId: _defaultTenantId,
        sinceEventId: since,
        limit: limit,
      );
      return _jsonResponse(<String, dynamic>{
        'documents': docs.map((d) => d.toJson()).toList(),
      });
    });

    router.get('/v1/documents/<id>', (Request request, String id) async {
      final doc = await _metadataStore.getDocument(
        tenantId: _defaultTenantId,
        documentId: id,
      );
      if (doc == null) {
        return _notFound('document not found');
      }
      return _jsonResponse(doc.toJson());
    });

    router.put('/v1/documents/<id>', (Request request, String id) async {
      final body = await request.readAsString();
      final payload = jsonDecode(body) as Map<String, dynamic>;

      final now = DateTime.now().toUtc();
      final doc = SyncDocument(
        id: id,
        tenantId: _defaultTenantId,
        title: payload['title'] as String? ?? 'Untitled',
        composer: payload['composer'] as String?,
        arranger: payload['arranger'] as String?,
        metadata: (payload['metadata'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
        updatedAt: now,
      );

      await _metadataStore.upsertDocument(doc);
      final eventId = await _metadataStore.appendEvent(
        tenantId: _defaultTenantId,
        entityType: 'document',
        entityId: id,
        eventType: 'upsert',
        eventVersion: now.millisecondsSinceEpoch,
      );

      return _jsonResponse(<String, dynamic>{
        'document': doc.toJson(),
        'eventId': eventId,
      });
    });

    router.get('/v1/documents/<id>/artifacts',
        (Request request, String id) async {
      final artifacts = await _metadataStore.listArtifacts(
        tenantId: _defaultTenantId,
        documentId: id,
      );
      return _jsonResponse(<String, dynamic>{
        'artifacts': artifacts.map((a) => a.toJson()).toList(),
      });
    });

    router.put('/v1/documents/<id>/artifacts/<format>',
        (Request request, String id, String format) async {
      final formatEnum = ArtifactFormat.fromString(format);
      if (formatEnum == ArtifactFormat.unknown) {
        return _badRequest('unsupported format');
      }

      final bytes = await _readAllBytes(request.read());
      final checksum = sha256.convert(bytes).toString();
      final existing = await _metadataStore.getArtifact(
        tenantId: _defaultTenantId,
        documentId: id,
        format: formatEnum,
      );
      final version = (existing?.version ?? 0) + 1;

      final storageKey = await _blobStore.put(
        tenantId: _defaultTenantId,
        documentId: id,
        format: formatEnum.name,
        bytes: bytes,
      );

      final artifact = SyncArtifact(
        documentId: id,
        tenantId: _defaultTenantId,
        format: formatEnum,
        mimeType:
            request.headers['content-type'] ?? _defaultMimeType(formatEnum),
        size: bytes.length,
        checksum: checksum,
        version: version,
        storageKey: storageKey,
        updatedAt: DateTime.now().toUtc(),
      );

      await _metadataStore.upsertArtifact(artifact);
      final eventId = await _metadataStore.appendEvent(
        tenantId: _defaultTenantId,
        entityType: 'artifact',
        entityId: '$id:${formatEnum.name}',
        eventType: 'upsert',
        eventVersion: version,
      );

      return _jsonResponse(<String, dynamic>{
        'artifact': artifact.toJson(),
        'eventId': eventId,
      });
    });

    router.get('/v1/documents/<id>/artifacts/<format>',
        (Request request, String id, String format) async {
      final formatEnum = ArtifactFormat.fromString(format);
      final artifact = await _metadataStore.getArtifact(
        tenantId: _defaultTenantId,
        documentId: id,
        format: formatEnum,
      );

      if (artifact == null) {
        return _notFound('artifact not found');
      }

      final bytes = await _blobStore.get(artifact.storageKey);
      if (bytes == null) {
        return _notFound('artifact data missing');
      }

      return Response.ok(
        bytes,
        headers: <String, String>{
          'content-type': artifact.mimeType,
          'x-artifact-checksum': artifact.checksum,
          'x-artifact-version': artifact.version.toString(),
        },
      );
    });

    router.get('/v1/sync/changes', (Request request) async {
      final since =
          int.tryParse(request.url.queryParameters['since'] ?? '0') ?? 0;
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final events = await _metadataStore.getChanges(
        tenantId: _defaultTenantId,
        since: since,
        limit: limit,
      );
      final nextCursor = events.isEmpty ? since : events.last.id;

      return _jsonResponse(<String, dynamic>{
        'events': events.map((e) => e.toJson()).toList(),
        'nextCursor': nextCursor,
      });
    });

    return router;
  }

  Future<Uint8List> _readAllBytes(Stream<List<int>> stream) async {
    final data = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      data.add(chunk);
    }
    return data.toBytes();
  }

  Response _jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  Response _notFound(String message) {
    return Response.notFound(
      jsonEncode(<String, dynamic>{'error': message}),
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  Response _badRequest(String message) {
    return Response(
      HttpStatus.badRequest,
      body: jsonEncode(<String, dynamic>{'error': message}),
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  String _defaultMimeType(ArtifactFormat format) {
    switch (format) {
      case ArtifactFormat.musicxml:
        return 'application/xml';
      case ArtifactFormat.pdf:
        return 'application/pdf';
      case ArtifactFormat.image:
        return 'image/*';
      case ArtifactFormat.midi:
        return 'audio/midi';
      case ArtifactFormat.unknown:
        return 'application/octet-stream';
    }
  }
}
