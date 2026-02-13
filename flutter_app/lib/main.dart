import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'core/services/library_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/audiveris_service.dart';
import 'core/services/file_import_service.dart';
import 'core/services/musicxml_service.dart';
import 'core/services/midi_playback_service.dart';
import 'desktop/screens/desktop_home_screen.dart';
import 'mobile/screens/mobile_home_screen.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SheetMusicReaderApp());
}

class SheetMusicReaderApp extends StatelessWidget {
  const SheetMusicReaderApp({super.key});

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => AudiverisService()),
        ChangeNotifierProvider(create: (_) => MusicXmlService()),
        ChangeNotifierProvider(create: (_) => MidiPlaybackService()),
        ChangeNotifierProxyProvider2<AudiverisService, LibraryService, FileImportService>(
          create: (context) => FileImportService(
            audiverisService: context.read<AudiverisService>(),
            libraryService: context.read<LibraryService>(),
          ),
          update: (context, audiveris, library, previous) =>
              previous ?? FileImportService(
                audiverisService: audiveris,
                libraryService: library,
              ),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Sheet Music Reader',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            home: _buildHomeScreen(),
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen() {
    if (_isDesktop) {
      return const DesktopHomeScreen();
    } else if (_isMobile) {
      return const MobileHomeScreen();
    } else {
      return const Scaffold(
        body: Center(
          child: Text('Platform not supported'),
        ),
      );
    }
  }
}
