# Quick Start Guide

## Overview

This guide will help you get the Sheet Music Reader application up and running on your system.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Run `flutter doctor` to verify installation

2. **Java Development Kit** (JDK 17 or higher)
   - Download from: https://adoptium.net/
   - Or use your system's package manager

3. **Git**
   - For cloning the repository

### Platform-Specific Requirements

#### Windows Desktop
- Visual Studio 2022 with "Desktop development with C++" workload
- Windows 10 SDK

#### Linux Desktop
- GTK 3.0 development libraries
- Install via: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev`

#### Android
- Android Studio
- Android SDK (API level 21+)

#### iOS
- macOS required
- Xcode 13+
- CocoaPods

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/basmulder03/sheet-music-reader.git
cd sheet-music-reader
```

### 2. Set Up Flutter Application

```bash
cd flutter_app

# Get Flutter dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

### 3. Set Up Audiveris Service

```bash
cd ../audiveris_service

# Build the service (Unix/Linux/macOS)
./gradlew build

# Or on Windows
gradlew.bat build
```

## Running the Application

### Desktop Application

#### Windows
```bash
cd flutter_app
flutter run -d windows
```

#### Linux
```bash
cd flutter_app
flutter run -d linux
```

### Mobile Application

#### Android
```bash
cd flutter_app

# List available devices
flutter devices

# Run on connected device
flutter run -d <device-id>
```

#### iOS (macOS only)
```bash
cd flutter_app

# Install iOS dependencies
cd ios
pod install
cd ..

# Run on simulator or device
flutter run -d ios
```

### Audiveris Service

The service will start automatically when the desktop application runs. To run it manually:

```bash
cd audiveris_service
./gradlew run
```

Or using the built JAR:
```bash
java -jar build/libs/audiveris-service.jar
```

The service runs on port 8081 by default.

## Verifying Installation

### Check Flutter Application

1. Launch the desktop or mobile app
2. You should see the home screen with navigation options
3. Navigate between Library, Import/Capture, Devices, and Settings

### Check Audiveris Service

1. Start the service manually or through the desktop app
2. Visit http://localhost:8081/health in a browser
3. You should see a JSON response: `{"status":"ok",...}`

## Development Mode

### Hot Reload

While the Flutter app is running:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Debug Mode

```bash
# Run with verbose logging
flutter run -v

# Run in debug mode with DevTools
flutter run --observatory-port=9999
```

## Common Issues

### Flutter Doctor Issues

If `flutter doctor` shows issues:
- Follow the instructions provided by the doctor output
- Most issues can be resolved by installing missing dependencies

### Build Errors

**"Could not resolve dependencies"**
- Run `flutter pub get` again
- Check your internet connection
- Clear pub cache: `flutter pub cache repair`

**"Gradle build failed"**
- Ensure Java 17+ is installed
- Check JAVA_HOME environment variable
- Try: `./gradlew clean build`

### Platform-Specific Issues

**Windows**: Visual Studio not found
- Install Visual Studio 2022 with C++ workload
- Run `flutter doctor` to verify

**Linux**: GTK errors
- Install GTK development libraries
- Run: `sudo apt-get install libgtk-3-dev`

**Android**: SDK not found
- Open Android Studio
- Go to SDK Manager and install required SDK versions

## Next Steps

### Explore the Code

- `flutter_app/lib/main.dart` - Application entry point
- `flutter_app/lib/core/models/` - Data models
- `flutter_app/lib/desktop/` - Desktop-specific code
- `flutter_app/lib/mobile/` - Mobile-specific code
- `audiveris_service/src/` - OMR service code

### Start Development

1. Review the project structure in README.md
2. Check the development roadmap
3. Look at open issues on GitHub
4. Read the architecture documentation in docs/

### Configure the Application

1. Open Settings in the app
2. Configure storage locations
3. Set up server preferences (desktop)
4. Customize theme and preferences

## Getting Help

- Check the main README.md for detailed information
- Look for existing issues on GitHub
- Review the documentation in the docs/ directory
- Open a new issue if you encounter problems

## Testing

### Run Unit Tests

```bash
cd flutter_app
flutter test
```

### Run Integration Tests

```bash
cd flutter_app
flutter test integration_test/
```

## Building for Release

### Desktop

```bash
flutter build windows  # or linux, macos
```

### Mobile

```bash
flutter build apk      # Android
flutter build ios      # iOS (macOS only)
```

## What's Next?

Now that you have the application running, you can:

1. **Try the demo** - Explore the UI and navigation
2. **Import test data** - Add sample sheet music to the library
3. **Connect devices** - Try connecting mobile and desktop apps
4. **Contribute** - Pick an issue from the roadmap and start coding!

Happy coding!
