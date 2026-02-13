import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/musicxml_model.dart';

/// Cache entry for parsed MusicXML scores
class _CacheEntry {
  final MusicXmlScore score;
  final DateTime timestamp;
  final int sizeInBytes;

  _CacheEntry(this.score, this.timestamp, this.sizeInBytes);
}

/// Service for parsing and working with MusicXML files with caching
class MusicXmlService extends ChangeNotifier {
  // Cache for parsed scores
  final Map<String, _CacheEntry> _scoreCache = {};
  
  // Maximum cache size in bytes (default: 50MB)
  final int maxCacheSize;
  
  // Maximum cache entries
  final int maxCacheEntries;
  
  // Current cache size in bytes
  int _currentCacheSize = 0;

  MusicXmlService({
    this.maxCacheSize = 50 * 1024 * 1024, // 50MB
    this.maxCacheEntries = 20,
  });

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'entries': _scoreCache.length,
      'sizeInBytes': _currentCacheSize,
      'sizeInMB': (_currentCacheSize / (1024 * 1024)).toStringAsFixed(2),
      'maxEntries': maxCacheEntries,
      'maxSizeMB': (maxCacheSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// Clear the entire cache
  void clearCache() {
    _scoreCache.clear();
    _currentCacheSize = 0;
    notifyListeners();
    
    if (kDebugMode) {
      print('MusicXML cache cleared');
    }
  }

  /// Remove a specific entry from cache
  void removeCacheEntry(String key) {
    final entry = _scoreCache.remove(key);
    if (entry != null) {
      _currentCacheSize -= entry.sizeInBytes;
      notifyListeners();
    }
  }

  /// Evict old entries if cache is full
  void _evictIfNeeded(int newEntrySize) {
    // Check entry count limit
    if (_scoreCache.length >= maxCacheEntries) {
      _evictOldest();
    }

    // Check size limit
    while (_currentCacheSize + newEntrySize > maxCacheSize && _scoreCache.isNotEmpty) {
      _evictOldest();
    }
  }

  /// Evict the oldest cache entry
  void _evictOldest() {
    if (_scoreCache.isEmpty) return;

    // Find oldest entry
    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _scoreCache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      final entry = _scoreCache.remove(oldestKey);
      if (entry != null) {
        _currentCacheSize -= entry.sizeInBytes;
        
        if (kDebugMode) {
          print('Evicted cache entry: $oldestKey (${entry.sizeInBytes} bytes)');
        }
      }
    }
  }

  /// Estimate the size of a MusicXML score in memory
  int _estimateScoreSize(MusicXmlScore score) {
    // Rough estimation based on content
    int size = 1000; // Base overhead

    // Header
    size += (score.header.title?.length ?? 0) * 2;
    size += (score.header.composer?.length ?? 0) * 2;
    size += (score.header.lyricist?.length ?? 0) * 2;

    // Parts
    size += score.parts.length * 100;
    for (final part in score.parts) {
      size += part.measures.length * 50;
      for (final measure in part.measures) {
        size += measure.elements.length * 100;
      }
    }

    return size;
  }

