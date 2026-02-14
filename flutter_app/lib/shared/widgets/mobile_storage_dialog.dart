import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/image_cache_service.dart';
import '../../mobile/services/mobile_offline_storage_service.dart';

/// A dialog for managing mobile storage (cached images and offline sheet music)
class MobileStorageDialog extends StatefulWidget {
  const MobileStorageDialog({super.key});

  /// Shows the mobile storage dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const MobileStorageDialog(),
    );
  }

  @override
  State<MobileStorageDialog> createState() => _MobileStorageDialogState();
}

class _MobileStorageDialogState extends State<MobileStorageDialog> {
  bool _isLoading = true;
  bool _isClearing = false;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _offlineStatistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final offlineStorage = context.read<MobileOfflineStorageService>();
      final stats = await ImageCacheService.instance.getStatistics();
      final offlineStats = await offlineStorage.getOfflineStatistics();
      if (mounted) {
        setState(() {
          _statistics = stats;
          _offlineStatistics = offlineStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove all cached images and thumbnails. '
          'They will be re-downloaded when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isClearing = true);
      try {
        await ImageCacheService.instance.clearAll();
        await _loadStatistics();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared successfully')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isClearing = false);
        }
      }
    }
  }

  Future<void> _clearMemoryCacheOnly() async {
    ImageCacheService.instance.clearMemoryCache();
    await _loadStatistics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory cache cleared')),
      );
    }
  }

  Future<void> _clearOfflineDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Offline Downloads?'),
        content: const Text(
          'This removes all offline sheet music files from this device. '
          'You can download them again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isClearing = true);
      try {
        await context
            .read<MobileOfflineStorageService>()
            .clearAllOfflineDownloads();
        await _loadStatistics();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline downloads removed')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isClearing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Storage'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    title: 'Offline Downloads',
                    subtitle: 'Saved scores for disconnected use',
                    icon: Icons.offline_pin_outlined,
                    children: [
                      _StatRow(
                        label: 'Saved Scores',
                        value: '${_offlineStatistics?['documentCount'] ?? 0}',
                        detail: 'documents',
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        label: 'Offline Size',
                        value: _offlineStatistics?['sizeFormatted'] ?? '0 B',
                        detail:
                            '${_offlineStatistics?['fileCount'] ?? 0} files',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isClearing ? null : _clearOfflineDownloads,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Clear Offline Downloads'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Image Cache',
                    subtitle: 'Thumbnails and sheet music images',
                    icon: Icons.image_outlined,
                    children: [
                      _StatRow(
                        label: 'Memory Cache',
                        value: _statistics?['memorySizeFormatted'] ?? '0 B',
                        detail: '${_statistics?['memoryEntries'] ?? 0} items',
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        label: 'Disk Cache',
                        value: _statistics?['diskSizeFormatted'] ?? '0 B',
                        detail: '${_statistics?['diskEntries'] ?? 0} files',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Cache Limits',
                    subtitle: 'Maximum storage allocation',
                    icon: Icons.storage_outlined,
                    children: [
                      const _StatRow(
                        label: 'Memory Limit',
                        value: '50 MB',
                        detail: 'RAM usage',
                      ),
                      const SizedBox(height: 8),
                      const _StatRow(
                        label: 'Disk Limit',
                        value: '200 MB',
                        detail: 'Storage usage',
                      ),
                      const SizedBox(height: 8),
                      const _StatRow(
                        label: 'Cache Expiry',
                        value: '30 days',
                        detail: 'Auto-cleanup',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isClearing ? null : _clearMemoryCacheOnly,
                          icon: const Icon(Icons.memory, size: 18),
                          label: const Text('Clear Memory'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isClearing ? null : _clearCache,
                          icon: _isClearing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Clear All'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                        ),
                      ),
                    ],
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
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const _StatRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            detail,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
