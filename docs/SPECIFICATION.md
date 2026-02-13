# Sheet Music Reader - Project Specification

**Version:** 1.0  
**Last Updated:** February 13, 2026  
**Status:** Active Development - Phase 5 (Testing & QA)

## Table of Contents

1. [Overview](#overview)
2. [Project Goals](#project-goals)
3. [System Architecture](#system-architecture)
4. [Technology Stack](#technology-stack)
5. [Key Features](#key-features)
6. [Development Phases](#development-phases)
7. [Related Specifications](#related-specifications)

---

## Overview

The Sheet Music Reader is a cross-platform application that enables musicians to digitize, view, annotate, and play back sheet music. The system uses Optical Music Recognition (OMR) to convert scanned sheet music images into the industry-standard MusicXML format, which can then be displayed, edited, and played back with MIDI audio.

### Core Capabilities

- **Desktop Application**: Full-featured application for Windows/macOS/Linux with OMR processing, library management, and editing
- **Mobile Application**: Companion app for Android/iOS for viewing and annotating music on tablets
- **Synchronization**: Real-time sync between desktop and mobile devices over local network
- **MIDI Playback**: Audio playback of digitized sheet music
- **Annotation System**: Rich annotation support including text notes, highlights, and visual markings

---

## Project Goals

### Primary Objectives

1. **Digitize Sheet Music**: Convert physical sheet music to digital format with high accuracy
2. **Cross-Platform Viewing**: Provide seamless viewing experience on desktop and mobile devices
3. **Real-time Collaboration**: Enable synchronized viewing and annotation across devices
4. **Professional Playback**: High-quality MIDI audio playback for practice and learning
5. **Offline Capability**: Full functionality without internet connection

### Success Criteria

- OMR accuracy: >90% for standard notation
- Sync latency: <500ms on local network
- Mobile rendering: 60 FPS for smooth scrolling
- Library support: 1000+ documents without performance degradation
- Cross-platform: Single Flutter codebase for all platforms

---

## System Architecture

The application follows a **client-server architecture** where the desktop application acts as the central hub (server) and mobile devices act as clients.

```
┌─────────────────────────────────────────────────────────────┐
│                      DESKTOP APPLICATION                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Flutter Desktop UI Layer                  │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Core Services (Shared with Mobile)           │ │
│  │  • Library Service    • Database Service               │ │
│  │  • MusicXML Service   • Memory Manager                 │ │
│  │  • Image Cache        • Performance Profiler           │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Desktop-Specific Services                 │ │
│  │  • HTTP/WebSocket Server  • mDNS Service Discovery     │ │
│  │  • Audiveris Integration  • File System Management     │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                  SQLite Database                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              ↕
                    HTTP/WebSocket + mDNS
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                      MOBILE APPLICATION                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │               Flutter Mobile UI Layer                  │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           Core Services (Shared with Desktop)          │ │
│  │  • MusicXML Renderer  • Image Cache                    │ │
│  │  • Memory Manager     • Network Optimizer              │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Mobile-Specific Services                  │ │
│  │  • Server Discovery   • Connection Service             │ │
│  │  • Offline Cache      • Touch Gestures                 │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    AUDIVERIS OMR SERVICE                     │
│                   (External Java Process)                    │
│  • Image Processing      • Staff Detection                   │
│  • Symbol Recognition    • MusicXML Export                   │
└─────────────────────────────────────────────────────────────┘
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture documentation.

---

## Technology Stack

### Frontend

- **Framework**: Flutter 3.27.2
- **Language**: Dart 3.x
- **UI Library**: Material Design 3
- **State Management**: Provider pattern

### Backend (Desktop Server)

- **Server**: Shelf (Dart HTTP server)
- **WebSocket**: shelf_web_socket
- **Service Discovery**: multicast_dns
- **Database**: SQLite (sqflite)

### OMR Processing

- **Engine**: Audiveris 5.3 (Java-based)
- **License**: AGPLv3
- **Format**: MusicXML 3.1 output
- **JDK**: Java 17 (Eclipse Adoptium)

### Data Formats

- **Music Notation**: MusicXML 3.1
- **Audio**: MIDI playback
- **Images**: PNG, JPEG (for thumbnails)
- **Database**: SQLite

### Development Tools

- **IDE**: Visual Studio Code / Android Studio
- **Build System**: Flutter build tools
- **Version Control**: Git
- **Testing**: flutter_test

---

## Key Features

### 1. Optical Music Recognition (OMR)

- **Input**: Scanned sheet music images (PNG, JPEG, PDF)
- **Output**: MusicXML format
- **Accuracy**: >90% for standard notation
- **Processing**: Background processing with progress indication
- **Manual Correction**: Post-processing editor for fixing recognition errors

**Implementation**: See [OMR_SPECIFICATION.md](./OMR_SPECIFICATION.md)

### 2. Library Management

- **Organization**: Title, composer, tags, creation/modification dates
- **Search**: Full-text search across title, composer, and tags
- **Pagination**: Efficient loading of large libraries (20 items per page)
- **Sorting**: By title, composer, date modified, date created
- **Statistics**: Document count, cache usage, storage metrics

**Implementation**: See [DATA_MODEL.md](./DATA_MODEL.md)

### 3. Sheet Music Viewer

- **Rendering**: High-quality MusicXML rendering
- **Zoom**: 50% to 300% zoom levels
- **Pagination**: Page-by-page navigation with page indicators
- **Responsive**: Adapts to screen size and orientation
- **Performance**: 60 FPS smooth scrolling

**Implementation**: See [UI_SPECIFICATION.md](./UI_SPECIFICATION.md)

### 4. Annotation System

- **Types**: Text notes, highlights, shape markings (circle, rectangle, arrow)
- **Colors**: Multiple color options for visual distinction
- **Page-specific**: Annotations tied to specific pages
- **Persistence**: Saved to SQLite database
- **Sync**: Real-time synchronization across devices

**Implementation**: See [DATA_MODEL.md](./DATA_MODEL.md#annotations)

### 5. MIDI Playback

- **Playback**: Full score playback with tempo control
- **Navigation**: Play/pause, stop, seek to position
- **Visual Tracking**: Highlight current measure/note during playback
- **Loop**: Repeat sections for practice

**Implementation**: See [PLAYBACK_SPECIFICATION.md](./PLAYBACK_SPECIFICATION.md)

### 6. Mobile-Desktop Sync

- **Discovery**: Automatic server discovery via mDNS
- **Protocol**: HTTP REST API + WebSocket for real-time updates
- **Security**: Local network only, optional authentication
- **Offline**: Local cache for offline viewing
- **Efficiency**: Paginated sync, delta updates, image caching

**Implementation**: See [SYNC_PROTOCOL.md](./SYNC_PROTOCOL.md)

### 7. Performance Optimizations

- **Memory Management**: LRU caching, 100MB limit for loaded documents
- **Image Caching**: 50MB memory + 200MB disk cache
- **Network Optimization**: Request debouncing, batching, compression
- **Database**: Indexed queries, pagination, optimized schema
- **Rendering**: Frame profiling, dropped frame detection

**Implementation**: See [PERFORMANCE_SPECIFICATION.md](./PERFORMANCE_SPECIFICATION.md)

---

## Development Phases

### Phase 1: Foundation & Core Libraries ✅ COMPLETED

**Duration**: Completed  
**Deliverables**:
- Project structure setup
- Core data models (MusicXML, Documents, Annotations)
- MusicXML parsing service
- Database service (SQLite)
- Library service (document management)

### Phase 2: Desktop Core Features ✅ COMPLETED

**Duration**: Completed  
**Features Implemented** (7/7):
1. OMR integration with Audiveris
2. Document import and management
3. MusicXML viewer with zoom/pagination
4. Annotation system (add, edit, delete)
5. HTTP server for mobile clients
6. WebSocket real-time updates
7. mDNS service discovery

### Phase 3: Mobile App Development ✅ COMPLETED

**Duration**: Completed  
**Features Implemented** (8/8):
1. Server discovery UI
2. Connection management
3. Document browsing (list view)
4. Document viewer with zoom/pan
5. Annotation viewing and editing
6. Real-time sync with WebSocket
7. Offline caching
8. Touch gesture support

### Phase 4: Performance & Optimization ✅ COMPLETED

**Duration**: Completed  
**Optimizations Implemented** (8/8):
1. MusicXML parsing optimization (LRU cache, isolates)
2. Document list pagination (20 per page)
3. Image caching (memory + disk)
4. WebSocket message batching
5. Database query optimization (9 indexes)
6. Memory management (100MB limit)
7. Network request debouncing/batching
8. Rendering performance profiling

### Phase 5: Testing & Quality Assurance 🔄 IN PROGRESS

**Duration**: Current  
**Goals**:
- Bug fixes and code cleanup ✅
- Unit test coverage for core services
- Integration tests for sync protocol
- Performance benchmarking
- Widget tests for UI components
- Load testing with realistic data

### Phase 6: Polish & Release 📋 PLANNED

**Goals**:
- UI/UX improvements
- Documentation completion
- Build configuration
- App store preparation
- CI/CD pipeline setup

---

## Related Specifications

This is the master specification document. Detailed specifications for individual components:

### Architecture & Design
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture and component design
- [DATA_MODEL.md](./DATA_MODEL.md) - Data structures and database schema

### APIs & Protocols
- [API_SPECIFICATION.md](./API_SPECIFICATION.md) - REST API reference
- [SYNC_PROTOCOL.md](./SYNC_PROTOCOL.md) - Mobile-desktop synchronization protocol
- [WEBSOCKET_PROTOCOL.md](./WEBSOCKET_PROTOCOL.md) - WebSocket message format

### Feature Specifications
- [OMR_SPECIFICATION.md](./OMR_SPECIFICATION.md) - Optical Music Recognition integration
- [UI_SPECIFICATION.md](./UI_SPECIFICATION.md) - User interface specifications
- [PLAYBACK_SPECIFICATION.md](./PLAYBACK_SPECIFICATION.md) - MIDI playback system

### Technical Specifications
- [PERFORMANCE_SPECIFICATION.md](./PERFORMANCE_SPECIFICATION.md) - Performance optimizations
- [SECURITY_SPECIFICATION.md](./SECURITY_SPECIFICATION.md) - Security considerations
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment and build guide

### Guides
- [QUICKSTART.md](./QUICKSTART.md) - Getting started guide
- [TESTING_GUIDE.md](../TESTING_GUIDE.md) - Testing procedures
- [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) - How components connect

---

## License

This project is licensed under AGPLv3 (inherited from Audiveris).

---

## Contact & Support

For questions, issues, or contributions, please refer to the project repository.
