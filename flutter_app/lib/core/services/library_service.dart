import 'package:flutter/foundation.dart';
import '../models/sheet_music_document.dart';
import 'database_service.dart';

/// Service for managing the sheet music library
class LibraryService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final List<SheetMusicDocument> _documents = [];
  final Map<String, List<Annotation>> _annotations = {};
  bool _isLoaded = false;

  List<SheetMusicDocument> get documents => List.unmodifiable(_documents);
  bool get isLoaded => _isLoaded;

  /// Get annotations for a specific document
  List<Annotation> getAnnotations(String documentId) {
    return _annotations[documentId] ?? [];
  }

  /// Add a new document to the library
  Future<void> addDocument(SheetMusicDocument document) async {
    _documents.add(document);
    _documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    notifyListeners();
    
    // Persist to database
    await _databaseService.saveDocument(document);
  }

  /// Update an existing document
  Future<void> updateDocument(SheetMusicDocument document) async {
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      _documents[index] = document.copyWith(modifiedAt: DateTime.now());
      _documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      notifyListeners();
      
      // Persist to database
      await _databaseService.updateDocument(_documents[index]);
    }
  }

  /// Remove a document from the library
  Future<void> removeDocument(String documentId) async {
    _documents.removeWhere((d) => d.id == documentId);
    _annotations.remove(documentId);
    notifyListeners();
    
    // Delete from database
    await _databaseService.deleteDocument(documentId);
  }

  /// Add an annotation to a document
  Future<void> addAnnotation(String documentId, Annotation annotation) async {
    if (!_annotations.containsKey(documentId)) {
      _annotations[documentId] = [];
    }
    _annotations[documentId]!.add(annotation);
    notifyListeners();
    
    // Persist to database
    await _databaseService.saveAnnotation(documentId, annotation);
  }

  /// Remove an annotation
  Future<void> removeAnnotation(String documentId, String annotationId) async {
    _annotations[documentId]?.removeWhere((a) => a.id == annotationId);
    notifyListeners();
    
    // Delete from database
    await _databaseService.deleteAnnotation(annotationId);
  }

  /// Search documents by query
  List<SheetMusicDocument> search(String query) {
    if (query.isEmpty) return documents;

    final lowerQuery = query.toLowerCase();
    return _documents.where((doc) {
      return doc.title.toLowerCase().contains(lowerQuery) ||
          (doc.composer?.toLowerCase().contains(lowerQuery) ?? false) ||
          (doc.arranger?.toLowerCase().contains(lowerQuery) ?? false) ||
          doc.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Filter documents by tag
  List<SheetMusicDocument> filterByTag(String tag) {
    return _documents.where((doc) => doc.tags.contains(tag)).toList();
  }

  /// Get all unique tags
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final doc in _documents) {
      tags.addAll(doc.tags);
    }
    return tags;
  }

  /// Load library from storage
  Future<void> loadLibrary() async {
    if (_isLoaded) return;
    
    try {
      // Load documents from database
      _documents.clear();
      final docs = await _databaseService.getAllDocuments();
      _documents.addAll(docs);
      
      // Load annotations for each document
      _annotations.clear();
      for (final doc in docs) {
        final annotations = await _databaseService.getAnnotations(doc.id);
        if (annotations.isNotEmpty) {
          _annotations[doc.id] = annotations;
        }
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[LibraryService] Error loading library: $e');
      }
      rethrow;
    }
  }

  /// Reload library from database
  Future<void> reloadLibrary() async {
    _isLoaded = false;
    await loadLibrary();
  }

  /// Get database statistics
  Future<Map<String, int>> getStatistics() async {
    return await _databaseService.getStatistics();
  }

  /// Close database connection
  @override
  Future<void> dispose() async {
    await _databaseService.close();
    super.dispose();
  }
}
