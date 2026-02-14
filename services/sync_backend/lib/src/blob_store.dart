import 'dart:typed_data';

abstract interface class BlobStore {
  Future<String> put({
    required String tenantId,
    required String documentId,
    required String format,
    required Uint8List bytes,
  });

  Future<Uint8List?> get(String storageKey);
}
