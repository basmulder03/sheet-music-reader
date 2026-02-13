import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for caching images (thumbnails and sheet music)
class ImageCacheService {
  static ImageCacheService? _instance;
  static ImageCacheService get instance {
    _instance ??= ImageCacheService._();
    return _instance!;
  }

  ImageCacheService._();

  Directory? _cacheDir;
  final Map<String, Uint8List> _memoryCache = {};
  int _memoryCacheSize = 0;
  
  // Cache configuration
  static const int maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB in memory
  static const int maxDiskCacheSize = 200 * 1024 * 1024; // 200MB on disk
  static const Duration cacheExpiry = Duration(days: 30);

  /// Initialize cache directories
  Future<void> initialize() async {
    if (_cacheDir != null) return;

    try {
      final appDir = await getApplicationCacheDirectory();
      _cacheDir = Directory(path.join(appDir.path, 'image_cache'));
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Clean up expired cache on initialization
      await _cleanExpiredCache();
      
      if (kDebugMode) {
        print('[ImageCache] Initialized at ${_cacheDir!.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ImageCache] Error initializing: $e');
      }
      rethrow;
    }
  }

  /// Generate cache key from source path or URL
  String _generateCacheKey(String source, {String? variant}) {
    final key = variant != null ? '$source-$variant' : source;
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get cached image data (checks memory first, then disk)
  Future<Uint8List?> get(String source, {String? variant}) async {
    final cacheKey = _generateCacheKey(source, variant: variant);

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('[ImageCache] Memory hit: $source');
      }
      return _memoryCache[cacheKey];
    }

    // Check disk cache
    await initialize();
    final cacheFile = File(path.join(_cacheDir!.path, cacheKey));
    
    if (await cacheFile.exists()) {
      try {
        // Check if expired
        final stat = await cacheFile.stat();
        final age = DateTime.now().difference(stat.modified);
        
        if (age > cacheExpiry) {
          if (kDebugMode) {
            print('[ImageCache] Expired: $source');
          }
          await cacheFile.delete();
          return null;
        }

        final data = await cacheFile.readAsBytes();
        
        // Add to memory cache if space available
        _addToMemoryCache(cacheKey, data);
        
        if (kDebugMode) {
          print('[ImageCache] Disk hit: $source');
        }
        
        return data;
      } catch (e) {
        if (kDebugMode) {
          print('[ImageCache] Error reading cache: $e');
        }
        return null;
      }
    }

    if (kDebugMode) {
      print('[ImageCache] Miss: $source');
    }
    return null;
  }

  /// Put image data into cache (memory and disk)
  Future<void> put(String source, Uint8List data, {String? variant}) async {
    final cacheKey = _generateCacheKey(source, variant: variant);

    try {
      // Add to memory cache
      _addToMemoryCache(cacheKey, data);

      // Write to disk cache
      await initialize();
      final cacheFile = File(path.join(_cacheDir!.path, cacheKey));
      await cacheFile.writeAsBytes(data);

      if (kDebugMode) {
        print('[ImageCache] Cached: $source (${_formatBytes(data.length)})');
      }

      // Check if disk cache size exceeds limit
      await _enforceMaxDiskSize();
    } catch (e) {
      if (kDebugMode) {
        print('[ImageCache] Error writing cache: $e');
      }
    }
  }

  /// Add data to memory cache with LRU eviction
  void _addToMemoryCache(String key, Uint8List data) {
    // Remove if already exists (to update access time)
    if (_memoryCache.containsKey(key)) {
      _memoryCacheSize -= _memoryCache[key]!.length;
      _memoryCache.remove(key);
    }

    // Evict if necessary
    while (_memoryCacheSize + data.length > maxMemoryCacheSize && _memoryCache.isNotEmpty) {
      final oldestKey = _memoryCache.keys.first;
      final oldestData = _memoryCache.remove(oldestKey)!;
      _memoryCacheSize -= oldestData.length;
      
      if (kDebugMode) {
        print('[ImageCache] Memory evicted: $oldestKey');
      }
    }

    // Add to cache
    _memoryCache[key] = data;
    _memoryCacheSize += data.length;
  }

  /// Remove from cache
  Future<void> remove(String source, {String? variant}) async {
    final cacheKey = _generateCacheKey(source, variant: variant);

    // Remove from memory
    if (_memoryCache.containsKey(cacheKey)) {
      _memoryCacheSize -= _memoryCache[cacheKey]!.length;
      _memoryCache.remove(cacheKey);
    }

    // Remove from disk
    await initialize();
    final cacheFile = File(path.join(_cacheDir!.path, cacheKey));
    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }

    if (kDebugMode) {
      print('[ImageCache] Removed: $source');
    }
  }

  /// Clear all cached images
  Future<void> clearAll() async {
    // Clear memory cache
    _memoryCache.clear();
    _memoryCacheSize = 0;

    // Clear disk cache
    await initialize();
    if (await _cacheDir!.exists()) {
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }

    if (kDebugMode) {
      print('[ImageCache] Cleared all cache');
    }
  }

  /// Clean up expired cache files
  Future<void> _cleanExpiredCache() async {
    if (_cacheDir == null) return;

    try {
      final now = DateTime.now();
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          if (age > cacheExpiry) {
            await entity.delete();
            if (kDebugMode) {
              print('[ImageCache] Expired file deleted: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ImageCache] Error cleaning expired cache: $e');
      }
    }
  }

  /// Enforce maximum disk cache size
  Future<void> _enforceMaxDiskSize() async {
    if (_cacheDir == null) return;

    try {
      // Get all cache files with their sizes and modification times
      final files = <MapEntry<File, FileStat>>[];
      int totalSize = 0;

      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          files.add(MapEntry(entity, stat));
          totalSize += stat.size;
        }
      }

      // If under limit, no action needed
      if (totalSize <= maxDiskCacheSize) return;

      // Sort by modification time (oldest first)
      files.sort((a, b) => a.value.modified.compareTo(b.value.modified));

      // Delete oldest files until under limit
      for (final entry in files) {
        if (totalSize <= maxDiskCacheSize) break;

        await entry.key.delete();
        totalSize -= entry.value.size;

        if (kDebugMode) {
          print('[ImageCache] Evicted old file: ${entry.key.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ImageCache] Error enforcing disk size: $e');
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStatistics() async {
    await initialize();

    int fileCount = 0;
    int diskSize = 0;

    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        fileCount++;
        final stat = await entity.stat();
        diskSize += stat.size;
      }
    }

    return {
      'memoryEntries': _memoryCache.length,
      'memorySizeBytes': _memoryCacheSize,
      'memorySizeFormatted': _formatBytes(_memoryCacheSize),
      'diskEntries': fileCount,
      'diskSizeBytes': diskSize,
      'diskSizeFormatted': _formatBytes(diskSize),
      'cachePath': _cacheDir?.path,
    };
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clear memory cache only (keep disk cache)
  void clearMemoryCache() {
    _memoryCache.clear();
    _memoryCacheSize = 0;
    
    if (kDebugMode) {
      print('[ImageCache] Memory cache cleared');
    }
  }

  /// Preload images into cache
  Future<void> preload(List<String> sources) async {
    for (final source in sources) {
      // Check if already cached
      final cached = await get(source);
      if (cached != null) continue;

      // Load and cache
      try {
        final file = File(source);
        if (await file.exists()) {
          final data = await file.readAsBytes();
          await put(source, data);
        }
      } catch (e) {
        if (kDebugMode) {
          print('[ImageCache] Error preloading $source: $e');
        }
      }
    }
  }
}
