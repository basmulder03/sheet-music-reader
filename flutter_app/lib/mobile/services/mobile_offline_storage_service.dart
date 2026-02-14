import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MobileOfflineStorageService extends ChangeNotifier {
  Directory? _offlineDirectory;

  Future<void> initialize() async {
    if (_offlineDirectory != null) {
      return;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(docsDir.path, 'offline_documents'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _offlineDirectory = dir;
  }

  Future<File> saveMusicXml({
    required String documentId,
    required String musicXml,
  }) async {
    await initialize();
    final file =
        File(path.join(_offlineDirectory!.path, '$documentId.musicxml'));
    await file.writeAsString(musicXml, flush: true);
    notifyListeners();
    return file;
  }

  Future<String?> readMusicXml(String documentId) async {
    await initialize();
    final file =
        File(path.join(_offlineDirectory!.path, '$documentId.musicxml'));
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  Future<bool> hasOfflineMusicXml(String documentId) async {
    await initialize();
    final file =
        File(path.join(_offlineDirectory!.path, '$documentId.musicxml'));
    return file.exists();
  }

  Future<void> removeOfflineMusicXml(String documentId) async {
    await initialize();
    final file =
        File(path.join(_offlineDirectory!.path, '$documentId.musicxml'));
    if (await file.exists()) {
      await file.delete();
      notifyListeners();
    }
  }

  Future<File> saveSourceFile({
    required String documentId,
    required Uint8List bytes,
    String? fileName,
    String? contentType,
  }) async {
    await initialize();
    await _removeExistingSourceFiles(documentId);

    final extension =
        _determineExtension(fileName: fileName, contentType: contentType);
    final file = File(
        path.join(_offlineDirectory!.path, '$documentId.source.$extension'));
    await file.writeAsBytes(bytes, flush: true);
    notifyListeners();
    return file;
  }

  Future<File?> getOfflinePdfFile(String documentId) async {
    await initialize();
    final file =
        File(path.join(_offlineDirectory!.path, '$documentId.source.pdf'));
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<File?> getOfflineSourceFile(String documentId) async {
    await initialize();
    final directory = _offlineDirectory!;
    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }
      final name = path.basename(entity.path);
      if (name.startsWith('$documentId.source.')) {
        return entity;
      }
    }
    return null;
  }

  Future<void> removeOfflineSource(String documentId) async {
    await initialize();
    await _removeExistingSourceFiles(documentId);
    notifyListeners();
  }

  Future<void> _removeExistingSourceFiles(String documentId) async {
    final directory = _offlineDirectory!;
    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }
      final name = path.basename(entity.path);
      if (name.startsWith('$documentId.source.')) {
        await entity.delete();
      }
    }
  }

  String _determineExtension({String? fileName, String? contentType}) {
    if (fileName != null && fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }

    final type = contentType?.toLowerCase() ?? '';
    if (type.contains('pdf')) {
      return 'pdf';
    }
    if (type.contains('png')) {
      return 'png';
    }
    if (type.contains('jpeg') || type.contains('jpg')) {
      return 'jpg';
    }
    if (type.contains('webp')) {
      return 'webp';
    }

    return 'bin';
  }
}
