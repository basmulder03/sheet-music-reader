import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'image_cache_service.dart';

/// Service for generating and caching thumbnails
class ThumbnailService {
  static ThumbnailService? _instance;
  static ThumbnailService get instance {
    _instance ??= ThumbnailService._();
    return _instance!;
  }

  ThumbnailService._();

  final ImageCacheService _cacheService = ImageCacheService.instance;

  // Thumbnail sizes
  static const int smallThumbnailSize = 128;
  static const int mediumThumbnailSize = 256;
  static const int largeThumbnailSize = 512;

  /// Get or generate thumbnail for an image file
  Future<Uint8List?> getThumbnail(
    String imagePath, {
    int size = mediumThumbnailSize,
    bool forceRegenerate = false,
  }) async {
    if (!File(imagePath).existsSync()) {
      if (kDebugMode) {
        print('[Thumbnail] File not found: $imagePath');
      }
      return null;
    }

    final variant = 'thumb_$size';

    // Check cache first
    if (!forceRegenerate) {
      final cached = await _cacheService.get(imagePath, variant: variant);
      if (cached != null) {
        return cached;
      }
    }

    // Generate thumbnail
    try {
      final thumbnail = await _generateThumbnail(imagePath, size);
      if (thumbnail != null) {
        // Cache for future use
        await _cacheService.put(imagePath, thumbnail, variant: variant);
      }
      return thumbnail;
    } catch (e) {
      if (kDebugMode) {
        print('[Thumbnail] Error generating thumbnail: $e');
      }
      return null;
    }
  }

  /// Generate thumbnail in isolate to avoid blocking UI
  Future<Uint8List?> _generateThumbnail(String imagePath, int maxSize) async {
    try {
      return await compute(_generateThumbnailIsolate, {
        'path': imagePath,
        'size': maxSize,
      });
    } catch (e) {
      if (kDebugMode) {
        print('[Thumbnail] Error in isolate: $e');
      }
      return null;
    }
  }

  /// Generate thumbnail for MusicXML document (first page preview)
  Future<Uint8List?> getMusicXmlThumbnail(
    String musicXmlPath, {
    int size = mediumThumbnailSize,
  }) async {
    // For now, return a placeholder or first page render
    // In a full implementation, this would render the first page of music
    // using the MusicXML renderer and generate a thumbnail
    
    // TODO: Implement actual MusicXML to image rendering
    // For now, we'll just check if we have any cached thumbnail
    
    final variant = 'musicxml_thumb_$size';
    final cached = await _cacheService.get(musicXmlPath, variant: variant);
    return cached;
  }

  /// Preload thumbnails for multiple images
  Future<void> preloadThumbnails(
    List<String> imagePaths, {
    int size = mediumThumbnailSize,
  }) async {
    for (final imagePath in imagePaths) {
      await getThumbnail(imagePath, size: size);
    }
  }

  /// Clear all thumbnails from cache
  Future<void> clearThumbnailCache() async {
    await _cacheService.clearAll();
    if (kDebugMode) {
      print('[Thumbnail] All thumbnails cleared');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getStatistics();
  }
}

/// Isolate function to generate thumbnail
Uint8List? _generateThumbnailIsolate(Map<String, dynamic> params) {
  try {
    final imagePath = params['path'] as String;
    final maxSize = params['size'] as int;

    // Read image file
    final file = File(imagePath);
    final imageBytes = file.readAsBytesSync();

    // Decode image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      return null;
    }

    // Calculate thumbnail size maintaining aspect ratio
    int thumbWidth, thumbHeight;
    if (image.width > image.height) {
      thumbWidth = maxSize;
      thumbHeight = (maxSize * image.height / image.width).round();
    } else {
      thumbHeight = maxSize;
      thumbWidth = (maxSize * image.width / image.height).round();
    }

    // Resize image with high quality
    final thumbnail = img.copyResize(
      image,
      width: thumbWidth,
      height: thumbHeight,
      interpolation: img.Interpolation.linear,
    );

    // Encode as JPEG with good quality
    final encoded = img.encodeJpg(thumbnail, quality: 85);

    return Uint8List.fromList(encoded);
  } catch (e) {
    print('[Thumbnail] Error in isolate: $e');
    return null;
  }
}