  /// Parse a MusicXML file with caching
  Future<MusicXmlScore?> parseFile(String filePath) async {
    // Check cache first
    if (_scoreCache.containsKey(filePath)) {
      if (kDebugMode) {
        print('Using cached MusicXML: $filePath');
      }
      return _scoreCache[filePath]!.score;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final xmlString = await file.readAsString();
      return await parseMusicXml(xmlString, cacheKey: filePath);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing MusicXML file: $e');
      }
      return null;
    }
  }

  /// Parse MusicXML from a string with optional caching
  Future<MusicXmlScore?> parseMusicXml(String xmlString, {String? cacheKey}) async {
    // Check cache if key provided
    if (cacheKey != null && _scoreCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('Using cached MusicXML: $cacheKey');
      }
      return _scoreCache[cacheKey]!.score;
    }

    try {
      // Parse in isolate for heavy documents (> 100KB)
      MusicXmlScore? score;
      
      if (xmlString.length > 100 * 1024) {
        if (kDebugMode) {
          print('Parsing large MusicXML in isolate (${xmlString.length} bytes)');
        }
        score = await compute(_parseInIsolate, xmlString);
      } else {
        score = MusicXmlScore.parse(xmlString);
      }

      // Cache the result if key provided
      if (score != null && cacheKey != null) {
        final size = _estimateScoreSize(score);
        _evictIfNeeded(size);
        
        _scoreCache[cacheKey] = _CacheEntry(
          score,
          DateTime.now(),
          size,
        );
        _currentCacheSize += size;
        
        if (kDebugMode) {
          print('Cached MusicXML: $cacheKey ($size bytes)');
          print('Cache stats: ${_scoreCache.length} entries, ${(_currentCacheSize / 1024).toStringAsFixed(1)} KB');
        }
        
        notifyListeners();
      }

      return score;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing MusicXML: $e');
      }
      return null;
    }
  }

  /// Parse MusicXML from a string (legacy method - forwards to parseMusicXml)
  MusicXmlScore? parseString(String xmlString) {
    return MusicXmlScore.parse(xmlString);
  }

  /// Parse MusicXML in isolate (for heavy documents)
  static MusicXmlScore? _parseInIsolate(String xmlString) {
    return MusicXmlScore.parse(xmlString);
  }

  /// Validate a MusicXML file
  Future<bool> validateFile(String filePath) async {
    try {
      final score = await parseFile(filePath);
      return score != null && score.parts.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Extract metadata from a MusicXML score
  Map<String, dynamic> extractMetadata(MusicXmlScore score) {
    final metadata = <String, dynamic>{};

    // Basic information
    metadata['title'] = score.header.title;
    metadata['composer'] = score.header.composer;
    metadata['lyricist'] = score.header.lyricist;

    // Count measures across all parts
    final measureCounts = score.parts.map((p) => p.measures.length).toList();
    metadata['measureCount'] = measureCounts.isNotEmpty
        ? measureCounts.reduce((a, b) => a > b ? a : b)
        : 0;

    // Get instruments
    metadata['instruments'] = score.partList.map((p) => p.name).toList();
    metadata['partCount'] = score.parts.length;

    // Get time and key signature from first measure
    if (score.parts.isNotEmpty && score.parts.first.measures.isNotEmpty) {
      final firstMeasure = score.parts.first.measures.first;
      if (firstMeasure.attributes != null) {
        final attrs = firstMeasure.attributes!;
        
        if (attrs.timeSignature != null) {
          metadata['timeSignature'] = attrs.timeSignature.toString();
        }
        
        if (attrs.keySignature != null) {
          metadata['keySignature'] = attrs.keySignature.toString();
        }
      }
    }

    return metadata;
  }

  /// Count the total number of notes in a score
  int countNotes(MusicXmlScore score) {
    var count = 0;
    for (final part in score.parts) {
      for (final measure in part.measures) {
        count += measure.elements.whereType<Note>().where((n) => !n.isRest).length;
      }
    }
    return count;
  }

  /// Get the duration of the score in quarter notes
  int getScoreDuration(MusicXmlScore score) {
    if (score.parts.isEmpty) return 0;

    var maxDuration = 0;
    for (final part in score.parts) {
      var partDuration = 0;
      for (final measure in part.measures) {
        for (final element in measure.elements) {
          if (element is Note && !element.isChord) {
            partDuration += element.duration;
          }
        }
      }
      if (partDuration > maxDuration) {
        maxDuration = partDuration;
      }
    }

    return maxDuration;
  }

  /// Convert MusicXML duration to seconds (approximate)
  double durationToSeconds(int duration, int divisions, int tempo) {
    // duration is in divisions
    // divisions = number of divisions per quarter note
    // tempo = beats per minute (quarter notes per minute)
    final quarterNotes = duration / divisions;
    final minutes = quarterNotes / tempo;
    return minutes * 60;
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
