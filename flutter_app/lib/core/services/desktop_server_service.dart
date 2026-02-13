import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart' show Color, Offset, Size;
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/sheet_music_document.dart';
import 'library_service.dart';

/// Service for running a local HTTP/WebSocket server for mobile device sync
class DesktopServerService extends ChangeNotifier {
  final LibraryService _libraryService;
  
  HttpServer? _server;
  MDnsClient? _mdnsClient;
  final List<WebSocketChannel> _wsConnections = [];
  final Map<WebSocketChannel, Set<String>> _subscriptions = {}; // Track document subscriptions
  final Map<WebSocketChannel, DateTime> _lastPingTime = {}; // Track ping times
  bool _isRunning = false;
  int _port = 8080;
  String? _serverAddress;
  
  // Message batching for WebSocket
  final Map<WebSocketChannel, List<Map<String, dynamic>>> _pendingMessages = {};
  Timer? _batchTimer;
  
  DesktopServerService(this._libraryService);

  // Getters
  bool get isRunning => _isRunning;
  int get port => _port;
  String? get serverAddress => _serverAddress;
  int get connectedClients => _wsConnections.length;

  /// Start the server
  Future<void> startServer() async {
    if (_isRunning) return;

    try {
      // Get local IP address
      _serverAddress = await _getLocalIpAddress();
      
      // Create and configure router
      final router = _createRouter();
      
      // Add middleware
      final handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);

      // Start HTTP server
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        _port,
      );

      _isRunning = true;
      
      // Start message batching timer
      _startBatchTimer();
      
      if (kDebugMode) {
        print('Server running on http://$_serverAddress:$_port');
      }

