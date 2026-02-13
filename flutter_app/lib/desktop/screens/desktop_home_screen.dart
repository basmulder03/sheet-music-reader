import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/library_service.dart';
import '../../core/services/file_import_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/models/sheet_music_document.dart';
import '../../shared/widgets/theme_selector_dialog.dart';
import '../../shared/widgets/storage_location_dialog.dart';
import '../widgets/server_controls.dart';
import '../widgets/server_status.dart';
import 'document_viewer_screen.dart';

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final libraryService = context.read<LibraryService>();
    await libraryService.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: Text('Library'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: Text('Import'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dns_outlined),
                selectedIcon: Icon(Icons.dns),
                label: Text('Server'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
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
        return const _ImportView();
      case 2:
        return const _ServerView();
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
      final library = context.read<LibraryService>();
      if (library.hasMorePages && !library.isLoadingMore) {
        library.loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (_isSearching) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  tooltip: 'Close search',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by title, composer, arranger, or tags...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ] else ...[
                const Text(
                  'Sheet Music Library',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Consumer<LibraryService>(
                  builder: (context, library, _) {
                    if (library.totalDocumentCount != null) {
                      return Text(
                        '(${library.documents.length} of ${library.totalDocumentCount} loaded)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  tooltip: 'Search library',
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Consumer<LibraryService>(
            builder: (context, library, _) {
              // Get filtered documents based on search query
              final displayDocuments = _searchQuery.isEmpty
                  ? library.documents
                  : library.search(_searchQuery);

              if (displayDocuments.isEmpty && !library.isLoadingMore) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off
                            : Icons.library_music_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No results found'
                            : 'No sheet music in library',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Import PDF or images to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: displayDocuments.length + 
                    (library.isLoadingMore && _searchQuery.isEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end (only when not searching)
                  if (index >= displayDocuments.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final doc = displayDocuments[index];
                  return _DocumentCard(document: doc);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final SheetMusicDocument document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DocumentViewerScreen(document: document),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: Icon(
                    Icons.music_note,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (document.composer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      document.composer!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportView extends StatelessWidget {
  const _ImportView();

  @override
  Widget build(BuildContext context) {
    return Consumer<FileImportService>(
      builder: (context, importService, _) {
        if (importService.isImporting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  importService.currentFileName ?? 'Processing...',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (importService.importStatus != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                    child: Text(
                      importService.importStatus!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 300,
                  child: LinearProgressIndicator(
                    value: importService.importProgress,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(importService.importProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Import Sheet Music',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Convert PDF or images to editable sheet music'),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final importService = context.read<FileImportService>();
                  await importService.pickAndImportFiles();
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Select Files'),
              ),
              if (importService.importStatus != null && !importService.isImporting) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          importService.importStatus!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () {
                          importService.clearStatus();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ServerView extends StatelessWidget {
  const _ServerView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Server',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        const ServerControls(),
        const SizedBox(height: 16),
        const ServerStatus(),
      ],
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ListTile(
          title: const Text('Theme'),
          subtitle: const Text('Choose your preferred theme'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ThemeSelectorDialog.show(context);
          },
        ),
        ListTile(
          title: const Text('Storage Location'),
          subtitle: Consumer<SettingsService>(
            builder: (context, settings, _) {
              final path = settings.defaultStoragePath;
              return Text(
                path.isNotEmpty ? path : 'Default location',
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            StorageLocationDialog.show(context);
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('Server Settings'),
          subtitle: const Text('Configure network server'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Show server settings
          },
        ),
      ],
    );
  }
}
