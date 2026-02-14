import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/sheet_music_document.dart';
import '../../shared/widgets/theme_selector_dialog.dart';
import '../../shared/widgets/mobile_storage_dialog.dart';
import '../../shared/widgets/about_dialog.dart' as app_about;
import '../widgets/mobile_sync_settings_dialog.dart';
import '../services/server_discovery_service.dart';
import '../services/mobile_connection_service.dart';
import '../services/mobile_offline_storage_service.dart';
import 'mobile_document_viewer_screen.dart';
import 'camera_capture_screen.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Capture',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _LibraryView();
      case 1:
        return const _CaptureView();
      case 2:
        return const _ConnectView();
      case 3:
        return const _SettingsView();
      default:
        return const Center(child: Text('Unknown view'));
    }
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<SheetMusicDocument> _searchResults = [];
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load next page when user is 200 pixels from bottom
      final connectionService = context.read<MobileConnectionService>();
      if (connectionService.isConnected &&
          connectionService.hasMoreDocuments &&
          !connectionService.isLoadingMore) {
        connectionService.loadNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    final connectionService = context.read<MobileConnectionService>();
    if (connectionService.isConnected) {
      await connectionService.syncDocuments();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
    });

    final connectionService = context.read<MobileConnectionService>();
    final results = await connectionService.search(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    }
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileConnectionService>(
      builder: (context, connectionService, _) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search sheet music...',
                          border: InputBorder.none,
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _performSearch(value);
                        },
                      )
                    : Row(
                        children: [
                          const Text('My Sheet Music'),
                          if (connectionService.isConnected &&
                              connectionService.totalDocumentCount != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                '(${connectionService.documents.length}/${connectionService.totalDocumentCount})',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      ),
                floating: true,
                leading: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _closeSearch,
                      )
                    : null,
                actions: [
                  if (!_isSearching) ...[
                    if (connectionService.isConnected)
                      IconButton(
                        icon: connectionService.isSyncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: connectionService.isSyncing
                            ? null
                            : () => connectionService.syncDocuments(),
                        tooltip: 'Sync with desktop',
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: connectionService.isConnected
                          ? () {
                              setState(() {
                                _isSearching = true;
                              });
                            }
                          : null,
                      tooltip: 'Search library',
                    ),
                  ],
                ],
              ),
              if (!connectionService.isConnected)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Not Connected',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect to desktop to view your library',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            DefaultTabController.of(context).animateTo(2);
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Connect Now'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isSearching && _isSearchLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_isSearching &&
                  _searchQuery.isNotEmpty &&
                  _searchResults.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try a different search term',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isSearching && _searchResults.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = _searchResults[index];
                        return _DocumentListTile(document: doc);
                      },
                      childCount: _searchResults.length,
                    ),
                  ),
                )
              else if (connectionService.documents.isEmpty &&
                  !connectionService.isLoadingMore)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sheet music yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add music on desktop or capture with camera',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Show loading indicator at the end
                        if (index >= connectionService.documents.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final doc = connectionService.documents[index];
                        return _DocumentListTile(document: doc);
                      },
                      childCount: connectionService.documents.length +
                          (connectionService.isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentListTile extends StatelessWidget {
  final SheetMusicDocument document;

  const _DocumentListTile({required this.document});

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with document info
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (document.composer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      document.composer!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Menu options
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        MobileDocumentViewerScreen(document: document),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () {
                Navigator.of(context).pop();
                _showDetailsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                _shareDocument(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Download for Offline',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _downloadForOffline(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Title', value: document.title),
              if (document.composer != null)
                _DetailRow(label: 'Composer', value: document.composer!),
              if (document.arranger != null)
                _DetailRow(label: 'Arranger', value: document.arranger!),
              _DetailRow(
                label: 'Pages',
                value: document.metadata.pageCount.toString(),
              ),
              if (document.metadata.timeSignature != null)
                _DetailRow(
                  label: 'Time Signature',
                  value: document.metadata.timeSignature!,
                ),
              if (document.metadata.keySignature != null)
                _DetailRow(
                  label: 'Key Signature',
                  value: document.metadata.keySignature!,
                ),
              if (document.metadata.tempo != null)
                _DetailRow(
                  label: 'Tempo',
                  value: '${document.metadata.tempo} BPM',
                ),
              if (document.metadata.measureCount != null)
                _DetailRow(
                  label: 'Measures',
                  value: document.metadata.measureCount.toString(),
                ),
              if (document.tags.isNotEmpty)
                _DetailRow(label: 'Tags', value: document.tags.join(', ')),
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Created',
                value: _formatDate(document.createdAt),
              ),
              _DetailRow(
                label: 'Modified',
                value: _formatDate(document.modifiedAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareDocument(BuildContext context) {
    // Show a snackbar indicating share functionality
    // In a real app, this would use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
      ),
    );
  }

  Future<void> _downloadForOffline(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final connectionService = context.read<MobileConnectionService>();
    final offlineStorage = context.read<MobileOfflineStorageService>();

    messenger.showSnackBar(
      SnackBar(
        content: Text('Downloading "${document.title}" for offline use...'),
      ),
    );

    final musicXml = await connectionService.getMusicXml(document.id);
    if (musicXml == null) {
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('Could not download this document. Check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await offlineStorage.saveMusicXml(
        documentId: document.id, musicXml: musicXml);

    final sourceFile = await connectionService.getSourceFile(document.id);
    if (sourceFile != null) {
      await offlineStorage.saveSourceFile(
        documentId: document.id,
        bytes: sourceFile.bytes,
        fileName: sourceFile.fileName,
        contentType: sourceFile.contentType,
      );
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sourceFile == null
              ? 'Saved "${document.title}" for offline use'
              : 'Saved "${document.title}" with source file for offline use',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          document.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: document.composer != null
            ? Text(
                document.composer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptionsMenu(context),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  MobileDocumentViewerScreen(document: document),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Sheet Music'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Take a photo of sheet music to convert it to digital format',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CameraCaptureScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectView extends StatefulWidget {
  const _ConnectView();

  @override
  State<_ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<_ConnectView> {
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '8080');

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Desktop'),
      ),
      body: Consumer2<ServerDiscoveryService, MobileConnectionService>(
        builder: (context, discoveryService, connectionService, _) {
          // If connected, show connection info
          if (connectionService.isConnected) {
            return _buildConnectedView(connectionService);
          }

          // If connecting, show loading
          if (connectionService.status == ConnectionStatus.connecting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Connecting to server...'),
                ],
              ),
            );
          }

          // Otherwise show discovery UI
          return _buildDiscoveryView(discoveryService, connectionService);
        },
      ),
    );
  }

  Widget _buildConnectedView(MobileConnectionService connectionService) {
    final server = connectionService.connectedServer!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Connected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            server.url,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.computer,
                    label: 'Server',
                    value: server.address,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.router,
                    label: 'Port',
                    value: '${server.port}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Connected',
                    value: _formatDuration(
                      DateTime.now().difference(server.discoveredAt),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await connectionService.disconnect();
              },
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryView(
    ServerDiscoveryService discoveryService,
    MobileConnectionService connectionService,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Discovery section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Find My Desktop',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (discoveryService.isDiscovering)
                    const LinearProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => discoveryService.startDiscovery(),
                        icon: const Icon(Icons.search),
                        label: const Text('Find Desktops (Recommended)'),
                      ),
                    ),
                  if (discoveryService.discoveredServers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Available desktops:'),
                    const SizedBox(height: 8),
                    ...discoveryService.discoveredServers.map((server) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.computer),
                          title: Text(server.name == 'Desktop Server'
                              ? server.address
                              : server.name),
                          subtitle: Text('${server.address}:${server.port}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _connectToServer(
                            connectionService,
                            server,
                          ),
                        ),
                      );
                    }),
                  ],
                  if (discoveryService.isDiscovering &&
                      discoveryService.discoveredServers.isEmpty) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Scanning local network...',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Advanced connection section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Easy First Step',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use the button above to find your desktop automatically. Most setups work right away.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
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
                          'Only use this if auto-discovery does not work'),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Desktop name or address',
                            hintText: 'My-Laptop or 192.168.1.100',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.computer),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '8080',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.router),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _connectManually(
                              discoveryService,
                              connectionService,
                            ),
                            icon: const Icon(Icons.link),
                            label: const Text('Try Advanced Connection'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (connectionService.errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        connectionService.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connectToServer(
    MobileConnectionService connectionService,
    DiscoveredServer server,
  ) async {
    final success = await connectionService.connect(server);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${server.address}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _connectManually(
    ServerDiscoveryService discoveryService,
    MobileConnectionService connectionService,
  ) async {
    final address = _addressController.text.trim();
    final portText = _portController.text.trim();
    final port = int.tryParse(portText) ?? 8080;

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a desktop name or address')),
      );
      return;
    }

    final server = await discoveryService.addManualServer(address, port);
    if (server != null) {
      await _connectToServer(connectionService, server);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to server'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: const Text('Choose your preferred theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ThemeSelectorDialog.show(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Storage'),
            subtitle: const Text('Manage downloaded sheet music'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              MobileStorageDialog.show(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('Sync Settings'),
            subtitle: const Text('Configure synchronization'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              MobileSyncSettingsDialog.show(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('About'),
            subtitle: const Text('Version and license information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              app_about.AboutDialog.show(context);
            },
          ),
        ],
      ),
    );
  }
}
