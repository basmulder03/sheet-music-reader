import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/sheet_music_document.dart';
import '../../core/models/musicxml_model.dart';
import '../../core/services/musicxml_service.dart';
import '../../desktop/widgets/musicxml_renderer.dart';
import '../services/mobile_connection_service.dart';
import '../widgets/mobile_annotation_widget.dart';

class MobileDocumentViewerScreen extends StatefulWidget {
  final SheetMusicDocument document;

  const MobileDocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<MobileDocumentViewerScreen> createState() =>
      _MobileDocumentViewerScreenState();
}

class _MobileDocumentViewerScreenState
    extends State<MobileDocumentViewerScreen> {
  MusicXmlScore? _score;
  bool _isLoading = true;
  String? _errorMessage;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connectionService = context.read<MobileConnectionService>();
      final musicXmlContent =
          await connectionService.getMusicXml(widget.document.id);

      if (musicXmlContent == null) {
        throw Exception('Failed to download MusicXML from server');
      }

      final musicXmlService = context.read<MusicXmlService>();
      final score = await musicXmlService.parseMusicXml(musicXmlContent);

      setState(() {
        _score = score;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _zoomLevel > 0.5
                ? () {
                    setState(() {
                      _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 2.0);
                    });
                  }
                : null,
            tooltip: 'Zoom out',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                '${(_zoomLevel * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _zoomLevel < 2.0
                ? () {
                    setState(() {
                      _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 2.0);
                    });
                  }
                : null,
            tooltip: 'Zoom in',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'annotate':
                  _showAnnotationDialog();
                  break;
                case 'refresh':
                  _loadScore();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'annotate',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 12),
                    Text('Annotate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading sheet music...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Score',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadScore,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_score == null) {
      return const Center(
        child: Text('No score data available'),
      );
    }

    // Show the music score
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.document.composer != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.document.composer!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                    if (widget.document.arranger != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Arr. ${widget.document.arranger}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Music score renderer
            Transform.scale(
              scale: _zoomLevel,
              alignment: Alignment.topLeft,
              child: MusicXmlRenderer(score: _score!),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnotationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MobileAnnotationWidget(
        document: widget.document,
        onAnnotationAdded: _addAnnotation,
      ),
    );
  }

  Future<void> _addAnnotation(Annotation annotation) async {
    final connectionService = context.read<MobileConnectionService>();

    if (!connectionService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to server'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await connectionService.addAnnotation(
      widget.document.id,
      annotation,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annotation added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add annotation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
