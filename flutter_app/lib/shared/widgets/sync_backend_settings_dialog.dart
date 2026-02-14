import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart';

class SyncBackendSettingsDialog extends StatefulWidget {
  const SyncBackendSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SyncBackendSettingsDialog(),
    );
  }

  @override
  State<SyncBackendSettingsDialog> createState() =>
      _SyncBackendSettingsDialogState();
}

class _SyncBackendSettingsDialogState extends State<SyncBackendSettingsDialog> {
  late SyncConnectionMode _mode;
  late TextEditingController _urlController;
  late TextEditingController _tokenController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _mode = settings.syncConnectionMode;
    _urlController = TextEditingController(text: settings.syncBackendUrl);
    _tokenController = TextEditingController(text: settings.syncBackendToken);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final settings = context.read<SettingsService>();
    await settings.setSyncConnectionMode(_mode);
    await settings.setSyncBackendUrl(_urlController.text.trim());
    await settings.setSyncBackendToken(_tokenController.text.trim());

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync backend settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync Backend'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how this device connects for synchronization.',
            ),
            const SizedBox(height: 12),
            RadioListTile<SyncConnectionMode>(
              value: SyncConnectionMode.localDesktop,
              groupValue: _mode,
              title: const Text('Local desktop (same network)'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _mode = value);
              },
            ),
            RadioListTile<SyncConnectionMode>(
              value: SyncConnectionMode.selfHostedBackend,
              groupValue: _mode,
              title: const Text('Self-hosted backend'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _mode = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'https://sync.example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'API Token',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
