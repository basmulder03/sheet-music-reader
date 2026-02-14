import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/desktop_server_service.dart';

/// Dialog for configuring server settings
class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  /// Show the server settings dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ServerSettingsDialog(),
    );
  }

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late TextEditingController _portController;
  late TextEditingController _deviceNameController;
  late TextEditingController _backendUrlController;
  late TextEditingController _backendTokenController;
  late bool _autoStartServer;
  late bool _enableMdns;
  late SyncConnectionMode _syncMode;

  bool _isLoading = false;
  String? _errorMessage;
  bool _portAvailable = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();

    _portController =
        TextEditingController(text: settings.serverPort.toString());
    _deviceNameController = TextEditingController(text: settings.deviceName);
    _backendUrlController =
        TextEditingController(text: settings.syncBackendUrl);
    _backendTokenController =
        TextEditingController(text: settings.syncBackendToken);
    _autoStartServer = settings.autoStartServer;
    _enableMdns = settings.enableMdns;
    _syncMode = settings.syncConnectionMode;

    _portController.addListener(_onSettingsChanged);
    _deviceNameController.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _portController.dispose();
    _deviceNameController.dispose();
    _backendUrlController.dispose();
    _backendTokenController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  Future<bool> _checkPortAvailability(int port) async {
    try {
      // Check if port is in valid range
      if (port < 1024 || port > 65535) {
        return false;
      }

      // Check if the server is currently using this port
      final serverService = context.read<DesktopServerService>();
      if (serverService.isRunning && serverService.port == port) {
        return true; // Current port is fine
      }

      // Try to bind to the port temporarily
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await server.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _validatePort() async {
    final port = int.tryParse(_portController.text);
    if (port == null) {
      setState(() {
        _portAvailable = false;
        _errorMessage = 'Invalid port number';
      });
      return;
    }

    if (port < 1024 || port > 65535) {
      setState(() {
        _portAvailable = false;
        _errorMessage = 'Port must be between 1024 and 65535';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final available = await _checkPortAvailability(port);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _portAvailable = available;
        if (!available) {
          _errorMessage = 'Port $port is already in use';
        }
      });
    }
  }

  Future<void> _save() async {
    final port = int.tryParse(_portController.text);
    if (port == null) {
      setState(() {
        _errorMessage = 'Invalid port number';
      });
      return;
    }

    if (port < 1024 || port > 65535) {
      setState(() {
        _errorMessage = 'Port must be between 1024 and 65535';
      });
      return;
    }

    final deviceName = _deviceNameController.text.trim();
    if (deviceName.isEmpty) {
      setState(() {
        _errorMessage = 'Device name cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = context.read<SettingsService>();
      final serverService = context.read<DesktopServerService>();

      // Check if server needs restart due to port change
      final needsRestart =
          serverService.isRunning && settings.serverPort != port;

      // Save settings
      await settings.setServerPort(port);
      await settings.setDeviceName(deviceName);
      await settings.setAutoStartServer(_autoStartServer);
      await settings.setEnableMdns(_enableMdns);
      await settings.setSyncConnectionMode(_syncMode);
      await settings.setSyncBackendUrl(_backendUrlController.text.trim());
      await settings.setSyncBackendToken(_backendTokenController.text.trim());

      // Restart server if port changed and server was running
      if (needsRestart) {
        await serverService.stopServer();
        // Update the port in server service
        serverService.setPort(port);
        await serverService.startServer();
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              needsRestart
                  ? 'Server settings saved and server restarted'
                  : 'Server settings saved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save settings: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_outlined),
          SizedBox(width: 12),
          Text('Server Settings'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure the network server for mobile device synchronization.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Device Name
              Text(
                'Device Name',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  hintText: 'Sheet Music Reader',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.computer),
                  helperText: 'Name shown to mobile devices',
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Most users should leave advanced network settings unchanged.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),

              // Auto-start server
              SwitchListTile(
                title: const Text('Auto-start Server'),
                subtitle: const Text('Start server when app launches'),
                value: _autoStartServer,
                onChanged: (value) {
                  setState(() {
                    _autoStartServer = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              // Enable mDNS
              SwitchListTile(
                title: const Text('Network Discovery'),
                subtitle: const Text(
                    'Allow mobile devices to find this server automatically'),
                value: _enableMdns,
                onChanged: (value) {
                  setState(() {
                    _enableMdns = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 12),
              Text(
                'Sync Mode',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<SyncConnectionMode>(
                segments: const [
                  ButtonSegment(
                    value: SyncConnectionMode.localDesktop,
                    icon: Icon(Icons.devices),
                    label: Text('Local Desktop'),
                  ),
                  ButtonSegment(
                    value: SyncConnectionMode.selfHostedBackend,
                    icon: Icon(Icons.cloud),
                    label: Text('Self-hosted'),
                  ),
                ],
                selected: <SyncConnectionMode>{_syncMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _syncMode = selection.first;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                _syncMode == SyncConnectionMode.selfHostedBackend
                    ? 'Desktop will connect to your self-hosted sync server.'
                    : 'Desktop will use local network server mode.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (_syncMode == SyncConnectionMode.selfHostedBackend) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _backendUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    hintText: 'https://sync.example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _backendTokenController,
                  decoration: const InputDecoration(
                    labelText: 'API Token',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  obscureText: true,
                ),
              ],

              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  title: const Text(
                    'Advanced troubleshooting (nuclear options)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                      'Only change this if troubleshooting asks you to'),
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Custom connection port',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _portController,
                            decoration: InputDecoration(
                              hintText: '8080',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.router),
                              errorText: !_portAvailable ? _errorMessage : null,
                              suffixIcon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : _portAvailable &&
                                          _portController.text.isNotEmpty
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            onChanged: (_) {
                              _validatePort();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            _portController.text = '8080';
                            _validatePort();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use a value between 1024 and 65535',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Server status info
              Consumer<DesktopServerService>(
                builder: (context, serverService, _) {
                  if (serverService.isRunning) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Server is running',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${serverService.serverAddress}:${serverService.port}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Server is not running. Changes will apply when the server starts.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              if (_errorMessage != null && _portAvailable) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || !_portAvailable ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
