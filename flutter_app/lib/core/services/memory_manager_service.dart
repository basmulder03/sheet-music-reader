import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/musicxml_model.dart';

/// Service for managing memory usage for large MusicXML documents
class MemoryManagerService {
  static MemoryManagerService? _instance;
  static MemoryManagerService get instance {
    _instance ??= MemoryManagerService._();
    return _instance!;
  }

  MemoryManagerService._();

  // Memory cache for loaded documents
  final Map<String, MusicXmlScore> _loadedDocuments = {};
  final Map<String, DateTime> _accessTimes = {};
  final Map<String, int> _documentSizes = {};
  
  int _currentMemoryUsage = 0;
  
  // Memory limits
  static const int maxMemoryUsage = 100 * 1024 * 1024; // 100MB
  static const int warningThreshold = 75 * 1024 * 1024; // 75MB
  static const int maxCachedDocuments = 10;
  static const Duration inactiveTimeout = Duration(minutes: 5);

  // Getters
  int get currentMemoryUsage => _currentMemoryUsage;
  int get loadedDocumentCount => _loadedDocuments.length;
  double get memoryUsagePercent => _currentMemoryUsage / maxMemoryUsage;
  bool get isMemoryPressure => _currentMemoryUsage > warningThreshold;

  /// Load a document into memory
  Future<MusicXmlScore?> loadDocument(
    String documentId,
    Future<MusicXmlScore?> Function() loader,
  ) async {
    // Check if already loaded
    if (_loadedDocuments.containsKey(documentId)) {
      _accessTimes[documentId] = DateTime.now();
      if (kDebugMode) {
        print('[MemoryManager] Document already loaded: $documentId');
      }
      return _loadedDocuments[documentId];
    }

    // Load document
    final score = await loader();
    if (score == null) return null;

    // Estimate size
    final estimatedSize = _estimateScoreSize(score);

    // Check if we need to free memory
    if (_currentMemoryUsage + estimatedSize > maxMemoryUsage) {
      await _freeMemoryForSize(estimatedSize);
    }

    // Store in cache
    _loadedDocuments[documentId] = score;
    _accessTimes[documentId] = DateTime.now();
    _documentSizes[documentId] = estimatedSize;
    _currentMemoryUsage += estimatedSize;

    if (kDebugMode) {
      print('[MemoryManager] Loaded document: $documentId (${_formatBytes(estimatedSize)})');
      print('[MemoryManager] Memory usage: ${_formatBytes(_currentMemoryUsage)} / ${_formatBytes(maxMemoryUsage)}');
    }

    // Check if we need to enforce max document limit
    if (_loadedDocuments.length > maxCachedDocuments) {
      await _evictOldestDocument();
    }

    return score;
  }

  /// Get a loaded document (null if not in memory)
  MusicXmlScore? getDocument(String documentId) {
    if (_loadedDocuments.containsKey(documentId)) {
      _accessTimes[documentId] = DateTime.now();
      return _loadedDocuments[documentId];
    }
    return null;
  }

  /// Unload a specific document
  void unloadDocument(String documentId) {
    if (_loadedDocuments.containsKey(documentId)) {
      final size = _documentSizes[documentId] ?? 0;
      _currentMemoryUsage -= size;
      
      _loadedDocuments.remove(documentId);
      _accessTimes.remove(documentId);
      _documentSizes.remove(documentId);

      if (kDebugMode) {
        print('[MemoryManager] Unloaded document: $documentId');
        print('[MemoryManager] Memory usage: ${_formatBytes(_currentMemoryUsage)}');
      }
    }
  }

  /// Unload all documents
  void unloadAll() {
    _loadedDocuments.clear();
    _accessTimes.clear();
    _documentSizes.clear();
    _currentMemoryUsage = 0;

    if (kDebugMode) {
      print('[MemoryManager] All documents unloaded');
    }
  }

  /// Free memory to accommodate a new document
  Future<void> _freeMemoryForSize(int requiredSize) async {
    if (kDebugMode) {
      print('[MemoryManager] Freeing memory for ${_formatBytes(requiredSize)}');
    }

    // Calculate how much we need to free
    final targetUsage = maxMemoryUsage - requiredSize;
    
    while (_currentMemoryUsage > targetUsage && _loadedDocuments.isNotEmpty) {
      await _evictOldestDocument();
    }
  }

  /// Evict the oldest (least recently accessed) document
  Future<void> _evictOldestDocument() async {
    if (_loadedDocuments.isEmpty) return;

    // Find least recently accessed document
    String? oldestDocId;
    DateTime? oldestTime;

    for (final entry in _accessTimes.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestDocId = entry.key;
      }
    }

    if (oldestDocId != null) {
      if (kDebugMode) {
        print('[MemoryManager] Evicting oldest document: $oldestDocId');
      }
      unloadDocument(oldestDocId);
    }
  }

  /// Clean up inactive documents
  Future<void> cleanupInactive() async {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _accessTimes.entries) {
      final age = now.difference(entry.value);
      if (age > inactiveTimeout) {
        toRemove.add(entry.key);
      }
    }

    for (final documentId in toRemove) {
      if (kDebugMode) {
        print('[MemoryManager] Removing inactive document: $documentId');
      }
      unloadDocument(documentId);
    }

    if (toRemove.isNotEmpty && kDebugMode) {
      print('[MemoryManager] Cleaned up ${toRemove.length} inactive documents');
    }
  }

  /// Estimate size of a MusicXML score in bytes
  int _estimateScoreSize(MusicXmlScore score) {
    // Rough estimation based on structure
    int size = 0;

    // Base overhead
    size += 1000; // Object overhead

    // Parts
    size += score.parts.length * 500; // Per-part overhead

    for (final part in score.parts) {
      // Measures
      size += part.measures.length * 200; // Per-measure overhead

      for (final measure in part.measures) {
        // Music elements (notes, rests, etc.)
        size += measure.elements.length * 100; // Per-element overhead
        
        // Attributes
        if (measure.attributes != null) {
          size += 200;
        }
      }
    }

    return size;
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get memory statistics
  Map<String, dynamic> getStatistics() {
    return {
      'loadedDocuments': _loadedDocuments.length,
      'currentMemoryUsage': _currentMemoryUsage,
      'currentMemoryFormatted': _formatBytes(_currentMemoryUsage),
      'maxMemoryUsage': maxMemoryUsage,
      'maxMemoryFormatted': _formatBytes(maxMemoryUsage),
      'memoryUsagePercent': (memoryUsagePercent * 100).toStringAsFixed(1),
      'isMemoryPressure': isMemoryPressure,
      'documents': _loadedDocuments.keys.toList(),
    };
  }

  /// Start periodic cleanup timer
  Timer? _cleanupTimer;

  void startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      cleanupInactive();
    });

    if (kDebugMode) {
      print('[MemoryManager] Started periodic cleanup');
    }
  }

  void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    if (kDebugMode) {
      print('[MemoryManager] Stopped periodic cleanup');
    }
  }

  /// Get list of loaded documents with their access times
  List<Map<String, dynamic>> getLoadedDocumentsInfo() {
    return _loadedDocuments.keys.map((docId) {
      return {
        'documentId': docId,
        'size': _documentSizes[docId] ?? 0,
        'sizeFormatted': _formatBytes(_documentSizes[docId] ?? 0),
        'accessTime': _accessTimes[docId]?.toIso8601String(),
        'ageMinutes': _accessTimes[docId] != null
            ? DateTime.now().difference(_accessTimes[docId]!).inMinutes
            : null,
      };
    }).toList();
  }
}
