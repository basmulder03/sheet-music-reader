import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/models/sheet_music_document.dart';
import '../../core/services/network_request_optimizer.dart';
import 'server_discovery_service.dart';

/// Connection status
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Service for managing connection to desktop server
class MobileConnectionService extends ChangeNotifier {
  DiscoveredServer? _connectedServer;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  WebSocketChannel? _wsChannel;
  String? _errorMessage;
  final List<SheetMusicDocument> _documents = [];
  bool _isSyncing = false;
  
  // Pagination state
  int _currentPage = 0;
  int _pageSize = 20;
  bool _hasMoreDocuments = true;
  bool _isLoadingMore = false;
  int? _totalDocumentCount;
  
  // Network optimizer for debouncing
  final NetworkRequestOptimizer _optimizer = NetworkRequestOptimizer.instance;

  // Getters
  DiscoveredServer? get connectedServer => _connectedServer;
  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<SheetMusicDocument> get documents => List.unmodifiable(_documents);
  bool get isSyncing => _isSyncing;
  bool get isConnected => _status == ConnectionStatus.connected;
  bool get hasMoreDocuments => _hasMoreDocuments;
  bool get isLoadingMore => _isLoadingMore;
  int? get totalDocumentCount => _totalDocumentCount;

  /// Connect to a discovered server
  Future<bool> connect(DiscoveredServer server) async {
    if (_status == ConnectionStatus.connecting) return false;

    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      // Test connection with health check
      final response = await http
          .get(Uri.parse('${server.url}/api/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _connectedServer = server;
        _status = ConnectionStatus.connected;
        _errorMessage = null;

        // Connect WebSocket
        await _connectWebSocket();

        // Initial sync
        await syncDocuments();

        notifyListeners();
        
        if (kDebugMode) {
          print('Connected to server: ${server.url}');
        }
        
        return true;
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = 'Failed to connect: $e';
      _connectedServer = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('Connection error: $e');
      }
      
      return false;
    }
  }

  /// Disconnect from the server
  Future<void> disconnect() async {
    if (_status == ConnectionStatus.disconnected) return;

    try {
      await _wsChannel?.sink.close();
      _wsChannel = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error closing WebSocket: $e');
      }
    }

    _connectedServer = null;
    _status = ConnectionStatus.disconnected;
    _errorMessage = null;
    _documents.clear();
    notifyListeners();

