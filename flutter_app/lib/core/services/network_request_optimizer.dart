import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for debouncing and batching network requests
class NetworkRequestOptimizer {
  static NetworkRequestOptimizer? _instance;
  static NetworkRequestOptimizer get instance {
    _instance ??= NetworkRequestOptimizer._();
    return _instance!;
  }

  NetworkRequestOptimizer._();

  // Debouncing timers
  final Map<String, Timer> _debounceTimers = {};
  
  // Batched requests
  final Map<String, List<Map<String, dynamic>>> _batchedRequests = {};
  final Map<String, Timer> _batchTimers = {};
  
  // Default debounce duration
  static const Duration defaultDebounceDuration = Duration(milliseconds: 300);
  
  // Default batch duration
  static const Duration defaultBatchDuration = Duration(milliseconds: 500);

  /// Debounce a function call
  /// 
  /// The function will only be called after [duration] has passed since the last call
  void debounce(
    String key,
    VoidCallback callback, {
    Duration duration = defaultDebounceDuration,
  }) {
    // Cancel existing timer
    _debounceTimers[key]?.cancel();

    // Create new timer
    _debounceTimers[key] = Timer(duration, () {
      callback();
      _debounceTimers.remove(key);
    });

    if (kDebugMode) {
      print('[NetworkOptimizer] Debounced: $key');
    }
  }

  /// Debounce an async function call
  Future<T?> debounceAsync<T>(
    String key,
    Future<T> Function() callback, {
    Duration duration = defaultDebounceDuration,
  }) async {
    // Cancel existing timer
    _debounceTimers[key]?.cancel();

    final completer = Completer<T?>();

    // Create new timer
    _debounceTimers[key] = Timer(duration, () async {
      try {
        final result = await callback();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      } finally {
        _debounceTimers.remove(key);
      }
    });

    if (kDebugMode) {
      print('[NetworkOptimizer] Debounced async: $key');
    }

    return completer.future;
  }

  /// Batch multiple requests together
  /// 
  /// Requests with the same [batchKey] will be grouped and executed together
  void batchRequest(
    String batchKey,
    Map<String, dynamic> request,
    Function(List<Map<String, dynamic>>) onBatchReady, {
    Duration duration = defaultBatchDuration,
    int? maxBatchSize,
  }) {
    // Initialize batch if needed
    if (!_batchedRequests.containsKey(batchKey)) {
      _batchedRequests[batchKey] = [];
    }

    // Add request to batch
    _batchedRequests[batchKey]!.add(request);

    if (kDebugMode) {
      print('[NetworkOptimizer] Added to batch: $batchKey (${_batchedRequests[batchKey]!.length} items)');
    }

    // Check if batch size limit reached
    if (maxBatchSize != null && _batchedRequests[batchKey]!.length >= maxBatchSize) {
      _executeBatch(batchKey, onBatchReady);
      return;
    }

    // Reset batch timer
    _batchTimers[batchKey]?.cancel();
    _batchTimers[batchKey] = Timer(duration, () {
      _executeBatch(batchKey, onBatchReady);
    });
  }

  /// Execute a batched request
  void _executeBatch(
    String batchKey,
    Function(List<Map<String, dynamic>>) onBatchReady,
  ) {
    final batch = _batchedRequests[batchKey];
    if (batch == null || batch.isEmpty) return;

    if (kDebugMode) {
      print('[NetworkOptimizer] Executing batch: $batchKey (${batch.length} items)');
    }

    // Execute callback with batch
    onBatchReady(List.from(batch));

    // Clear batch
    _batchedRequests[batchKey]?.clear();
    _batchTimers[batchKey]?.cancel();
    _batchTimers.remove(batchKey);
  }

  /// Flush all pending batches immediately
  void flushAllBatches() {
    for (final key in _batchTimers.keys.toList()) {
      _batchTimers[key]?.cancel();
      _batchTimers.remove(key);
    }

    if (kDebugMode) {
      print('[NetworkOptimizer] Flushed all batches');
    }
  }

  /// Cancel a specific debounce timer
  void cancelDebounce(String key) {
    _debounceTimers[key]?.cancel();
    _debounceTimers.remove(key);

    if (kDebugMode) {
      print('[NetworkOptimizer] Cancelled debounce: $key');
    }
  }

  /// Cancel all debounce timers
  void cancelAllDebounces() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    if (kDebugMode) {
      print('[NetworkOptimizer] Cancelled all debounces');
    }
  }

  /// Throttle a function call
  /// 
  /// The function can only be called once every [duration]
  Timer? _throttleTimer;
  DateTime? _lastThrottleCall;

  void throttle(
    String key,
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    final now = DateTime.now();

    if (_lastThrottleCall == null ||
        now.difference(_lastThrottleCall!) >= duration) {
      _lastThrottleCall = now;
      callback();

      if (kDebugMode) {
        print('[NetworkOptimizer] Throttled call executed: $key');
      }
    } else {
      if (kDebugMode) {
        print('[NetworkOptimizer] Throttled call ignored: $key');
      }
    }
  }

  /// Get statistics about debouncing and batching
  Map<String, dynamic> getStatistics() {
    int totalBatchedRequests = 0;
    for (final batch in _batchedRequests.values) {
      totalBatchedRequests += batch.length;
    }

    return {
      'activeDebounces': _debounceTimers.length,
      'activeBatches': _batchedRequests.length,
      'totalBatchedRequests': totalBatchedRequests,
      'batchDetails': _batchedRequests.map((key, value) => MapEntry(key, value.length)),
    };
  }

  /// Clear all state
  void dispose() {
    cancelAllDebounces();
    flushAllBatches();
    
    _batchedRequests.clear();
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _lastThrottleCall = null;

    if (kDebugMode) {
      print('[NetworkOptimizer] Disposed');
    }
  }
}

/// Mixin for widgets that need debouncing functionality
mixin DebounceMixin {
  final NetworkRequestOptimizer _optimizer = NetworkRequestOptimizer.instance;

  void debounceCall(
    String key,
    VoidCallback callback, {
    Duration duration = NetworkRequestOptimizer.defaultDebounceDuration,
  }) {
    _optimizer.debounce(key, callback, duration: duration);
  }

  Future<T?> debounceAsyncCall<T>(
    String key,
    Future<T> Function() callback, {
    Duration duration = NetworkRequestOptimizer.defaultDebounceDuration,
  }) {
    return _optimizer.debounceAsync(key, callback, duration: duration);
  }

  void throttleCall(
    String key,
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    _optimizer.throttle(key, callback, duration: duration);
  }
}
