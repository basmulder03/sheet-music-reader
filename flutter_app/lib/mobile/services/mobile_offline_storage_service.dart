import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/models/sheet_music_document.dart';

class MobileOfflineStorageService extends ChangeNotifier {
  Directory? _offlineDirectory;
  static const String _indexFileName = 'offline_index.json';

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

  Future<void> upsertOfflineDocument(
    SheetMusicDocument document, {
    String? sourceType,
    String? sourceFileName,
  }) async {
    await initialize();

    final index = await _readIndex();
    final key = document.id;

    final musicXmlFile =
        File(path.join(_offlineDirectory!.path, '$key.musicxml'));
    final sourceFile = await getOfflineSourceFile(document.id);

    index[key] = <String, dynamic>{
      'document': document.toJson(),
      'musicXmlLocalPath': musicXmlFile.path,
      'sourceLocalPath': sourceFile?.path,
      'sourceType': sourceType,
      'sourceFileName': sourceFileName,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await _writeIndex(index);
    notifyListeners();
  }

  Future<List<SheetMusicDocument>> getOfflineDocuments() async {
    await initialize();
    final index = await _readIndex();
    final result = <SheetMusicDocument>[];

    for (final entry in index.entries) {
      final raw = entry.value;
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      final docJson = raw['document'];
      if (docJson is! Map<String, dynamic>) {
        continue;
      }

      final localMusicXmlPath = raw['musicXmlLocalPath'] as String?;
      if (localMusicXmlPath == null ||
          !await File(localMusicXmlPath).exists()) {
        continue;
      }

      try {
        final parsed = SheetMusicDocument.fromJson(docJson);
        result.add(
          parsed.copyWith(
            musicXmlPath: localMusicXmlPath,
            sourcePath: raw['sourceLocalPath'] as String?,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    result.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return result;
  }

  Future<Set<String>> getOfflineDocumentIds() async {
    final docs = await getOfflineDocuments();
    return docs.map((d) => d.id).toSet();
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

  Future<void> removeOfflineDocument(String documentId) async {
    await removeOfflineMusicXml(documentId);
    await removeOfflineSource(documentId);

    final index = await _readIndex();
    if (index.remove(documentId) != null) {
      await _writeIndex(index);
    }
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

  Future<Map<String, dynamic>> _readIndex() async {
    final file = File(path.join(_offlineDirectory!.path, _indexFileName));
    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    try {
      final content = await file.readAsString();
      final parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeIndex(Map<String, dynamic> index) async {
    final file = File(path.join(_offlineDirectory!.path, _indexFileName));
    await file.writeAsString(jsonEncode(index), flush: true);
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