      // Start mDNS advertisement
      await _startMdnsAdvertisement();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start server: $e');
      }
      rethrow;
    }
  }

  /// Stop the server
  Future<void> stopServer() async {
    if (!_isRunning) return;

    try {
      // Stop batch timer
      _batchTimer?.cancel();
      _batchTimer = null;
      
      // Close all WebSocket connections
      for (final ws in _wsConnections) {
        await ws.sink.close();
      }
      _wsConnections.clear();
      _subscriptions.clear();
      _lastPingTime.clear();
      _pendingMessages.clear();

      // Stop mDNS
      await _stopMdnsAdvertisement();

      // Stop HTTP server
      await _server?.close(force: true);
      _server = null;

      _isRunning = false;
      _serverAddress = null;
      
      if (kDebugMode) {
        print('Server stopped');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping server: $e');
      }
      rethrow;
    }
  }

  /// Create router with all API endpoints
  Router _createRouter() {
    final router = Router();

    // Health check
    router.get('/api/health', (shelf.Request request) {
      return shelf.Response.ok(
        json.encode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Get all documents (with pagination support)
    router.get('/api/documents', (shelf.Request request) async {
      final pageParam = request.url.queryParameters['page'];
      final pageSizeParam = request.url.queryParameters['pageSize'];
      
      // If pagination parameters are provided, use paginated response
      if (pageParam != null && pageSizeParam != null) {
        final page = int.tryParse(pageParam) ?? 0;
        final pageSize = int.tryParse(pageSizeParam) ?? 20;
        
        final documents = await _libraryService._databaseService.getDocumentsPage(
          page: page,
          pageSize: pageSize,
        );
        final totalCount = await _libraryService._databaseService.getDocumentCount();
        
        return shelf.Response.ok(
          json.encode({
            'documents': documents.map((d) => _documentToJson(d)).toList(),
            'page': page,
            'pageSize': pageSize,
            'totalCount': totalCount,
            'hasMore': (page + 1) * pageSize < totalCount,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Default: return all loaded documents
      final documents = _libraryService.documents;
      return shelf.Response.ok(
        json.encode({
          'documents': documents.map((d) => _documentToJson(d)).toList(),
          'totalCount': _libraryService.totalDocumentCount,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Get specific document
    router.get('/api/documents/<id>', (shelf.Request request, String id) async {
      final document = _libraryService.documents
          .where((d) => d.id == id)
          .firstOrNull;
      
      if (document == null) {
        return shelf.Response.notFound(
          json.encode({'error': 'Document not found'}),
        );
      }

      return shelf.Response.ok(
        json.encode(_documentToJson(document)),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Get document MusicXML file
    router.get('/api/documents/<id>/musicxml', (shelf.Request request, String id) async {
      final document = _libraryService.documents
          .where((d) => d.id == id)
          .firstOrNull;
      
      if (document == null) {
        return shelf.Response.notFound(
          json.encode({'error': 'Document not found'}),
        );
      }

      try {
        final file = File(document.musicXmlPath);
        if (!await file.exists()) {
          return shelf.Response.notFound(
            json.encode({'error': 'MusicXML file not found'}),
          );
        }

        final content = await file.readAsString();
        return shelf.Response.ok(
          content,
          headers: {'Content-Type': 'application/xml'},
        );
      } catch (e) {
        return shelf.Response.internalServerError(
          body: json.encode({'error': 'Failed to read MusicXML file: $e'}),
        );
      }
    });

    // Get document annotations
    router.get('/api/documents/<id>/annotations', (shelf.Request request, String id) async {
      final annotations = _libraryService.getAnnotations(id);
      return shelf.Response.ok(
        json.encode({
          'annotations': annotations.map((a) => _annotationToJson(a)).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Add annotation
    router.post('/api/documents/<id>/annotations', (shelf.Request request, String id) async {
      try {
        final payload = await request.readAsString();
        final data = json.decode(payload) as Map<String, dynamic>;
        
        final annotation = Annotation(
          id: data['id'] as String,
          documentId: id,
          page: data['page'] as int,
          type: AnnotationType.values.firstWhere(
            (e) => e.toString() == data['type'],
            orElse: () => AnnotationType.note,
          ),
          text: data['text'] as String?,
          color: data['color'] != null ? Color(data['color'] as int) : null,
          position: Offset(
            (data['position']['dx'] as num).toDouble(),
            (data['position']['dy'] as num).toDouble(),
          ),
          size: data['size'] != null 
              ? Size(
                  (data['size']['width'] as num).toDouble(),
                  (data['size']['height'] as num).toDouble(),
                )
              : null,
          createdAt: DateTime.parse(data['createdAt'] as String),
        );

        await _libraryService.addAnnotation(id, annotation);
        
        // Broadcast to WebSocket clients
        _broadcastUpdate({
          'type': 'annotation_added',
          'documentId': id,
          'annotation': _annotationToJson(annotation),
        });

        return shelf.Response.ok(
          json.encode({'success': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return shelf.Response.internalServerError(
          body: json.encode({'error': 'Failed to add annotation: $e'}),
        );
      }
    });

    // WebSocket endpoint for real-time sync
    router.get('/ws', webSocketHandler((WebSocketChannel webSocket) {
      _handleWebSocketConnection(webSocket);
    }));

    // Search documents (with pagination support)
    router.get('/api/search', (shelf.Request request) async {
      final query = request.url.queryParameters['q'] ?? '';
      final pageParam = request.url.queryParameters['page'];
      final pageSizeParam = request.url.queryParameters['pageSize'];
      
      // If pagination parameters are provided, use paginated search
      if (pageParam != null && pageSizeParam != null) {
        final page = int.tryParse(pageParam) ?? 0;
        final pageSize = int.tryParse(pageSizeParam) ?? 20;
        
        final results = await _libraryService._databaseService.searchDocumentsPage(
          query: query,
          page: page,
          pageSize: pageSize,
        );
        final totalCount = await _libraryService._databaseService.getSearchCount(query);
        
        return shelf.Response.ok(
          json.encode({
            'results': results.map((d) => _documentToJson(d)).toList(),
            'page': page,
            'pageSize': pageSize,
            'totalCount': totalCount,
            'hasMore': (page + 1) * pageSize < totalCount,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Default: return all search results from memory
      final results = _libraryService.search(query);
      return shelf.Response.ok(
        json.encode({
          'results': results.map((d) => _documentToJson(d)).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Get all tags
    router.get('/api/tags', (shelf.Request request) {
      final tags = _libraryService.getAllTags().toList();
      return shelf.Response.ok(
        json.encode({'tags': tags}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    return router;
  }

  /// Handle WebSocket connections
  void _handleWebSocketConnection(WebSocketChannel webSocket) {
    // Add to connections list
    _wsConnections.add(webSocket);
    _subscriptions[webSocket] = {};
    _lastPingTime[webSocket] = DateTime.now();
    _pendingMessages[webSocket] = [];
    notifyListeners();

    if (kDebugMode) {
      print('WebSocket client connected. Total connections: ${_wsConnections.length}');
    }

    // Send welcome message with server capabilities
    _queueMessage(webSocket, {
      'type': 'welcome',
      'message': 'Connected to Sheet Music Reader Desktop',
      'serverTime': DateTime.now().toIso8601String(),
      'capabilities': {
        'pagination': true,
        'compression': false, // Can be enabled with gzip if needed
        'batching': true,
      },
    });

    // Listen for incoming messages
    webSocket.stream.listen(
      (message) {
        try {
          final data = json.decode(message as String) as Map<String, dynamic>;
          _handleWebSocketMessage(webSocket, data);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing WebSocket message: $e');
          }
          _queueMessage(webSocket, {
            'type': 'error',
            'message': 'Invalid message format',
          });
        }
      },
      onDone: () {
        _cleanupWebSocketConnection(webSocket);
        if (kDebugMode) {
          print('WebSocket client disconnected. Total connections: ${_wsConnections.length}');
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('WebSocket error: $error');
        }
        _cleanupWebSocketConnection(webSocket);
      },
    );
  }

  /// Cleanup WebSocket connection
  void _cleanupWebSocketConnection(WebSocketChannel webSocket) {
    _wsConnections.remove(webSocket);
    _subscriptions.remove(webSocket);
    _lastPingTime.remove(webSocket);
    _pendingMessages.remove(webSocket);
    notifyListeners();
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(WebSocketChannel webSocket, Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    _lastPingTime[webSocket] = DateTime.now();

    switch (messageType) {
      case 'ping':
        // Respond to ping with pong (lightweight response)
        _queueMessage(webSocket, {
          'type': 'pong',
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;

      case 'subscribe':
        // Client wants to subscribe to updates for specific documents
        final documentIds = data['documentIds'] as List<dynamic>?;
        if (documentIds != null) {
          _subscriptions[webSocket]?.addAll(
            documentIds.map((id) => id.toString()),
          );
          _queueMessage(webSocket, {
            'type': 'subscribed',
            'documentIds': documentIds,
          });
          
          if (kDebugMode) {
            print('Client subscribed to ${documentIds.length} documents');
          }
        }
        break;

      case 'unsubscribe':
        // Client wants to unsubscribe from specific documents
        final documentIds = data['documentIds'] as List<dynamic>?;
        if (documentIds != null) {
          for (final id in documentIds) {
            _subscriptions[webSocket]?.remove(id.toString());
          }
          _queueMessage(webSocket, {
            'type': 'unsubscribed',
            'documentIds': documentIds,
          });
        }
        break;

      case 'sync_request':
        // Client requests sync - use pagination to reduce bandwidth
        final page = data['page'] as int? ?? 0;
        final pageSize = data['pageSize'] as int? ?? 20;
        final includeMetadataOnly = data['metadataOnly'] as bool? ?? false;
        
        _handleSyncRequest(webSocket, page, pageSize, includeMetadataOnly);
        break;

      case 'document_metadata_request':
        // Request only metadata for specific documents (lightweight)
        final documentIds = data['documentIds'] as List<dynamic>?;
        if (documentIds != null) {
          _handleMetadataRequest(webSocket, documentIds.map((e) => e.toString()).toList());
        }
        break;

      default:
        _queueMessage(webSocket, {
          'type': 'error',
          'message': 'Unknown message type: $messageType',
        });
    }
  }

  /// Handle sync request with pagination
  void _handleSyncRequest(
    WebSocketChannel webSocket,
    int page,
    int pageSize,
    bool metadataOnly,
  ) async {
    try {
      final docs = await _libraryService._databaseService.getDocumentsPage(
        page: page,
        pageSize: pageSize,
      );
      final totalCount = await _libraryService._databaseService.getDocumentCount();
      
      final docData = docs.map((d) {
        if (metadataOnly) {
          // Send only lightweight metadata
          return {
            'id': d.id,
            'title': d.title,
            'composer': d.composer,
            'modifiedAt': d.modifiedAt.toIso8601String(),
          };
        } else {
          return _documentToJson(d);
        }
      }).toList();

      _queueMessage(webSocket, {
        'type': 'sync_response',
        'documents': docData,
        'page': page,
        'pageSize': pageSize,
        'totalCount': totalCount,
        'hasMore': (page + 1) * pageSize < totalCount,
        'metadataOnly': metadataOnly,
      });
      
      if (kDebugMode) {
        print('Sent sync response: page $page, ${docs.length} documents');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling sync request: $e');
      }
      _queueMessage(webSocket, {
        'type': 'error',
        'message': 'Failed to sync documents',
      });
    }
  }

  /// Handle metadata-only request for specific documents
  void _handleMetadataRequest(WebSocketChannel webSocket, List<String> documentIds) {
    final metadata = documentIds.map((id) {
      final doc = _libraryService.documents.where((d) => d.id == id).firstOrNull;
      if (doc != null) {
        return {
          'id': doc.id,
          'title': doc.title,
          'composer': doc.composer,
          'modifiedAt': doc.modifiedAt.toIso8601String(),
        };
      }
      return null;
    }).whereType<Map<String, dynamic>>().toList();

    _queueMessage(webSocket, {
      'type': 'metadata_response',
      'metadata': metadata,
    });
  }

  /// Queue message for batching
  void _queueMessage(WebSocketChannel webSocket, Map<String, dynamic> message) {
    if (!_pendingMessages.containsKey(webSocket)) {
      _pendingMessages[webSocket] = [];
    }
    _pendingMessages[webSocket]!.add(message);
    
    // For high-priority messages, flush immediately
    if (message['type'] == 'pong' || message['type'] == 'error') {
      _flushMessages(webSocket);
    }
  }

  /// Start timer for batching messages
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _flushAllMessages();
    });
  }

  /// Flush pending messages for a specific connection
  void _flushMessages(WebSocketChannel webSocket) {
    final pending = _pendingMessages[webSocket];
    if (pending == null || pending.isEmpty) return;

    try {
      if (pending.length == 1) {
        // Single message - send directly
        webSocket.sink.add(json.encode(pending.first));
      } else {
        // Multiple messages - send as batch
        webSocket.sink.add(json.encode({
          'type': 'batch',
          'messages': pending,
        }));
      }
      pending.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error flushing messages: $e');
      }
      _cleanupWebSocketConnection(webSocket);
    }
  }

  /// Flush all pending messages for all connections
  void _flushAllMessages() {
    for (final ws in _wsConnections.toList()) {
      _flushMessages(ws);
    }
  }

  /// CORS middleware
  shelf.Middleware _corsMiddleware() {
    return shelf.createMiddleware(
      requestHandler: (shelf.Request request) {
        if (request.method == 'OPTIONS') {
          return shelf.Response.ok('', headers: _corsHeaders);
        }
        return null;
      },
      responseHandler: (shelf.Response response) {
        return response.change(headers: _corsHeaders);
      },
    );
  }

  final _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
  };

  /// Start mDNS advertisement
  Future<void> _startMdnsAdvertisement() async {
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();

      // Note: The multicast_dns package has limited support for service registration.
      // For full mDNS/Bonjour service advertisement, platform-specific implementations
      // would be needed (Avahi on Linux, Bonjour on Windows/macOS).
      // 
      // For now, mobile clients can:
      // 1. Use mDNS discovery to find the service type: _sheet-music-reader._tcp
      // 2. Manually enter the server address shown in the UI
      // 
      // Service information that would be advertised:
      // - Service Type: _sheet-music-reader._tcp
      // - Port: $_port
      // - TXT Records:
      //   - version=0.1.0
      //   - api=/api
      //   - ws=/ws
      
      if (kDebugMode) {
        print('mDNS client started');
        print('Service: _sheet-music-reader._tcp.local');
        print('Port: $_port');
        print('For full service discovery, mobile clients should scan for $_serverAddress:$_port');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start mDNS: $e');
      }
    }
  }

  /// Stop mDNS advertisement
  Future<void> _stopMdnsAdvertisement() async {
    try {
      _mdnsClient?.stop();
      _mdnsClient = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping mDNS: $e');
      }
    }
  }

  /// Get local IP address
  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Skip loopback
          if (addr.address == '127.0.0.1') continue;
          // Prefer addresses starting with 192.168 or 10.
          if (addr.address.startsWith('192.168') || 
              addr.address.startsWith('10.')) {
            return addr.address;
          }
        }
      }

      // Fallback to first non-loopback address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.address != '127.0.0.1') {
            return addr.address;
          }
        }
      }

      return 'localhost';
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get IP address: $e');
      }
      return 'localhost';
    }
  }

  /// Broadcast update to all WebSocket clients (with subscription filtering)
  void _broadcastUpdate(Map<String, dynamic> message) {
    final documentId = message['documentId'] as String?;
    final data = json.encode(message);
    final closedConnections = <WebSocketChannel>[];

    for (final ws in _wsConnections) {
      try {
        // If document-specific update, only send to subscribed clients
        if (documentId != null) {
          final subscriptions = _subscriptions[ws];
          if (subscriptions == null || !subscriptions.contains(documentId)) {
            continue; // Skip this client
          }
        }
        
        // Queue message instead of sending immediately
        _queueMessage(ws, message);
      } catch (e) {
        closedConnections.add(ws);
      }
    }

    // Remove closed connections
    for (final ws in closedConnections) {
      _cleanupWebSocketConnection(ws);
    }

    if (closedConnections.isNotEmpty) {
      notifyListeners();
    }
    
    // Flush messages immediately for broadcasts
    _flushAllMessages();
  }

  /// Convert document to JSON
  Map<String, dynamic> _documentToJson(SheetMusicDocument doc) {
    return {
      'id': doc.id,
      'title': doc.title,
      'composer': doc.composer,
      'arranger': doc.arranger,
      'musicXmlPath': doc.musicXmlPath,
      'sourcePath': doc.sourcePath,
      'tags': doc.tags,
      'metadata': {
        'pageCount': doc.metadata.pageCount,
        'timeSignature': doc.metadata.timeSignature,
        'keySignature': doc.metadata.keySignature,
        'tempo': doc.metadata.tempo,
        'instruments': doc.metadata.instruments,
        'measureCount': doc.metadata.measureCount,
      },
      'createdAt': doc.createdAt.toIso8601String(),
      'modifiedAt': doc.modifiedAt.toIso8601String(),
    };
  }

  /// Convert annotation to JSON
  Map<String, dynamic> _annotationToJson(Annotation annotation) {
    return {
      'id': annotation.id,
      'documentId': annotation.documentId,
      'page': annotation.page,
      'type': annotation.type.toString(),
      'text': annotation.text,
      'position': {
        'dx': annotation.position.dx,
        'dy': annotation.position.dy,
      },
      'size': annotation.size != null
          ? {
              'width': annotation.size!.width,
              'height': annotation.size!.height,
            }
          : null,
      // ignore: deprecated_member_use
      'color': annotation.color?.value,
      'createdAt': annotation.createdAt.toIso8601String(),
    };
  }

  @override
  void dispose() {
    stopServer();
    super.dispose();
  }
}
