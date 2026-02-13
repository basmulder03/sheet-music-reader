import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Service for profiling and optimizing rendering performance
class RenderingProfiler {
  static RenderingProfiler? _instance;
  static RenderingProfiler get instance {
    _instance ??= RenderingProfiler._();
    return _instance!;
  }

  RenderingProfiler._();

  // Frame timing tracking
  final List<Duration> _frameTimes = [];
  final List<DateTime> _frameTimestamps = [];
  int _droppedFrames = 0;
  int _totalFrames = 0;
  
  // Performance metrics
  final Map<String, List<Duration>> _operationTimings = {};
  final Map<String, int> _operationCounts = {};
  
  // Performance monitoring
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  FrameCallback? _frameCallback;

  // Thresholds
  static const Duration targetFrameTime = Duration(milliseconds: 16); // 60 FPS
  static const Duration warningFrameTime = Duration(milliseconds: 32); // 30 FPS
  static const int maxStoredFrames = 300; // Store last 5 seconds @ 60fps

  /// Start monitoring rendering performance
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _frameTimes.clear();
    _frameTimestamps.clear();
    _droppedFrames = 0;
    _totalFrames = 0;

    // Add frame callback
    _frameCallback = (Duration timestamp) {
      _recordFrame(timestamp);
      if (_isMonitoring) {
        SchedulerBinding.instance.addPostFrameCallback(_frameCallback!);
      }
    };
    
    SchedulerBinding.instance.addPostFrameCallback(_frameCallback!);

    if (kDebugMode) {
      print('[RenderingProfiler] Started monitoring');
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _frameCallback = null;

    if (kDebugMode) {
      print('[RenderingProfiler] Stopped monitoring');
    }
  }

  /// Record a frame
  void _recordFrame(Duration timestamp) {
    final now = DateTime.now();
    
    if (_frameTimestamps.isNotEmpty) {
      final lastFrame = _frameTimestamps.last;
      final frameDuration = now.difference(lastFrame);
      
      _frameTimes.add(frameDuration);
      
      // Check for dropped frames
      if (frameDuration > targetFrameTime) {
        _droppedFrames++;
      }
      
      _totalFrames++;
      
      // Keep only recent frames
      if (_frameTimes.length > maxStoredFrames) {
        _frameTimes.removeAt(0);
        _frameTimestamps.removeAt(0);
      }
    }
    
    _frameTimestamps.add(now);
  }

