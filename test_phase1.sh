#!/bin/bash
# Test script for Sheet Music Reader - Phase 1
# This script will test all components once SDKs are installed

set -e  # Exit on error

echo "════════════════════════════════════════════════════════════"
echo "  SHEET MUSIC READER - PHASE 1 TEST SUITE"
echo "════════════════════════════════════════════════════════════"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to check if command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        return 1
    fi
}

# Function to run test
run_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing: $1... "
    
    if eval "$2" &> /dev/null; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo "1. CHECKING PREREQUISITES"
echo "──────────────────────────────────────────────────────────"

check_command flutter && FLUTTER_OK=1 || FLUTTER_OK=0
check_command java && JAVA_OK=1 || JAVA_OK=0
check_command dart && DART_OK=1 || DART_OK=0
check_command gradle && GRADLE_OK=1 || GRADLE_OK=0

echo ""

if [ $FLUTTER_OK -eq 0 ] || [ $JAVA_OK -eq 0 ]; then
    echo -e "${YELLOW}⚠ Prerequisites not met. Please install:${NC}"
    [ $FLUTTER_OK -eq 0 ] && echo "  • Flutter SDK: https://flutter.dev/docs/get-started/install"
    [ $JAVA_OK -eq 0 ] && echo "  • Java JDK 17+: https://adoptium.net/"
    echo ""
    echo "After installation, run this script again."
    exit 1
fi

echo "2. VERIFYING PROJECT STRUCTURE"
echo "──────────────────────────────────────────────────────────"

run_test "Flutter app directory exists" "[ -d 'flutter_app' ]"
run_test "Audiveris service directory exists" "[ -d 'audiveris_service' ]"
run_test "Documentation directory exists" "[ -d 'docs' ]"
run_test "Main.dart exists" "[ -f 'flutter_app/lib/main.dart' ]"
run_test "MusicXML model exists" "[ -f 'flutter_app/lib/core/models/musicxml_model.dart' ]"
run_test "Java service exists" "[ -f 'audiveris_service/src/main/java/com/sheetmusicreader/AudiverisService.java' ]"
run_test "README exists" "[ -f 'README.md' ]"

echo ""

echo "3. FLUTTER ANALYSIS"
echo "──────────────────────────────────────────────────────────"

cd flutter_app

run_test "Flutter pub get" "flutter pub get"
run_test "Flutter analyze" "flutter analyze --no-pub"
run_test "Dart format check" "dart format --output=none --set-exit-if-changed lib/"

echo ""

echo "4. FLUTTER UNIT TESTS"
echo "──────────────────────────────────────────────────────────"

run_test "MusicXML parser tests" "flutter test test/musicxml_parser_test.dart"

echo ""

echo "5. JAVA SERVICE BUILD"
echo "──────────────────────────────────────────────────────────"

cd ../audiveris_service

run_test "Gradle build" "./gradlew build --quiet"
run_test "JAR file created" "[ -f 'build/libs/audiveris-service.jar' ]"

echo ""

echo "6. JAVA SERVICE RUNTIME TEST"
echo "──────────────────────────────────────────────────────────"

# Start service in background
echo "Starting Audiveris service..."
./gradlew run > /dev/null 2>&1 &
SERVICE_PID=$!
sleep 5  # Give service time to start

run_test "Service health check" "curl -s http://localhost:8081/health | grep -q 'ok'"
run_test "Service responds to requests" "curl -s http://localhost:8081/jobs | grep -q '\['"

# Stop service
kill $SERVICE_PID 2>/dev/null || true

cd ..

echo ""

echo "7. FLUTTER BUILD TESTS"
echo "──────────────────────────────────────────────────────────"

cd flutter_app

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    run_test "Linux desktop build" "flutter build linux --debug"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    run_test "Windows desktop build" "flutter build windows --debug"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    run_test "macOS desktop build" "flutter build macos --debug"
fi

cd ..

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  TEST SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Total Tests:  $TOTAL_TESTS"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo ""
    echo "Phase 1 is fully operational and ready for Phase 2!"
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failures above and fix any issues."
    exit 1
fi
