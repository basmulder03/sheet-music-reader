import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_service.dart';

/// A dialog that allows users to select their preferred theme mode
class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  /// Shows the theme selector dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ThemeSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                title: 'System',
                subtitle: 'Follow system settings',
                icon: Icons.settings_suggest_outlined,
                themeMode: ThemeMode.system,
                currentMode: settings.themeMode,
                onTap: () => _selectTheme(context, settings, ThemeMode.system),
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                title: 'Light',
                subtitle: 'Always use light theme',
                icon: Icons.light_mode_outlined,
                themeMode: ThemeMode.light,
                currentMode: settings.themeMode,
                onTap: () => _selectTheme(context, settings, ThemeMode.light),
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                title: 'Dark',
                subtitle: 'Always use dark theme',
                icon: Icons.dark_mode_outlined,
                themeMode: ThemeMode.dark,
                currentMode: settings.themeMode,
                onTap: () => _selectTheme(context, settings, ThemeMode.dark),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _selectTheme(BuildContext context, SettingsService settings, ThemeMode mode) {
    settings.setThemeMode(mode);
    Navigator.of(context).pop();
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode themeMode;
  final ThemeMode currentMode;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeMode,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = themeMode == currentMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
