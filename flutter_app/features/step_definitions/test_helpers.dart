import 'package:flutter/material.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test context that holds state between step definitions
class TestContext {
  // Library state
  List<Map<String, dynamic>> documents = [];
  Map<String, dynamic>? selectedDocument;
  String? lastError;
  
  // Viewer state
  int currentPage = 1;
  double zoomLevel = 1.0;
  
  // OMR state
  String? omrStatus;
  double omrProgress = 0.0;
  Map<String, dynamic>? omrResult;
  
  // Sync state
  List<Map<String, String>> discoveredServers = [];
  String? connectedServerName;
  bool isOnline = true;
  
  // Annotation state
  List<Map<String, dynamic>> annotations = [];
  Map<String, dynamic>? selectedAnnotation;
  
  // Performance metrics
  Map<String, dynamic> performanceMetrics = {};
  
  // Test data paths
  String testDataPath = 'D:\\github\\basmulder03\\sheet-music-reader\\test_files';
  
  void reset() {
    documents = [];
    selectedDocument = null;
    lastError = null;
    currentPage = 1;
    zoomLevel = 1.0;
    omrStatus = null;
    omrProgress = 0.0;
    omrResult = null;
    discoveredServers = [];
    connectedServerName = null;
    isOnline = true;
    annotations = [];
    selectedAnnotation = null;
    performanceMetrics = {};
  }
}

/// Helper functions for common test operations
class TestHelpers {
  static Future<void> waitForElement(
    FlutterDriver driver,
    SerializableFinder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await driver.waitFor(finder, timeout: timeout);
  }
  
  static Future<void> tapElement(
    FlutterDriver driver,
    SerializableFinder finder,
  ) async {
    await driver.tap(finder);
  }
  
  static Future<String> getTextFromElement(
    FlutterDriver driver,
    SerializableFinder finder,
  ) async {
    return await driver.getText(finder);
  }
  
  static Future<void> enterText(
    FlutterDriver driver,
    SerializableFinder finder,
    String text,
  ) async {
    await driver.tap(finder);
    await driver.enterText(text);
  }
  
  static Future<void> scrollUntilVisible(
    FlutterDriver driver,
    SerializableFinder scrollable,
    SerializableFinder target, {
    double delta = -300,
  }) async {
    await driver.scrollUntilVisible(
      scrollable,
      target,
      dyScroll: delta,
    );
  }
  
  static SerializableFinder findByText(String text) {
    return find.text(text);
  }
  
  static SerializableFinder findByKey(String key) {
    return find.byValueKey(key);
  }
  
  static SerializableFinder findByType(String type) {
    return find.byType(type);
  }
  
  /// Wait for a condition to be true with timeout
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration checkInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return;
      }
      await Future.delayed(checkInterval);
    }
    
    throw TimeoutException('Condition not met within timeout');
  }
  
  /// Verify element exists
  static Future<bool> elementExists(
    FlutterDriver driver,
    SerializableFinder finder,
  ) async {
    try {
      await driver.waitFor(finder, timeout: const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Take screenshot for debugging
  static Future<void> takeScreenshot(
    FlutterDriver driver,
    String name,
  ) async {
    final pixels = await driver.screenshot();
    // Could save to file if needed
    print('Screenshot taken: $name (${pixels.length} bytes)');
  }
  
  /// Simulate file selection (mock)
  static Future<String> mockFileSelection(String fileName) async {
    // In real implementation, this would interact with file picker
    return 'D:\\github\\basmulder03\\sheet-music-reader\\test_files\\$fileName';
  }
  
  /// Wait for async operation with progress
  static Future<void> waitForProgress(
    bool Function() isComplete,
    Function()? onProgress, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      if (isComplete()) {
        return;
      }
      onProgress?.call();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    throw TimeoutException('Operation not completed within timeout');
  }
}

/// Custom exception for test timeouts
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

/// Mock data generators for tests
class MockData {
  static Map<String, dynamic> createDocument({
    required String title,
    String? composer,
    String? path,
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'composer': composer ?? 'Unknown Composer',
      'path': path ?? '/mock/path/$title.xml',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'page_count': 5,
      'type': 'musicxml',
    };
  }
  
  static Map<String, dynamic> createAnnotation({
    required String type,
    required int page,
    String? content,
    String? color,
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'page': page,
      'content': content,
      'color': color ?? '#FFFF00',
      'created_at': DateTime.now().toIso8601String(),
    };
  }
  
  static Map<String, String> createServer({
    required String name,
    String? address,
  }) {
    return {
      'name': name,
      'address': address ?? '192.168.1.100',
      'port': '8080',
    };
  }
}
