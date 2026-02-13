import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for communicating with the Audiveris Java backend
class AudiverisService extends ChangeNotifier {
  final String baseUrl;
  Process? _serverProcess;
  bool _isRunning = false;

  AudiverisService({this.baseUrl = 'http://localhost:8081'});

  bool get isRunning => _isRunning;

  /// Start the Audiveris server if not already running
  Future<bool> startServer() async {
    if (_isRunning) return true;

    try {
      // Check if server is already running
      if (await checkHealth()) {
        _isRunning = true;
        notifyListeners();
        return true;
      }

      // Try to start the server
      // Note: This assumes the Java service is built and available
      // In production, you would package the JAR with your app
      if (kDebugMode) {
        print('[AudiverisService] Starting Audiveris server...');
      }

      // For now, we expect the server to be started manually
      // TODO: Implement automatic server startup with packaged JAR
      
      // Wait a bit and check again
      await Future.delayed(const Duration(seconds: 2));
      _isRunning = await checkHealth();
      notifyListeners();
      
      return _isRunning;
    } catch (e) {
      if (kDebugMode) {
        print('[AudiverisService] Error starting server: $e');
      }
      return false;
    }
  }

  /// Stop the Audiveris server
  Future<void> stopServer() async {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
    }
    _isRunning = false;
    notifyListeners();
  }

  /// Check if the server is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Convert a PDF or image file to MusicXML
  Future<String?> convertToMusicXml(String filePath) async {
    try {
      // Ensure server is running
      if (!_isRunning && !await startServer()) {
        throw Exception('Audiveris server is not running');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/convert');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      if (kDebugMode) {
        print('[AudiverisService] Sending file to Audiveris: $filePath');
      }

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // OMR can take a while
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          if (kDebugMode) {
            print('[AudiverisService] Conversion successful');
          }
          return jsonResponse['musicxml'] as String?;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Conversion failed');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AudiverisService] Error converting file: $e');
      }
      rethrow;
    }
  }

  /// Get conversion status by job ID
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status/$jobId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get job status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AudiverisService] Error getting job status: $e');
      }
      rethrow;
    }
  }

  /// Submit a file for async conversion (returns job ID)
  Future<String> submitConversionJob(String filePath) async {
    try {
      // Ensure server is running
      if (!_isRunning && !await startServer()) {
        throw Exception('Audiveris server is not running');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/convert/async');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['jobId'] as String;
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AudiverisService] Error submitting job: $e');
      }
      rethrow;
    }
  }

  /// Poll for job completion and return MusicXML
  Future<String?> waitForJobCompletion(String jobId, {
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final status = await getJobStatus(jobId);
      
      final state = status['status'] as String?;
      if (state == 'completed') {
        return status['musicxml'] as String?;
      } else if (state == 'failed') {
        throw Exception(status['message'] ?? 'Job failed');
      }
      
      // Still processing, wait and try again
      await Future.delayed(pollInterval);
    }
    
    throw Exception('Job timed out after ${timeout.inMinutes} minutes');
  }
}
