import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/server_discovery_service.dart';
import '../services/mobile_connection_service.dart';

/// A dialog for managing synchronization settings on mobile
class MobileSyncSettingsDialog extends StatefulWidget {
  const MobileSyncSettingsDialog({super.key});

  /// Shows the sync settings dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const MobileSyncSettingsDialog(),
    );
  }

  @override
  State<MobileSyncSettingsDialog> createState() => _MobileSyncSettingsDialogState();
}

class _MobileSyncSettingsDialogState extends State<MobileSyncSettingsDialog> {
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connectManually() async {
    final address = _addressController.text.trim();
    final portText = _portController.text.trim();
    
    if (address.isEmpty) {
      setState(() => _errorMessage = 'Please enter an IP address');
      return;
    }
    
    final port = int.tryParse(portText);
    if (port == null || port <= 0 || port > 65535) {
      setState(() => _errorMessage = 'Please enter a valid port (1-65535)');
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final discovery = context.read<ServerDiscoveryService>();
      final connection = context.read<MobileConnectionService>();
      
      final server = await discovery.addManualServer(address, port);
      if (server != null) {
        await connection.connect(server);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to $address:$port')),
          );
        }
      } else {
        setState(() => _errorMessage = 'Could not reach server at $address:$port');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    final connection = context.read<MobileConnectionService>();
    await connection.disconnect();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshDiscovery() async {
    final discovery = context.read<ServerDiscoveryService>();
    await discovery.stopDiscovery();
    await discovery.startDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Sync Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer2<MobileConnectionService, ServerDiscoveryService>(
          builder: (context, connection, discovery, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status
                  _buildConnectionStatus(connection, colorScheme),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Discovered Servers
                  _buildDiscoveredServers(discovery, connection, colorScheme),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Manual Connection
                  _buildManualConnection(colorScheme),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(MobileConnectionService connection, ColorScheme colorScheme) {
    final status = connection.status;
    final server = connection.connectedServer;

    IconData icon;
    Color iconColor;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        icon = Icons.cloud_done_outlined;
        iconColor = Colors.green;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        icon = Icons.cloud_sync_outlined;
        iconColor = Colors.orange;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.error:
        icon = Icons.cloud_off_outlined;
        iconColor = Colors.red;
        statusText = 'Error';
        break;
      case ConnectionStatus.disconnected:
      default:
        icon = Icons.cloud_off_outlined;
        iconColor = colorScheme.onSurfaceVariant;
        statusText = 'Disconnected';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sync_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'Connection Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    if (server != null)
                      Text(
                        '${server.name}\n${server.address}:${server.port}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (connection.errorMessage != null)
                      Text(
                        connection.errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              if (status == ConnectionStatus.connected)
                TextButton(
                  onPressed: _disconnect,
                  child: const Text('Disconnect'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveredServers(
    ServerDiscoveryService discovery,
    MobileConnectionService connection,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.devices_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Available Servers',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: discovery.isDiscovering
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 20),
              onPressed: discovery.isDiscovering ? null : _refreshDiscovery,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (discovery.discoveredServers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              discovery.isDiscovering
                  ? 'Searching for servers...'
                  : 'No servers found. Make sure your desktop app is running.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...discovery.discoveredServers.map((server) {
            final isConnected = connection.connectedServer == server;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.computer,
                color: isConnected ? Colors.green : colorScheme.onSurfaceVariant,
              ),
              title: Text(server.name),
              subtitle: Text('${server.address}:${server.port}'),
              trailing: isConnected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : TextButton(
                      onPressed: () async {
                        await connection.connect(server);
                        if (mounted && connection.isConnected) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Connect'),
                    ),
            );
          }),
      ],
    );
  }

  Widget _buildManualConnection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'Manual Connection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.100',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isConnecting ? null : _connectManually,
            icon: _isConnecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.link, size: 18),
            label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
          ),
        ),
      ],
    );
  }
}
