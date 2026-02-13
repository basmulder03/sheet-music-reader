import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io';
import '../../core/models/sheet_music_document.dart';
import '../../core/models/musicxml_model.dart';
import '../../core/services/note_editing_service.dart';
import '../../core/services/musicxml_service.dart';
import '../../core/services/library_service.dart';
import '../widgets/editing_toolbar.dart';
import '../widgets/interactive_music_renderer.dart';

/// Screen for editing sheet music documents
class DocumentEditorScreen extends StatefulWidget {
  final SheetMusicDocument document;

  const DocumentEditorScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  MusicXmlScore? _score;
  bool _isLoading = true;
  String? _error;
  double _zoom = 1.0;
  bool _isSaving = false;

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

      if (score == null) {
        throw Exception('Failed to parse MusicXML file');
      }

      setState(() {
        _score = score;
        _isLoading = false;
      });
      
      // Load score into editing service
      if (mounted) {
        context.read<NoteEditingService>().loadScore(score);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveScore() async {
    final editingService = context.read<NoteEditingService>();
    final score = editingService.score;
    
    if (score == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert score back to MusicXML
      final xmlString = _convertScoreToXml(score);
      
      // Save to file
      final file = File(widget.document.musicXmlPath);
      await file.writeAsString(xmlString);
      
      // Update library
      if (mounted) {
        await context.read<LibraryService>().updateDocument(
          widget.document.id,
          modifiedDate: DateTime.now(),
        );
        
        editingService.markAsSaved();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Score saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving score: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _convertScoreToXml(MusicXmlScore score) {
    final builder = xml.XmlBuilder();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('score-partwise', nest: () {
      builder.attribute('version', '3.1');
      
      // Header
      if (score.header.title != null) {
        builder.element('movement-title', nest: score.header.title);
      }
      
      builder.element('identification', nest: () {
        if (score.header.composer != null) {
          builder.element('creator', nest: () {
            builder.attribute('type', 'composer');
            builder.text(score.header.composer!);
          });
        }
        
        builder.element('encoding', nest: () {
          builder.element('software', nest: 'Sheet Music Reader');
          builder.element('encoding-date', nest: DateTime.now().toIso8601String().split('T')[0]);
        });
      });
      
      // Part list
      builder.element('part-list', nest: () {
        for (final partInfo in score.partList) {
          builder.element('score-part', nest: () {
            builder.attribute('id', partInfo.id);
            builder.element('part-name', nest: partInfo.name);
          });
        }
      });
      
      // Parts
      for (final part in score.parts) {
        builder.element('part', nest: () {
          builder.attribute('id', part.id);
          
          for (final measure in part.measures) {
            builder.element('measure', nest: () {
              builder.attribute('number', measure.number.toString());
              
              // Attributes
              if (measure.attributes != null) {
                builder.element('attributes', nest: () {
                  final attr = measure.attributes!;
                  
                  if (attr.divisions != null) {
                    builder.element('divisions', nest: attr.divisions.toString());
                  }
                  
                  if (attr.keySignature != null) {
                    builder.element('key', nest: () {
                      builder.element('fifths', nest: attr.keySignature!.fifths.toString());
                      builder.element('mode', nest: attr.keySignature!.mode);
                    });
                  }
                  
                  if (attr.timeSignature != null) {
                    builder.element('time', nest: () {
                      builder.element('beats', nest: attr.timeSignature!.beats.toString());
                      builder.element('beat-type', nest: attr.timeSignature!.beatType.toString());
                    });
                  }
                  
                  if (attr.clef != null) {
                    builder.element('clef', nest: () {
                      builder.element('sign', nest: attr.clef!.sign);
                      builder.element('line', nest: attr.clef!.line.toString());
                    });
                  }
                });
              }
              
              // Notes
              for (final element in measure.elements) {
                if (element is Note) {
                  builder.element('note', nest: () {
                    if (element.isRest) {
                      builder.element('rest');
                    } else if (element.pitch != null) {
                      builder.element('pitch', nest: () {
                        builder.element('step', nest: element.pitch!.step);
                        if (element.pitch!.alter != null) {
                          builder.element('alter', nest: element.pitch!.alter.toString());
                        }
                        builder.element('octave', nest: element.pitch!.octave.toString());
                      });
                    }
                    
                    builder.element('duration', nest: element.duration.toString());
                    builder.element('type', nest: element.type);
                    
                    if (element.voice != null) {
                      builder.element('voice', nest: element.voice.toString());
                    }
                  });
                }
              }
            });
          }
        });
      }
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteEditingService>(
      builder: (context, editingService, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit: ${widget.document.title}'),
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
              const SizedBox(width: 16),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: editingService.isModified ? _saveScore : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              const EditingToolbar(),
              Expanded(
                child: _buildBody(editingService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(NoteEditingService editingService) {
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

    final score = editingService.score;
    if (score == null) {
      return const Center(
        child: Text('No music to display'),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: InteractiveMusicRenderer(
        score: score,
        zoom: _zoom,
        isEditMode: true,
      ),
    );
  }
}
