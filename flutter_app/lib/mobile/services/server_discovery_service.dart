import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:http/http.dart' as http;

/// Discovered server information
class DiscoveredServer {
  final String name;
  final String address;
  final int port;
  final DateTime discoveredAt;

  DiscoveredServer({
    required this.name,
    required this.address,
    required this.port,
    required this.discoveredAt,
  });

  String get url => 'http://$address:$port';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredServer &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          port == other.port;

  @override
  int get hashCode => address.hashCode ^ port.hashCode;
}

/// Service for discovering desktop servers on the local network
class ServerDiscoveryService extends ChangeNotifier {
  static const String _serviceType = '_sheet-music-reader._tcp';
  static const int _defaultPort = 8080;
  
  MDnsClient? _mdnsClient;
  bool _isDiscovering = false;
  final List<DiscoveredServer> _discoveredServers = [];
  Timer? _discoveryTimer;

  bool get isDiscovering => _isDiscovering;
  List<DiscoveredServer> get discoveredServers => List.unmodifiable(_discoveredServers);

  /// Start discovering servers on the local network
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    _isDiscovering = true;
    _discoveredServers.clear();
    notifyListeners();

    try {
      // Start mDNS discovery
      await _startMdnsDiscovery();
      
      // Also scan common local network ranges as fallback
      _startNetworkScan();
    } catch (e) {
      if (kDebugMode) {
        print('Error starting discovery: $e');
      }
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Stop discovering servers
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;

    _isDiscovering = false;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;

    try {
      _mdnsClient?.stop();
      _mdnsClient = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping discovery: $e');
      }
    }

    notifyListeners();
  }

  /// Start mDNS service discovery
  Future<void> _startMdnsDiscovery() async {
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();

      // Look for our service type
      await for (final PtrResourceRecord ptr in _mdnsClient!
          .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(_serviceType))) {
        
        // For each service instance, look up its details
        await for (final SrvResourceRecord srv in _mdnsClient!
            .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName))) {
          
          // Get the IP address
          await for (final IPAddressResourceRecord ip in _mdnsClient!
              .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target))) {
            
            final server = DiscoveredServer(
              name: ptr.domainName,
              address: ip.address.address,
              port: srv.port,
              discoveredAt: DateTime.now(),
            );

            // Verify server is reachable
            if (await _verifyServer(server)) {
              _addDiscoveredServer(server);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('mDNS discovery error: $e');
      }
    }
  }

  /// Scan common local network IP ranges for servers
  void _startNetworkScan() {
    _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isDiscovering) {
        timer.cancel();
        return;
      }

      try {
        // Get local IP address to determine network range
        final localAddress = await _getLocalIpAddress();
        if (localAddress == null) return;

        // Scan a few IPs around the local address
        final parts = localAddress.split('.');
        if (parts.length != 4) return;

        final baseIp = '${parts[0]}.${parts[1]}.${parts[2]}';
        final localLastOctet = int.tryParse(parts[3]) ?? 0;

        // Scan 10 IPs before and after current IP
        for (int i = localLastOctet - 10; i <= localLastOctet + 10; i++) {
          if (i <= 0 || i >= 255) continue;
          if (i == localLastOctet) continue; // Skip self

          final testIp = '$baseIp.$i';
          final server = DiscoveredServer(
            name: 'Desktop Server',
            address: testIp,
            port: _defaultPort,
            discoveredAt: DateTime.now(),
          );

          // Verify in background
          _verifyServer(server).then((isValid) {
            if (isValid) {
              _addDiscoveredServer(server);
            }
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Network scan error: $e');
        }
      }
    });
  }

  /// Verify that a server is actually running at the given address
  Future<bool> _verifyServer(DiscoveredServer server) async {
    try {
      final response = await http
          .get(Uri.parse('${server.url}/api/health'))
          .timeout(const Duration(seconds: 2));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Add a discovered server to the list (avoid duplicates)
  void _addDiscoveredServer(DiscoveredServer server) {
    if (!_discoveredServers.contains(server)) {
      _discoveredServers.add(server);
      notifyListeners();
      
      if (kDebugMode) {
        print('Discovered server: ${server.address}:${server.port}');
      }
    }
  }

  /// Get the local IP address of this device
  Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Skip loopback
          if (addr.address == '127.0.0.1') continue;
          // Prefer private network addresses
          if (addr.address.startsWith('192.168') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }

      // Return first non-loopback address if no private network found
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.address != '127.0.0.1') {
            return addr.address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get local IP: $e');
      }
    }
    return null;
  }

  /// Manually add a server by address
  Future<DiscoveredServer?> addManualServer(String address, int port) async {
    final server = DiscoveredServer(
      name: 'Manual Server',
      address: address,
      port: port,
      discoveredAt: DateTime.now(),
    );

    // Verify it's valid
    if (await _verifyServer(server)) {
      _addDiscoveredServer(server);
      return server;
    }

    return null;
  }

  /// Remove a server from the discovered list
  void removeServer(DiscoveredServer server) {
    _discoveredServers.remove(server);
    notifyListeners();
  }

  /// Clear all discovered servers
  void clearServers() {
    _discoveredServers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopDiscovery();
    super.dispose();
  }
}
