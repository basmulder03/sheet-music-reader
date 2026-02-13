import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/note_editing_service.dart';

/// Toolbar for editing sheet music
class EditingToolbar extends StatelessWidget {
  const EditingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteEditingService>(
      builder: (context, editingService, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Tools section
              _buildToolSection(context, editingService),
              
              const VerticalDivider(),
              
              // Duration section
              _buildDurationSection(context, editingService),
              
              const VerticalDivider(),
              
              // Accidental section
              _buildAccidentalSection(context, editingService),
              
              const VerticalDivider(),
              
              // Undo/Redo section
              _buildUndoRedoSection(context, editingService),
              
              const Spacer(),
              
              // Save indicator
              _buildSaveIndicator(context, editingService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolSection(BuildContext context, NoteEditingService service) {
    return Row(
      children: [
        _buildToolButton(
          context: context,
          service: service,
          tool: EditingTool.select,
          icon: Icons.touch_app,
          tooltip: 'Select',
        ),
        _buildToolButton(
          context: context,
          service: service,
          tool: EditingTool.addNote,
          icon: Icons.music_note,
          tooltip: 'Add Note',
        ),
        _buildToolButton(
          context: context,
          service: service,
          tool: EditingTool.addRest,
          icon: Icons.pause,
          tooltip: 'Add Rest',
        ),
        _buildToolButton(
          context: context,
          service: service,
          tool: EditingTool.delete,
          icon: Icons.delete_outline,
          tooltip: 'Delete',
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required NoteEditingService service,
    required EditingTool tool,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = service.currentTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        isSelected: isSelected,
        onPressed: () => service.setTool(tool),
        style: IconButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : null,
        ),
      ),
    );
  }

  Widget _buildDurationSection(BuildContext context, NoteEditingService service) {
    return Row(
      children: [
        Text(
          'Duration:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        _buildDurationButton(
          context: context,
          service: service,
          duration: NoteDuration.whole,
          label: '𝅝',
          tooltip: 'Whole Note',
        ),
        _buildDurationButton(
          context: context,
          service: service,
          duration: NoteDuration.half,
          label: '𝅗𝅥',
          tooltip: 'Half Note',
        ),
        _buildDurationButton(
          context: context,
          service: service,
          duration: NoteDuration.quarter,
          label: '♩',
          tooltip: 'Quarter Note',
        ),
        _buildDurationButton(
          context: context,
          service: service,
          duration: NoteDuration.eighth,
          label: '♪',
          tooltip: 'Eighth Note',
        ),
        _buildDurationButton(
          context: context,
          service: service,
          duration: NoteDuration.sixteenth,
          label: '𝅘𝅥𝅯',
          tooltip: '16th Note',
        ),
      ],
    );
  }

  Widget _buildDurationButton({
    required BuildContext context,
    required NoteEditingService service,
    required NoteDuration duration,
    required String label,
    required String tooltip,
  }) {
    final isSelected = service.currentDuration == duration;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () => service.setDuration(duration),
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : null,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
        ),
        child: Tooltip(
          message: tooltip,
          child: Text(
            label,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildAccidentalSection(BuildContext context, NoteEditingService service) {
    return Row(
      children: [
        Text(
          'Accidental:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        _buildAccidentalButton(
          context: context,
          service: service,
          accidental: -1,
          label: '♭',
          tooltip: 'Flat',
        ),
        _buildAccidentalButton(
          context: context,
          service: service,
          accidental: 0,
          label: '♮',
          tooltip: 'Natural',
        ),
        _buildAccidentalButton(
          context: context,
          service: service,
          accidental: 1,
          label: '♯',
          tooltip: 'Sharp',
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => service.setAccidental(null),
          child: const Text('None'),
        ),
      ],
    );
  }

  Widget _buildAccidentalButton({
    required BuildContext context,
    required NoteEditingService service,
    required int accidental,
    required String label,
    required String tooltip,
  }) {
    final isSelected = service.currentAccidental == accidental;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () => service.setAccidental(accidental),
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : null,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
        ),
        child: Tooltip(
          message: tooltip,
          child: Text(
            label,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoRedoSection(BuildContext context, NoteEditingService service) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
          onPressed: service.canUndo ? service.undo : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Redo',
          onPressed: service.canRedo ? service.redo : null,
        ),
      ],
    );
  }

  Widget _buildSaveIndicator(BuildContext context, NoteEditingService service) {
    if (!service.isModified) return const SizedBox.shrink();
    
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Text(
          'Unsaved changes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
