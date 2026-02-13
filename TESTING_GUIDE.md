# Testing Guide - Phase 1

This guide explains how to test the Sheet Music Reader Phase 1 implementation.

## Current Status

✅ **Code Complete**: All Phase 1 code has been written and is ready for testing  
⚠️ **SDK Required**: Flutter and Java SDK need to be installed to run tests

## What Has Been Verified

### ✅ Manual Verification Complete
- **Project Structure**: All 30+ directories created correctly
- **File Creation**: 21 files with 3,025 lines of code
- **Code Quality**: Syntax, structure, and organization reviewed
- **Documentation**: 5 comprehensive markdown documents
- **Configuration**: All dependencies properly specified

### ⏸️ Pending Runtime Testing
- **Unit Tests**: 7 MusicXML parser tests ready to run
- **Flutter Analysis**: Code linting and formatting checks
- **Desktop Build**: Windows/Linux build verification
- **Java Service**: REST API functionality tests
- **Integration**: End-to-end workflow testing

## Prerequisites for Testing

### 1. Install Flutter SDK

**Windows:**
```bash
# Using Chocolatey
choco install flutter

# Or download manually from:
# https://flutter.dev/docs/get-started/install
```

**Linux:**
```bash
# Download and extract
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_latest-stable.tar.xz
tar xf flutter_linux_latest-stable.tar.xz

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"
```

**Verify Installation:**
```bash
flutter doctor
```

### 2. Install Java JDK 17+

**Windows:**
```bash
choco install temurin17
```

**Linux:**
```bash
sudo apt install openjdk-17-jdk
```

**Verify Installation:**
```bash
java -version
```

### 3. Install Platform Tools

**Windows Desktop:**
- Visual Studio 2022 with "Desktop development with C++" workload
- Windows 10 SDK

**Linux Desktop:**
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

## Running Tests

### Automated Test Suite

**Windows:**
```bash
test_phase1.bat
```

**Linux/macOS:**
```bash
chmod +x test_phase1.sh
./test_phase1.sh
```

The automated test suite will:
1. Check prerequisites
2. Verify project structure
3. Run Flutter analysis
4. Execute unit tests
5. Build Java service
6. Test REST API endpoints
7. Build desktop application

### Manual Testing

#### 1. Test MusicXML Parser

```bash
cd flutter_app
flutter test test/musicxml_parser_test.dart -r expanded
```

Expected output: 7 tests passing

#### 2. Test Flutter Analysis

```bash
cd flutter_app
flutter analyze
```

Expected output: No issues found

#### 3. Test Java Service

**Terminal 1 - Start service:**
```bash
cd audiveris_service
./gradlew run  # Windows: gradlew.bat run
```

**Terminal 2 - Test endpoints:**
```bash
# Health check
curl http://localhost:8081/health

# Expected: {"status":"ok","service":"audiveris-omr","version":"0.1.0"}

# List jobs
curl http://localhost:8081/jobs

# Expected: {}
```

#### 4. Test Desktop Application

```bash
cd flutter_app
flutter run -d windows  # or -d linux
```

Expected behavior:
- Application launches
- Navigation rail shows 4 sections
- Can navigate between Library, Import, Devices, Settings
- UI renders correctly in light/dark theme

## Test Checklist

### Unit Tests
- [ ] Parse simple MusicXML score
- [ ] Parse note with pitch
- [ ] Parse rest
- [ ] Parse time signature
- [ ] Parse key signature
- [ ] Parse clef
- [ ] All 7 tests pass

### Flutter Analysis
- [ ] No analysis errors
- [ ] No linting warnings
- [ ] Code formatting is correct

### Java Service
- [ ] Gradle builds successfully
- [ ] Service starts on port 8081
- [ ] Health endpoint responds
- [ ] Jobs endpoint responds
- [ ] Can upload files (once implemented)

### Desktop Application
- [ ] Application launches
- [ ] Navigation works
- [ ] Library view renders
- [ ] Import view renders
- [ ] Devices view renders
- [ ] Settings view renders
- [ ] Theme switching works
- [ ] No runtime errors

### Code Quality
- [ ] Consistent naming conventions
- [ ] Proper null safety
- [ ] Clear documentation
- [ ] Error handling present
- [ ] Type annotations used

## Expected Test Results

### Successful Run
```
════════════════════════════════════════════════════════════
  SHEET MUSIC READER - PHASE 1 TEST SUITE
════════════════════════════════════════════════════════════

1. CHECKING PREREQUISITES
──────────────────────────────────────────────────────────
✓ flutter is installed
✓ java is installed

2. VERIFYING PROJECT STRUCTURE
──────────────────────────────────────────────────────────
Testing: Flutter app directory exists... PASS
Testing: Audiveris service directory exists... PASS
Testing: Main.dart exists... PASS
[... more tests ...]

════════════════════════════════════════════════════════════
  TEST SUMMARY
════════════════════════════════════════════════════════════

Total Tests:  15
Passed:       15
Failed:       0

✓ ALL TESTS PASSED!

Phase 1 is fully operational and ready for Phase 2!
```

## Troubleshooting

### Flutter Not Found
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or on Windows, add to System Environment Variables
```

### Java Not Found
```bash
# Verify JAVA_HOME is set
echo $JAVA_HOME  # Linux/macOS
echo %JAVA_HOME% # Windows

# Should point to JDK installation directory
```

### Gradle Build Fails
```bash
cd audiveris_service
./gradlew clean build --refresh-dependencies
```

### Flutter Pub Get Fails
```bash
cd flutter_app
flutter clean
flutter pub cache repair
flutter pub get
```

### Port 8081 Already in Use
```bash
# Find and kill process using port 8081
# Linux/macOS:
lsof -i :8081
kill -9 <PID>

# Windows:
netstat -ano | findstr :8081
taskkill /PID <PID> /F
```

## Next Steps After Testing

Once all tests pass:

1. **Review Results**: Check that all features work as expected
2. **Document Issues**: Note any bugs or improvements
3. **Phase 2 Planning**: Prepare for desktop core features
4. **Feature Development**: Start implementing Phase 2 tasks

## Files in Test Suite

```
sheet-music-reader/
├── test_phase1.sh          # Linux/macOS test script
├── test_phase1.bat         # Windows test script
├── docs/
│   ├── TEST_REPORT.md      # Detailed test results
│   └── TESTING_GUIDE.md    # This file
└── flutter_app/test/
    └── musicxml_parser_test.dart  # Unit tests
```

## Need Help?

- Check the TEST_REPORT.md for detailed verification results
- Review QUICKSTART.md for setup instructions
- See README.md for architecture details
- Open an issue on GitHub for problems

---

**Testing Status**: Ready for execution once SDKs are installed  
**Last Updated**: February 13, 2026
