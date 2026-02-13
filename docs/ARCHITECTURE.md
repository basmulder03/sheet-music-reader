# Architecture Specification

**Version:** 1.0  
**Last Updated:** February 13, 2026  
**Related:** [SPECIFICATION.md](./SPECIFICATION.md)

## Table of Contents

1. [Overview](#overview)
2. [Architectural Principles](#architectural-principles)
3. [System Architecture](#system-architecture)
4. [Component Architecture](#component-architecture)
5. [Service Layer](#service-layer)
6. [Data Flow](#data-flow)
7. [Technology Choices](#technology-choices)

---

## Overview

The Sheet Music Reader follows a **layered architecture** with clear separation of concerns. The application is built using Flutter for maximum code reuse across desktop and mobile platforms, with a client-server model for synchronization.

### Architecture Style

- **Primary**: Layered Architecture
- **Communication**: Client-Server (Desktop as Server)
- **State Management**: Provider Pattern
- **Data Access**: Repository Pattern via Services

---

## Architectural Principles

### 1. Code Reuse

**Goal**: Maximize shared code between desktop and mobile platforms

**Implementation**:
- **Shared Core** (`lib/core/`): 100% code reuse for models, services, and business logic
- **Platform UI** (`lib/desktop/`, `lib/mobile/`): Platform-specific UI implementations
- **Shared Widgets** (`lib/shared/`): Reusable UI components

**Benefit**: ~70-80% code reuse across platforms

### 2. Separation of Concerns

**Layers**:
```
┌─────────────────────────────────────┐
│       Presentation Layer             │  UI widgets, screens
├─────────────────────────────────────┤
│       Application Layer              │  Services, business logic
├─────────────────────────────────────┤
│       Data Layer                     │  Models, repositories
├─────────────────────────────────────┤
│       Infrastructure Layer           │  Database, network, file I/O
└─────────────────────────────────────┘
```

### 3. Dependency Injection

**Pattern**: Constructor injection via Provider

**Example**:
```dart
MultiProvider(
  providers: [
    Provider(create: (_) => DatabaseService()),
    Provider(create: (_) => MusicXmlService()),
    ChangeNotifierProvider(create: (_) => LibraryService()),
  ],
  child: MyApp(),
)
```

### 4. Reactive Programming

**Pattern**: ChangeNotifier + Provider for state management

**Flow**: State Change → notify() → Consumer rebuilds → UI updates

### 5. Offline-First

**Strategy**: Local-first with optional sync

- All data stored locally in SQLite
- Desktop is authoritative source
- Mobile caches data for offline access
- Sync happens when connected

---

## System Architecture

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        DESKTOP APP                            │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                  PRESENTATION LAYER                     │  │
│  │  • HomeScreen  • ViewerScreen  • SettingsScreen        │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ↕                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                  APPLICATION LAYER                      │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │           CORE SERVICES (Shared)                 │  │  │
│  │  │  • LibraryService      • MusicXmlService         │  │  │
│  │  │  • DatabaseService     • MemoryManagerService    │  │  │
│  │  │  • ImageCacheService   • RenderingProfiler       │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │         DESKTOP SERVICES (Platform)              │  │  │
│  │  │  • DesktopServerService  • OmrService            │  │  │
│  │  │  • MdnsService           • FilePickerService     │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ↕                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                     DATA LAYER                          │  │
│  │  • SheetMusicDocument  • Annotation  • MusicXmlScore   │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ↕                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                 INFRASTRUCTURE LAYER                    │  │
│  │  • SQLite Database  • File System  • HTTP Server       │  │
│  │  • WebSocket Server • mDNS         • Audiveris Process │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                              ↕
                  HTTP/WebSocket over Local Network
                              ↕
┌──────────────────────────────────────────────────────────────┐
│                         MOBILE APP                            │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                  PRESENTATION LAYER                     │  │
│  │  • ServerListScreen  • DocumentListScreen              │  │
│  │  • DocumentViewerScreen  • AnnotationEditor            │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ↕                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                  APPLICATION LAYER                      │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │           CORE SERVICES (Shared)                 │  │  │
│  │  │  • MusicXmlService     • MemoryManagerService    │  │  │
│  │  │  • ImageCacheService   • NetworkOptimizer        │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │          MOBILE SERVICES (Platform)              │  │  │
│  │  │  • ServerDiscoveryService                        │  │  │
│  │  │  • MobileConnectionService                       │  │  │
│  │  │  • OfflineCacheService                           │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ↕                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                     DATA LAYER                          │  │
│  │  • SheetMusicDocument  • Annotation  • MusicXmlScore   │  │
│  │  • ServerInfo (mobile-specific)                         │  │
│  └────────────────────────────────────────────────────────┘  │
│                           ↕                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                 INFRASTRUCTURE LAYER                    │  │
│  │  • Local Cache (SharedPreferences)                      │  │
│  │  • HTTP Client  • WebSocket Client  • mDNS Client       │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### Desktop Application Structure

```
flutter_app/lib/
├── main.dart                    # App entry point
├── core/                        # Shared across platforms
│   ├── models/                  # Data models
│   │   ├── musicxml_model.dart
│   │   └── sheet_music_document.dart
│   └── services/                # Business logic
│       ├── database_service.dart
│       ├── library_service.dart
│       ├── musicxml_service.dart
│       ├── memory_manager_service.dart
│       ├── image_cache_service.dart
│       ├── network_request_optimizer.dart
│       └── rendering_profiler.dart
├── desktop/                     # Desktop-specific
│   ├── screens/                 # Desktop UI screens
│   │   ├── desktop_home_screen.dart
│   │   └── desktop_viewer_screen.dart
│   ├── widgets/                 # Desktop UI widgets
│   │   ├── document_list.dart
│   │   └── music_sheet_view.dart
│   └── services/                # Desktop services
│       ├── desktop_server_service.dart
│       └── omr_service.dart
├── mobile/                      # Mobile-specific
│   ├── screens/
│   │   ├── server_list_screen.dart
│   │   ├── mobile_home_screen.dart
│   │   └── mobile_document_viewer_screen.dart
│   ├── widgets/
│   │   ├── server_card.dart
│   │   └── touch_gesture_handler.dart
│   └── services/
│       ├── server_discovery_service.dart
│       └── mobile_connection_service.dart
└── shared/                      # Shared UI components
    ├── theme/
    │   └── app_theme.dart
    └── widgets/
        └── cached_image.dart
```

### Component Responsibilities

#### Core Layer (Shared)

**Models** (`core/models/`):
- Data classes with immutable properties
- Factory constructors for parsing (XML, JSON, database)
- No business logic

**Services** (`core/services/`):
- Business logic and data manipulation
- State management (ChangeNotifier)
- Platform-agnostic implementations

#### Platform Layers

**Desktop** (`desktop/`):
- Full feature set: OMR, library management, server
- Large screen optimizations
- Keyboard/mouse interactions

**Mobile** (`mobile/`):
- Viewer-focused feature set
- Touch gesture support
- Smaller screen optimizations
- Offline capability

---

## Service Layer

### Core Services (Shared)

#### 1. DatabaseService

**Responsibility**: SQLite database operations

**Location**: `lib/core/services/database_service.dart`

**Methods**:
```dart
class DatabaseService {
  // Documents
  Future<List<SheetMusicDocument>> getDocumentsPage({int page, int pageSize});
  Future<int> getDocumentCount();
  Future<void> saveDocument(SheetMusicDocument doc);
  Future<void> deleteDocument(String id);
  
  // Search
  Future<List<SheetMusicDocument>> searchDocumentsPage({String query, int page, int pageSize});
  Future<int> getSearchCount(String query);
  
  // Annotations
  Future<List<Annotation>> getAnnotations(String documentId);
  Future<void> saveAnnotation(Annotation annotation);
  Future<void> deleteAnnotation(String id);
  
  // Optimization
  Future<void> optimizeDatabase();
}
```

**Dependencies**: sqflite, path

**Thread Safety**: All methods are async and use SQLite's built-in locking

#### 2. LibraryService

**Responsibility**: Document library management, business logic layer over DatabaseService

**Location**: `lib/core/services/library_service.dart`

**Methods**:
```dart
class LibraryService extends ChangeNotifier {
  // Document management
  Future<void> addDocument(SheetMusicDocument doc);
  Future<void> updateDocument(String id, {DateTime? modifiedDate});
  Future<void> deleteDocument(String id);
  
  // Pagination
  Future<void> loadFirstPage();
  Future<void> loadNextPage();
  void setPageSize(int size);
  
  // Annotations
  Future<void> addAnnotation(String docId, Annotation annotation);
  List<Annotation> getAnnotations(String docId);
  
  // State
  List<SheetMusicDocument> get documents;
  bool get hasMorePages;
  int? get totalDocumentCount;
}
```

**State**: Maintains in-memory cache of loaded documents, notifies listeners on changes

#### 3. MusicXmlService

**Responsibility**: Parse and cache MusicXML documents

**Location**: `lib/core/services/musicxml_service.dart`

**Methods**:
```dart
class MusicXmlService {
  // Parsing
  Future<MusicXmlScore?> parseMusicXml(String xmlContent);
  Future<MusicXmlScore?> parseFile(String filePath);
  
  // Caching
  MusicXmlScore? getCached(String key);
  void clearCache();
  Map<String, dynamic> getCacheStatistics();
}
```

**Optimizations**:
- LRU cache (50MB max, 20 entries max)
- Isolate-based parsing for large files (>100KB)
- Size estimation for memory management

#### 4. MemoryManagerService

**Responsibility**: Manage memory usage for loaded documents

**Location**: `lib/core/services/memory_manager_service.dart`

**Limits**:
- Max memory: 100MB
- Warning threshold: 75MB
- Max cached documents: 10
- Inactive timeout: 5 minutes

**Methods**:
```dart
class MemoryManagerService {
  Future<MusicXmlScore?> loadDocument(String id, Future<MusicXmlScore?> Function() loader);
  MusicXmlScore? getDocument(String id);
  void unloadDocument(String id);
  void unloadAll();
  void cleanupInactive();
  Map<String, dynamic> getStatistics();
}
```

**Eviction Strategy**: LRU (Least Recently Used)

#### 5. ImageCacheService

**Responsibility**: Cache images for thumbnails and sheet music

**Location**: `lib/core/services/image_cache_service.dart`

**Configuration**:
- Memory cache: 50MB
- Disk cache: 200MB
- Cache expiry: 30 days

**Methods**:
```dart
class ImageCacheService {
  Future<void> initialize();
  Future<Uint8List?> get(String source, {String? variant});
  Future<void> put(String source, Uint8List data, {String? variant});
  Future<void> clearAll();
  Map<String, dynamic> getStatistics();
}
```

### Desktop Services

#### 6. DesktopServerService

**Responsibility**: HTTP/WebSocket server for mobile clients

**Location**: `lib/core/services/desktop_server_service.dart`

**Endpoints**: See [API_SPECIFICATION.md](./API_SPECIFICATION.md)

**Features**:
- REST API for document access
- WebSocket for real-time updates
- Message batching (100ms intervals)
- Subscription-based filtering

#### 7. OmrService

**Responsibility**: Integration with Audiveris OMR engine

**Location**: `lib/desktop/services/omr_service.dart` (if exists)

**Methods**:
```dart
class OmrService {
  Future<String> processImage(String imagePath);
  Stream<double> getProgress();
  Future<void> cancel();
}
```

### Mobile Services

#### 8. ServerDiscoveryService

**Responsibility**: Discover desktop servers via mDNS

**Location**: `lib/mobile/services/server_discovery_service.dart`

**Methods**:
```dart
class ServerDiscoveryService extends ChangeNotifier {
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  List<ServerInfo> get discoveredServers;
  bool get isDiscovering;
}
```

#### 9. MobileConnectionService

**Responsibility**: Manage connection to desktop server

**Location**: `lib/mobile/services/mobile_connection_service.dart`

**Methods**:
```dart
class MobileConnectionService extends ChangeNotifier {
  Future<void> connect(String serverUrl);
  Future<void> disconnect();
  Future<List<SheetMusicDocument>> getDocuments({int page, int pageSize});
  Future<String?> getMusicXml(String documentId);
  void subscribeToUpdates();
  bool get isConnected;
}
```

---

## Data Flow

### Document Addition Flow (Desktop)

```
User Action: Import Image
        ↓
DesktopHomeScreen (UI)
        ↓
OmrService.processImage()
        ↓
Audiveris (External Process)
        ↓
MusicXML File Generated
        ↓
MusicXmlService.parseFile()
        ↓
LibraryService.addDocument()
        ↓
DatabaseService.saveDocument()
        ↓
SQLite Database (Persisted)
        ↓
LibraryService.notifyListeners()
        ↓
UI Updates (via Consumer)
```

### Document Sync Flow (Mobile)

```
Mobile App Launch
        ↓
ServerDiscoveryService.startDiscovery()
        ↓
mDNS Discovery
        ↓
Server List Displayed
        ↓
User Selects Server
        ↓
MobileConnectionService.connect(serverUrl)
        ↓
HTTP GET /documents?page=0&pageSize=20
        ↓
DesktopServerService (Desktop)
        ↓
LibraryService.databaseService.getDocumentsPage()
        ↓
JSON Response
        ↓
MobileConnectionService Parses Response
        ↓
Mobile UI Updates
        ↓
WebSocket Connection Established
        ↓
Real-time Updates Flow
```

### Annotation Flow (Mobile → Desktop)

```
User Adds Annotation (Mobile)
        ↓
MobileDocumentViewerScreen
        ↓
HTTP POST /documents/{id}/annotations
        ↓
DesktopServerService (Desktop)
        ↓
LibraryService.addAnnotation()
        ↓
DatabaseService.saveAnnotation()
        ↓
SQLite Database (Persisted)
        ↓
WebSocket Broadcast: annotation_added
        ↓
All Connected Clients Receive Update
        ↓
UI Updates on All Devices
```

---

## Technology Choices

### Why Flutter?

**Pros**:
- Single codebase for desktop + mobile
- High performance (compiled to native)
- Rich widget library
- Hot reload for fast development
- Growing ecosystem

**Cons**:
- Desktop support still maturing
- Limited native platform integration
- Larger app size

**Decision**: Benefits outweigh cons for this use case

### Why SQLite?

**Pros**:
- No server required
- Fast local queries
- Cross-platform
- Battle-tested reliability
- Full-text search support

**Alternatives Considered**:
- Hive: Less mature, no SQL
- ObjectBox: Proprietary, paid tiers
- Remote database: Unnecessary complexity

### Why Audiveris for OMR?

**Pros**:
- Open source (AGPLv3)
- MusicXML output
- Actively maintained
- Good accuracy

**Cons**:
- Requires Java runtime
- Heavy resource usage
- AGPLv3 license viral nature

**Alternatives Considered**:
- PhotoScore: Proprietary, expensive
- OMR Cloud APIs: Requires internet, privacy concerns

### Why mDNS for Discovery?

**Pros**:
- Zero configuration
- Works on local network
- Standard protocol
- No central server needed

**Cons**:
- Local network only
- Some network restrictions

**Alternatives Considered**:
- QR code pairing: Extra step for users
- Manual IP entry: Poor UX
- Cloud relay: Unnecessary infrastructure

---

## Related Documents

- [SPECIFICATION.md](./SPECIFICATION.md) - Master specification
- [API_SPECIFICATION.md](./API_SPECIFICATION.md) - REST API reference
- [DATA_MODEL.md](./DATA_MODEL.md) - Data structures
- [SYNC_PROTOCOL.md](./SYNC_PROTOCOL.md) - Synchronization protocol
- [PERFORMANCE_SPECIFICATION.md](./PERFORMANCE_SPECIFICATION.md) - Performance details
