// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sheet_music_reader/main.dart';
import 'package:sheet_music_reader/core/services/settings_service.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Create a settings service for testing
    final settingsService = SettingsService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(SheetMusicReaderApp(settingsService: settingsService));

    // Verify that the app launches without errors.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

