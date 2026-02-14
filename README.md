# Sheet Music Reader

A cross-platform sheet music application that converts PDF/images to MusicXML using Optical Music Recognition (OMR), with playback capabilities and cross-device synchronization.

## Features

### Desktop Application (Windows, Linux)
- **OMR Conversion**: Convert PDF and image files to editable MusicXML format using Audiveris
- **Music Playback**: Play sheet music with MIDI synthesis
- **Advanced Editing**: Manual correction and editing of recognized notes
- **Local Server**: Acts as a hub for mobile devices on the local network
- **Library Management**: Organize and manage your sheet music collection

### Mobile Application (Android, iOS)
- **Camera Capture**: Take photos of sheet music for conversion
- **Sheet Music Reader**: Optimized mobile reading experience
- **Annotations**: Add notes, highlights, and fingerings
- **Sync**: Bidirectional synchronization with desktop
- **Offline Access**: Cached sheet music for offline use

### Cross-Platform Features
- **MusicXML Support**: Industry-standard format for music notation
- **Network Sync**: Local network communication between devices
- **Open Source**: Built entirely with open-source, license-friendly technologies

## Architecture

```
sheet-music-reader/
├── flutter_app/           # Flutter application (desktop + mobile)
│   ├── lib/
│   │   ├── core/         # Shared models, services, utilities
│   │   ├── desktop/      # Desktop-specific code
│   │   ├── mobile/       # Mobile-specific code
│   │   └── shared/       # Shared UI components
│   └── pubspec.yaml
├── packages/
│   └── sync_protocol/     # Shared sync API/data models (pure Dart)
├── services/
│   └── sync_backend/      # Self-hosted sync backend (Dart, Docker-ready)
├── audiveris_service/    # Java service wrapping Audiveris
│   ├── src/
│   └── build.gradle
└── docs/                 # Documentation
```

## Self-Hosted Sync Backend

The project now includes an early standalone sync backend service:

- **Location**: `services/sync_backend`
- **Runtime**: Dart (`shelf` + SQLite + filesystem blobs)
- **Mode**: single-library/single-tenant in v1, schema designed for future multi-tenant expansion
- **Deployment**: Dockerfile and docker-compose starter included
- **Unraid prep**: template XML included at `services/sync_backend/unraid/sheet-music-sync-backend.xml`

This backend is intentionally decoupled from Flutter UI code so it can be split into a separate repository later without major rewrites.

## Technology Stack

### Frontend (Desktop & Mobile)
- **Flutter/Dart** - Cross-platform UI framework
- **Provider** - State management
- **Material Design 3** - UI components

### Core Libraries
- **xml** (MIT) - MusicXML parsing
- **shelf** (BSD-3) - HTTP server for desktop
- **http** (BSD-3) - HTTP client for mobile
- **multicast_dns** (BSD-3) - Service discovery
- **flutter_midi_command** - MIDI playback
- **camera** (BSD-3) - Camera access
- **file_picker** (MIT) - File selection

### OMR Engine
- **Audiveris** (AGPLv3) - Optical Music Recognition
- Used as separate subprocess/service (not modified)

## Setup

### Prerequisites

#### For Flutter Development
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
- For desktop: Platform-specific requirements (Visual Studio, GTK, etc.)
- For mobile: Android Studio or Xcode

#### For Audiveris Service
- Java 17+
- Gradle 8.5+ (or use included wrapper)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/basmulder03/sheet-music-reader.git
   cd sheet-music-reader
   ```

2. **Install Flutter dependencies**
   ```bash
   cd flutter_app
   flutter pub get
   ```

3. **Build Audiveris service**
   ```bash
   cd ../audiveris_service
   ./gradlew build  # On Windows: gradlew.bat build
   ```

### Running the Application

#### Desktop Application
```bash
cd flutter_app
flutter run -d windows  # or -d linux, -d macos
```

#### Mobile Application
```bash
cd flutter_app
flutter run -d android  # or -d ios
```

#### Audiveris Service (runs automatically with desktop app)
```bash
cd audiveris_service
./gradlew run
# Or use the fat JAR:
java -jar build/libs/audiveris-service.jar
```

## Development Roadmap

### Phase 1: Foundation (Current)
- [x] Project structure setup
- [x] MusicXML data models
- [x] Basic UI for desktop and mobile
- [x] Audiveris service wrapper

### Phase 2: Desktop Core
- [ ] PDF/image import
- [ ] Audiveris integration
- [ ] MusicXML rendering
- [ ] MIDI playback
- [ ] Manual editing interface
- [ ] Local storage

### Phase 3: Mobile Core
- [ ] Camera interface
- [ ] Image preprocessing
- [ ] Network client
- [ ] Sheet music reader UI
- [ ] Annotation system
- [ ] Local caching

### Phase 4: Communication & Sync
- [ ] HTTP/WebSocket server on desktop
- [ ] mDNS service discovery
- [ ] Device pairing/authentication
- [ ] Bidirectional sync protocol
- [ ] Conflict resolution

### Phase 5: Polish & Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] User documentation

## Usage

### Desktop: Import Sheet Music
1. Click "Import" in the navigation
2. Select PDF or image files
3. Wait for OMR processing
4. Review and edit the converted music
5. Save to your library

### Mobile: Capture Sheet Music
1. Tap "Capture" in the bottom navigation
2. Take a photo or select from gallery
3. Connect to desktop app on your network
4. Send for conversion
5. Receive and view the converted music

### Synchronization
- Desktop acts as the central hub
- Mobile devices sync their library with desktop
- Annotations are synced bidirectionally
- Works over local WiFi network

## Contributing

Contributions are welcome! Please ensure:
- Code follows the existing style
- New dependencies are open-source and license-compatible
- Features are documented

## License

This project uses multiple open-source components:

### Project Code
- MIT License (see LICENSE file)

### Dependencies
- Flutter & Dart packages: Various (MIT, BSD, Apache 2.0)
- Audiveris: AGPLv3 (used as separate service, not modified)

See individual package licenses in `pubspec.yaml` and `build.gradle` for details.

## Audiveris Note

This project uses [Audiveris](https://github.com/Audiveris/audiveris) for Optical Music Recognition. Audiveris is licensed under AGPLv3. We use it as a separate service/subprocess without modification, which allows this project to use a different license. If you modify Audiveris itself, you must comply with AGPLv3 requirements.

## Acknowledgments

- [Audiveris](https://github.com/Audiveris/audiveris) - OMR engine
- [Flutter](https://flutter.dev) - Cross-platform framework
- [MusicXML](https://www.musicxml.com/) - Music notation format
- All open-source contributors

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check the [documentation](docs/)
- Review existing issues and discussions
