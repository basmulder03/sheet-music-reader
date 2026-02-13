import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/sheet_music_document.dart';
import '../../core/models/musicxml_model.dart';
import '../../core/services/musicxml_service.dart';
import '../../core/services/midi_playback_service.dart';
import '../widgets/musicxml_renderer.dart';
import '../widgets/playback_controls.dart';
import 'document_editor_screen.dart';
import 'dart:io';

/// Screen for viewing and editing sheet music documents
class DocumentViewerScreen extends StatefulWidget {
  final SheetMusicDocument document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  MusicXmlScore? _score;
  bool _isLoading = true;
  String? _error;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _loadMusicXml();
  }

  Future<void> _loadMusicXml() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final file = File(widget.document.musicXmlPath);
      if (!await file.exists()) {
        throw Exception('MusicXML file not found: ${widget.document.musicXmlPath}');
      }

      final xmlContent = await file.readAsString();
      
      if (!mounted) return;
      
      final musicXmlService = context.read<MusicXmlService>();
      final score = musicXmlService.parseString(xmlContent);

      setState(() {
        _score = score;
        _isLoading = false;
      });
      
      // Load score into playback service
      if (score != null && mounted) {
        context.read<MidiPlaybackService>().loadScore(score);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.document.title),
            if (widget.document.composer != null)
              Text(
                widget.document.composer!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _zoom = (_zoom - 0.1).clamp(0.5, 2.0);
              });
            },
            tooltip: 'Zoom Out',
          ),
          Text(
            '${(_zoom * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _zoom = (_zoom + 0.1).clamp(0.5, 2.0);
              });
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _score != null ? _editScore : null,
            tooltip: 'Edit',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _score != null ? const PlaybackControls() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              'Error loading sheet music',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMusicXml,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_score == null) {
      return const Center(
        child: Text('No music to display'),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: MusicXmlRenderer(
        score: _score!,
        zoom: _zoom,
      ),
    );
  }

  void _editScore() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentEditorScreen(
          document: widget.document,
        ),
      ),
    );
  }
}