  /// Time an operation
  Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _recordOperationTime(operationName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperationTime(operationName, stopwatch.elapsed);
      rethrow;
    }
  }

  /// Time a synchronous operation
  T timeOperationSync<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      _recordOperationTime(operationName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperationTime(operationName, stopwatch.elapsed);
      rethrow;
    }
  }

  /// Record operation timing
  void _recordOperationTime(String operationName, Duration duration) {
    if (!_operationTimings.containsKey(operationName)) {
      _operationTimings[operationName] = [];
      _operationCounts[operationName] = 0;
    }
    
    _operationTimings[operationName]!.add(duration);
    _operationCounts[operationName] = _operationCounts[operationName]! + 1;
    
    // Keep only recent timings
    if (_operationTimings[operationName]!.length > 100) {
      _operationTimings[operationName]!.removeAt(0);
    }
  }

  /// Get frame statistics
  Map<String, dynamic> getFrameStatistics() {
    if (_frameTimes.isEmpty) {
      return {
        'averageFps': 0,
        'minFps': 0,
        'maxFps': 0,
        'droppedFrames': 0,
        'totalFrames': 0,
        'droppedFramePercent': 0.0,
      };
    }

    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) ~/ _frameTimes.length;
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);

    final avgFps = 1000 / avgFrameTime.inMilliseconds;
    final minFps = 1000 / maxFrameTime.inMilliseconds;
    final maxFps = 1000 / minFrameTime.inMilliseconds;

    return {
      'averageFps': avgFps.toStringAsFixed(1),
      'minFps': minFps.toStringAsFixed(1),
      'maxFps': maxFps.toStringAsFixed(1),
      'droppedFrames': _droppedFrames,
      'totalFrames': _totalFrames,
      'droppedFramePercent': (_droppedFrames / _totalFrames * 100).toStringAsFixed(1),
      'averageFrameTimeMs': avgFrameTime.inMilliseconds,
      'isPerformanceGood': avgFrameTime <= targetFrameTime,
      'isPerformanceWarning': avgFrameTime > targetFrameTime && avgFrameTime <= warningFrameTime,
      'isPerformancePoor': avgFrameTime > warningFrameTime,
    };
  }

  /// Get operation statistics
  Map<String, dynamic> getOperationStatistics() {
    final stats = <String, dynamic>{};

    for (final entry in _operationTimings.entries) {
      final timings = entry.value;
      if (timings.isEmpty) continue;

      final avgTime = timings.reduce((a, b) => a + b) ~/ timings.length;
      final minTime = timings.reduce((a, b) => a < b ? a : b);
      final maxTime = timings.reduce((a, b) => a > b ? a : b);
      final count = _operationCounts[entry.key] ?? 0;

      stats[entry.key] = {
        'count': count,
        'averageMs': avgTime.inMilliseconds,
        'minMs': minTime.inMilliseconds,
        'maxMs': maxTime.inMilliseconds,
        'totalMs': (avgTime.inMilliseconds * count),
      };
    }

    return stats;
  }

  /// Get all performance metrics
  Map<String, dynamic> getAllMetrics() {
    return {
      'frames': getFrameStatistics(),
      'operations': getOperationStatistics(),
      'isMonitoring': _isMonitoring,
    };
  }

  /// Clear all recorded data
  void clearMetrics() {
    _frameTimes.clear();
    _frameTimestamps.clear();
    _droppedFrames = 0;
    _totalFrames = 0;
    _operationTimings.clear();
    _operationCounts.clear();

    if (kDebugMode) {
      print('[RenderingProfiler] Cleared all metrics');
    }
  }

  /// Get recommendations based on performance
  List<String> getRecommendations() {
    final recommendations = <String>[];
    final frameStats = getFrameStatistics();
    final operationStats = getOperationStatistics();

    // Check frame rate
    final avgFps = double.tryParse(frameStats['averageFps'] as String? ?? '0') ?? 0;
    if (avgFps < 30) {
      recommendations.add('Frame rate is very low (${avgFps.toStringAsFixed(1)} FPS). Consider reducing UI complexity.');
    } else if (avgFps < 50) {
      recommendations.add('Frame rate could be improved (${avgFps.toStringAsFixed(1)} FPS). Look for expensive operations.');
    }

    // Check dropped frames
    final droppedPercent = double.tryParse(frameStats['droppedFramePercent'] as String? ?? '0') ?? 0;
    if (droppedPercent > 10) {
      recommendations.add('High percentage of dropped frames ($droppedPercent%). Optimize rendering pipeline.');
    }

    // Check operation timings
    for (final entry in operationStats.entries) {
      final stats = entry.value as Map<String, dynamic>;
      final avgMs = stats['averageMs'] as int;
      
      if (avgMs > 50) {
        recommendations.add('Operation "${entry.key}" is slow (${avgMs}ms average). Consider optimization.');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance looks good! No major issues detected.');
    }

    return recommendations;
  }

  /// Export metrics to string
  String exportMetrics() {
    final buffer = StringBuffer();
    buffer.writeln('=== Rendering Performance Report ===');
    buffer.writeln();
    
    final frameStats = getFrameStatistics();
    buffer.writeln('Frame Statistics:');
    for (final entry in frameStats.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln();
    
    final operationStats = getOperationStatistics();
    if (operationStats.isNotEmpty) {
      buffer.writeln('Operation Timings:');
      for (final entry in operationStats.entries) {
        buffer.writeln('  ${entry.key}:');
        final stats = entry.value as Map<String, dynamic>;
        for (final statEntry in stats.entries) {
          buffer.writeln('    ${statEntry.key}: ${statEntry.value}');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('Recommendations:');
    for (final recommendation in getRecommendations()) {
      buffer.writeln('  - $recommendation');
    }
    
    return buffer.toString();
  }
}

/// Mixin for widgets that need performance profiling
mixin RenderingProfilingMixin {
  final RenderingProfiler _profiler = RenderingProfiler.instance;

  Future<T> profileAsync<T>(String operationName, Future<T> Function() operation) {
    return _profiler.timeOperation(operationName, operation);
  }

  T profileSync<T>(String operationName, T Function() operation) {
    return _profiler.timeOperationSync(operationName, operation);
  }
}
