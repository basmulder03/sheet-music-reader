import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/settings_service.dart';

/// Dialog for selecting the storage location for sheet music files
class StorageLocationDialog extends StatefulWidget {
  const StorageLocationDialog({super.key});

  /// Show the storage location dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const StorageLocationDialog(),
    );
  }

  @override
  State<StorageLocationDialog> createState() => _StorageLocationDialogState();
}

class _StorageLocationDialogState extends State<StorageLocationDialog> {
  String? _currentPath;
  String? _defaultPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    // Get current setting before async operation
    final settings = context.read<SettingsService>();
    final currentSettingPath = settings.defaultStoragePath;

    try {
      // Get the default application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final defaultPath = '${appDocDir.path}/SheetMusicReader';

      if (!mounted) return;

      setState(() {
        _defaultPath = defaultPath;
        _currentPath = currentSettingPath.isNotEmpty ? currentSettingPath : defaultPath;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load paths: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Storage Location',
        initialDirectory: _currentPath,
      );

      if (result != null) {
        // Verify the directory exists and is writable
        final dir = Directory(result);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // Test write access
        final testFile = File('${dir.path}/.write_test');
        try {
          await testFile.writeAsString('test');
          await testFile.delete();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot write to selected folder: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _currentPath = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting folder: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    if (_defaultPath != null) {
      setState(() {
        _currentPath = _defaultPath;
      });
    }
  }

  Future<void> _save() async {
    if (_currentPath == null) return;

    final settings = context.read<SettingsService>();
    await settings.setDefaultStoragePath(_currentPath!);

    // Ensure directory exists
    final dir = Directory(_currentPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage location updated'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.folder_outlined),
          SizedBox(width: 12),
          Text('Storage Location'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose where to save your sheet music files.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Current Location:',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentPath ?? 'Not set',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectFolder,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Browse...'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _currentPath != _defaultPath
                                  ? _resetToDefault
                                  : null,
                              icon: const Icon(Icons.restore),
                              label: const Text('Reset Default'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Changing this location will not move existing files. '
                                'New imports will be saved to the selected folder.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _currentPath != null ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
