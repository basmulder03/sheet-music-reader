import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/sheet_music_document.dart';

/// Widget for adding annotations on mobile
class MobileAnnotationWidget extends StatefulWidget {
  final SheetMusicDocument document;
  final Function(Annotation) onAnnotationAdded;

  const MobileAnnotationWidget({
    super.key,
    required this.document,
    required this.onAnnotationAdded,
  });

  @override
  State<MobileAnnotationWidget> createState() => _MobileAnnotationWidgetState();
}

class _MobileAnnotationWidgetState extends State<MobileAnnotationWidget> {
  final _textController = TextEditingController();
  AnnotationType _selectedType = AnnotationType.note;
  Color _selectedColor = Colors.amber;
  int _selectedPage = 1;
  Offset _position = const Offset(100, 100);

  final _uuid = const Uuid();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            'Add Annotation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          // Annotation type
          DropdownButtonFormField<AnnotationType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: AnnotationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getTypeLabel(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          // Text input
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Note Text',
              hintText: 'Enter your annotation...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          // Page number
          TextField(
            decoration: const InputDecoration(
              labelText: 'Page',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.insert_drive_file),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final page = int.tryParse(value);
              if (page != null) {
                _selectedPage = page;
              }
            },
            controller: TextEditingController(text: _selectedPage.toString()),
          ),
          const SizedBox(height: 16),
          // Color selector
          Row(
            children: [
              const Icon(Icons.color_lens),
              const SizedBox(width: 12),
              const Text('Color:'),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _colorOption(Colors.amber),
                    _colorOption(Colors.red),
                    _colorOption(Colors.blue),
                    _colorOption(Colors.green),
                    _colorOption(Colors.purple),
                    _colorOption(Colors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addAnnotation,
                  icon: const Icon(Icons.check),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
          // Bottom padding for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _colorOption(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  void _addAnnotation() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter annotation text')),
      );
      return;
    }

    final annotation = Annotation(
      id: _uuid.v4(),
      documentId: widget.document.id,
      page: _selectedPage,
      type: _selectedType,
      text: text,
      color: _selectedColor,
      position: _position,
      createdAt: DateTime.now(),
    );

    widget.onAnnotationAdded(annotation);
    Navigator.of(context).pop();
  }

  String _getTypeLabel(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return 'Note';
      case AnnotationType.highlight:
        return 'Highlight';
      case AnnotationType.drawing:
        return 'Drawing';
      case AnnotationType.fingering:
        return 'Fingering';
      case AnnotationType.dynamics:
        return 'Dynamics';
    }
  }
}
