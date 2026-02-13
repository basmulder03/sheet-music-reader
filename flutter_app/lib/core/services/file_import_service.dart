import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/sheet_music_document.dart';
import 'audiveris_service.dart';
import 'library_service.dart';

/// Service for importing PDF and image files and converting them to MusicXML
class FileImportService extends ChangeNotifier {
  final AudiverisService _audiverisService;
  final LibraryService _libraryService;

  bool _isImporting = false;
  String? _importStatus;
  double _importProgress = 0.0;
  String? _currentFileName;

  FileImportService({
    required AudiverisService audiverisService,
    required LibraryService libraryService,
  })  : _audiverisService = audiverisService,
        _libraryService = libraryService;

  bool get isImporting => _isImporting;
  String? get importStatus => _importStatus;
  double get importProgress => _importProgress;
  String? get currentFileName => _currentFileName;

  /// Pick and import PDF or image files
  Future<List<SheetMusicDocument>> pickAndImportFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'tif', 'tiff'],
        allowMultiple: true,
        dialogTitle: 'Select PDF or image files to import',
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      return await importFiles(result.paths.whereType<String>().toList());
    } catch (e) {
      _updateStatus('Error picking files: $e');
      return [];
    }
  }

  /// Import a list of file paths
  Future<List<SheetMusicDocument>> importFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) return [];

    _isImporting = true;
    _importProgress = 0.0;
    notifyListeners();

    final documents = <SheetMusicDocument>[];

    try {
      for (var i = 0; i < filePaths.length; i++) {
        final filePath = filePaths[i];
        _currentFileName = path.basename(filePath);
        _updateStatus('Processing file ${i + 1} of ${filePaths.length}: $_currentFileName');

        try {
          final doc = await _importSingleFile(filePath);
          if (doc != null) {
            documents.add(doc);
            await _libraryService.addDocument(doc);
          }
        } catch (e) {
          _updateStatus('Error processing $_currentFileName: $e');
          // Continue with next file
        }

        _importProgress = (i + 1) / filePaths.length;
        notifyListeners();
      }

      _updateStatus('Import complete: ${documents.length} of ${filePaths.length} files processed successfully');
    } finally {
      _isImporting = false;
      _currentFileName = null;
      notifyListeners();
    }

    return documents;
  }

  /// Import a single file
  Future<SheetMusicDocument?> _importSingleFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final fileName = path.basenameWithoutExtension(filePath);

    // Copy file to app storage
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory(path.join(appDir.path, 'sheet_music_reader', 'imports'));
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storedFileName = '${timestamp}_${path.basename(filePath)}';
    final storedFilePath = path.join(storageDir.path, storedFileName);
    await file.copy(storedFilePath);

    _updateStatus('Copied file to storage: $storedFileName');

    // Convert to MusicXML using Audiveris
    _updateStatus('Converting to MusicXML...');
    final musicXmlContent = await _audiverisService.convertToMusicXml(storedFilePath);

    if (musicXmlContent == null || musicXmlContent.isEmpty) {
      throw Exception('Failed to convert file to MusicXML');
    }

    // Save MusicXML file
    final musicXmlDir = Directory(path.join(appDir.path, 'sheet_music_reader', 'musicxml'));
    if (!await musicXmlDir.exists()) {
      await musicXmlDir.create(recursive: true);
    }

    final musicXmlFileName = '${timestamp}_$fileName.musicxml';
    final musicXmlPath = path.join(musicXmlDir.path, musicXmlFileName);
    await File(musicXmlPath).writeAsString(musicXmlContent);

    _updateStatus('MusicXML saved: $musicXmlFileName');

    // Create document
    final now = DateTime.now();
    final document = SheetMusicDocument(
      id: 'doc_$timestamp',
      title: fileName,
      createdAt: now,
      modifiedAt: now,
      sourcePath: storedFilePath,
      musicXmlPath: musicXmlPath,
      metadata: DocumentMetadata(
        pageCount: 1,
      ),
    );

    _updateStatus('Document created: ${document.title}');

    return document;
  }

  /// Import from a directory (batch import)
  Future<List<SheetMusicDocument>> importFromDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist: $directoryPath');
    }

    final files = await directory
        .list()
        .where((entity) => entity is File)
        .map((entity) => entity as File)
        .where((file) {
      final ext = path.extension(file.path).toLowerCase();
      return ['.pdf', '.png', '.jpg', '.jpeg', '.tif', '.tiff'].contains(ext);
    }).toList();

    final filePaths = files.map((file) => file.path).toList();
    return await importFiles(filePaths);
  }

  void _updateStatus(String status) {
    _importStatus = status;
    notifyListeners();
    if (kDebugMode) {
      print('[FileImportService] $status');
    }
  }

  /// Clear import status
  void clearStatus() {
    _importStatus = null;
    notifyListeners();
  }
}
