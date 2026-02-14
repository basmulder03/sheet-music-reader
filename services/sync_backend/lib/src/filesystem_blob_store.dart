import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'blob_store.dart';

class FileSystemBlobStore implements BlobStore {
  FileSystemBlobStore({required String baseDirectoryPath})
      : _baseDirectory = Directory(baseDirectoryPath);

  final Directory _baseDirectory;

  Future<void> ensureInitialized() async {
    if (!await _baseDirectory.exists()) {
      await _baseDirectory.create(recursive: true);
    }
  }

  @override
  Future<String> put({
    required String tenantId,
    required String documentId,
    required String format,
    required Uint8List bytes,
  }) async {
    await ensureInitialized();

    final relativePath = p.join(
      'tenants',
      tenantId,
      'documents',
      documentId,
      '$format.bin',
    );

    final fullPath = p.join(_baseDirectory.path, relativePath);
    final file = File(fullPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    return relativePath;
  }

  @override
  Future<Uint8List?> get(String storageKey) async {
    final fullPath = p.join(_baseDirectory.path, storageKey);
    final file = File(fullPath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }
}