    if (kDebugMode) {
      print('Disconnected from server');
    }
  }

  /// Connect to WebSocket for real-time updates
  Future<void> _connectWebSocket() async {
    if (_connectedServer == null) return;

    try {
      final wsUrl = _connectedServer!.url.replaceFirst('http', 'ws');
      _wsChannel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));

      // Listen for messages
      _wsChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message as String);
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
        },
        onDone: () {
          if (kDebugMode) {
            print('WebSocket connection closed');
          }
          // Try to reconnect if still connected
          if (_status == ConnectionStatus.connected) {
            Future.delayed(const Duration(seconds: 3), () {
              if (_status == ConnectionStatus.connected) {
                _connectWebSocket();
              }
            });
          }
        },
      );

      if (kDebugMode) {
        print('WebSocket connected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect WebSocket: $e');
      }
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(String message) {
    try {
      final data = json.decode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'welcome':
          if (kDebugMode) {
            print('Received welcome from server');
          }
          // Send sync request
          _wsChannel?.sink.add(json.encode({'type': 'sync_request'}));
          break;

        case 'pong':
          // Server responded to ping
          break;

        case 'sync_response':
          // Full document list
          final docsData = data['documents'] as List<dynamic>;
          _documents.clear();
          for (final docData in docsData) {
            try {
              _documents.add(SheetMusicDocument.fromJson(docData as Map<String, dynamic>));
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing document: $e');
              }
            }
          }
          notifyListeners();
          break;

        case 'annotation_added':
          // Handle annotation update
          if (kDebugMode) {
            print('Annotation added: ${data['documentId']}');
          }
          // Refresh that document
          final docId = data['documentId'] as String?;
          if (docId != null) {
            refreshDocument(docId);
          }
          break;

        default:
          if (kDebugMode) {
            print('Unknown WebSocket message type: $type');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling WebSocket message: $e');
      }
    }
  }

  /// Sync documents from server (loads first page) - debounced version
  void syncDocumentsDebounced() {
    _optimizer.debounce('sync_documents', () {
      syncDocuments();
    }, duration: const Duration(milliseconds: 500));
  }

  /// Sync documents from server (loads first page)
  Future<void> syncDocuments() async {
    if (!isConnected || _connectedServer == null) return;

    _isSyncing = true;
    _currentPage = 0;
    _hasMoreDocuments = true;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('${_connectedServer!.url}/api/documents?page=$_currentPage&pageSize=$_pageSize'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docsData = data['documents'] as List<dynamic>;
        
        // Get pagination info
        _totalDocumentCount = data['totalCount'] as int?;
        _hasMoreDocuments = data['hasMore'] as bool? ?? false;

        _documents.clear();
        for (final docData in docsData) {
          try {
            _documents.add(SheetMusicDocument.fromJson(docData as Map<String, dynamic>));
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing document: $e');
            }
          }
        }

        if (kDebugMode) {
          print('Synced ${_documents.length} documents (total: $_totalDocumentCount)');
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sync error: $e');
      }
      _errorMessage = 'Failed to sync: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Load next page of documents
  Future<void> loadNextPage() async {
    if (!isConnected || 
        _connectedServer == null || 
        _isLoadingMore || 
        !_hasMoreDocuments) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final response = await http
          .get(Uri.parse('${_connectedServer!.url}/api/documents?page=$_currentPage&pageSize=$_pageSize'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docsData = data['documents'] as List<dynamic>;
        
        // Update pagination info
        _totalDocumentCount = data['totalCount'] as int?;
        _hasMoreDocuments = data['hasMore'] as bool? ?? false;

        // Add new documents
        for (final docData in docsData) {
          try {
            _documents.add(SheetMusicDocument.fromJson(docData as Map<String, dynamic>));
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing document: $e');
            }
          }
        }

        if (kDebugMode) {
          print('Loaded page $_currentPage: ${_documents.length}/$_totalDocumentCount documents');
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading next page: $e');
      }
      _errorMessage = 'Failed to load more: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Get MusicXML content for a document
  Future<String?> getMusicXml(String documentId) async {
    if (!isConnected || _connectedServer == null) return null;

    try {
      final response = await http
          .get(Uri.parse('${_connectedServer!.url}/api/documents/$documentId/musicxml'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching MusicXML: $e');
      }
      return null;
    }
  }

  /// Get annotations for a document
  Future<List<Annotation>> getAnnotations(String documentId) async {
    if (!isConnected || _connectedServer == null) return [];

    try {
      final response = await http
          .get(Uri.parse('${_connectedServer!.url}/api/documents/$documentId/annotations'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final annotsData = data['annotations'] as List<dynamic>;

        return annotsData
            .map((a) => Annotation.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching annotations: $e');
      }
      return [];
    }
  }

  /// Add an annotation
  Future<bool> addAnnotation(String documentId, Annotation annotation) async {
    if (!isConnected || _connectedServer == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${_connectedServer!.url}/api/documents/$documentId/annotations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(annotation.toJson()),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding annotation: $e');
      }
      return false;
    }
  }

  /// Search documents (with pagination support)
  Future<List<SheetMusicDocument>> search(String query, {int page = 0, int pageSize = 20}) async {
    if (!isConnected || _connectedServer == null) return [];

    try {
      final response = await http
          .get(Uri.parse(
            '${_connectedServer!.url}/api/search?q=${Uri.encodeComponent(query)}&page=$page&pageSize=$pageSize',
          ))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final resultsData = data['results'] as List<dynamic>;

        return resultsData
            .map((d) => SheetMusicDocument.fromJson(d as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching: $e');
      }
      return [];
    }
  }

  /// Refresh a specific document (debounced)
  void refreshDocumentDebounced(String documentId) {
    _optimizer.debounce('refresh_$documentId', () {
      refreshDocument(documentId);
    });
  }

  /// Refresh a specific document
  Future<void> refreshDocument(String documentId) async {
    if (!isConnected || _connectedServer == null) return;

    try {
      final response = await http
          .get(Uri.parse('${_connectedServer!.url}/api/documents/$documentId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final docData = json.decode(response.body) as Map<String, dynamic>;
        final newDoc = SheetMusicDocument.fromJson(docData);

        // Update in list
        final index = _documents.indexWhere((d) => d.id == documentId);
        if (index != -1) {
          _documents[index] = newDoc;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing document: $e');
      }
    }
  }

  /// Send ping to keep connection alive
  void sendPing() {
    if (isConnected && _wsChannel != null) {
      try {
        _wsChannel!.sink.add(json.encode({'type': 'ping'}));
      } catch (e) {
        if (kDebugMode) {
          print('Error sending ping: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
