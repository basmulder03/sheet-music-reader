import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/services/thumbnail_service.dart';

/// Widget that displays an image with automatic caching
class CachedImage extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useThumbnail;
  final int thumbnailSize;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useThumbnail = false,
    this.thumbnailSize = ThumbnailService.mediumThumbnailSize,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.useThumbnail != widget.useThumbnail ||
        oldWidget.thumbnailSize != widget.thumbnailSize) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Uint8List? data;

      if (widget.useThumbnail) {
        // Load thumbnail
        data = await ThumbnailService.instance.getThumbnail(
          widget.imagePath,
          size: widget.thumbnailSize,
        );
      } else {
        // Load full image from cache or disk
        final cacheService = ImageCacheService.instance;
        data = await cacheService.get(widget.imagePath);

        if (data == null) {
          // Not in cache, load from file and cache it
          final file = await _loadFromFile();
          if (file != null) {
            await cacheService.put(widget.imagePath, file);
            data = file;
          }
        }
      }

      if (mounted) {
        setState(() {
          _imageData = data;
          _isLoading = false;
          _hasError = data == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<Uint8List?> _loadFromFile() async {
    try {
      final file = await Future.value(widget.imagePath).then((path) {
        final f = File(path);
        return f.exists().then((exists) => exists ? f.readAsBytes() : null);
      });
      return file;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    if (_hasError || _imageData == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          );
    }

    return Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
    );
  }
}

/// Widget for displaying document thumbnails with automatic generation
class DocumentThumbnail extends StatelessWidget {
  final String documentPath;
  final double size;
  final BoxFit fit;

  const DocumentThumbnail({
    super.key,
    required this.documentPath,
    this.size = 128,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imagePath: documentPath,
      width: size,
      height: size,
      fit: fit,
      useThumbnail: true,
      thumbnailSize: size.toInt(),
      placeholder: Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.music_note,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.music_note,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
