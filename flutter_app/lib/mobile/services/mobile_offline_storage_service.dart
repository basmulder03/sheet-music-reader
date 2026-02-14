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
}
