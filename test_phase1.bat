@echo off
REM Test script for Sheet Music Reader - Phase 1 (Windows)
setlocal enabledelayedexpansion

echo ================================================================
echo   SHEET MUSIC READER - PHASE 1 TEST SUITE
echo ================================================================
echo.

set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0

echo 1. CHECKING PREREQUISITES
echo ----------------------------------------------------------------

where flutter >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m^✓[0m Flutter is installed
    set FLUTTER_OK=1
) else (
    echo [91m^✗[0m Flutter is NOT installed
    set FLUTTER_OK=0
)

where java >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m^✓[0m Java is installed
    set JAVA_OK=1
) else (
    echo [91m^✗[0m Java is NOT installed
    set JAVA_OK=0
)

echo.

if !FLUTTER_OK! equ 0 (
    echo [93m^⚠ Flutter SDK not found. Please install:[0m
    echo   • Download from: https://flutter.dev/docs/get-started/install
    echo   • Add to PATH
    echo.
)

if !JAVA_OK! equ 0 (
    echo [93m^⚠ Java JDK not found. Please install:[0m
    echo   • Download JDK 17+ from: https://adoptium.net/
    echo   • Or use: choco install temurin17
    echo.
)

if !FLUTTER_OK! equ 0 (
    echo After installation, run this script again.
    pause
    exit /b 1
)

if !JAVA_OK! equ 0 (
    echo After installation, run this script again.
    pause
    exit /b 1
)

echo 2. VERIFYING PROJECT STRUCTURE
echo ----------------------------------------------------------------

call :run_test "Flutter app directory" "if exist flutter_app ( exit 0 ) else ( exit 1 )"
call :run_test "Audiveris service directory" "if exist audiveris_service ( exit 0 ) else ( exit 1 )"
call :run_test "Main.dart" "if exist flutter_app\lib\main.dart ( exit 0 ) else ( exit 1 )"

echo.

echo 3. FLUTTER ANALYSIS
echo ----------------------------------------------------------------

cd flutter_app
call :run_test "Flutter pub get" "flutter pub get"
call :run_test "Flutter analyze" "flutter analyze --no-pub"
echo.

echo 4. FLUTTER UNIT TESTS
echo ----------------------------------------------------------------
call :run_test "MusicXML parser tests" "flutter test test\musicxml_parser_test.dart"
cd ..

echo.

echo 5. JAVA SERVICE BUILD
echo ----------------------------------------------------------------

cd audiveris_service
call :run_test "Gradle build" "gradlew.bat build"
cd ..

echo.

echo ================================================================
echo   TEST SUMMARY
echo ================================================================
echo.
echo Total Tests:  !TOTAL_TESTS!
echo Passed:       [92m!PASSED_TESTS![0m
echo Failed:       [91m!FAILED_TESTS![0m
echo.

if !FAILED_TESTS! equ 0 (
    echo [92m^✓ ALL TESTS PASSED![0m
    echo.
    echo Phase 1 is fully operational and ready for Phase 2!
) else (
    echo [91m^✗ SOME TESTS FAILED[0m
    echo.
    echo Please review the failures above and fix any issues.
)

pause
exit /b !FAILED_TESTS!

:run_test
set /a TOTAL_TESTS+=1
echo | set /p="Testing: %~1... "
%~2 >nul 2>&1
if %errorlevel% equ 0 (
    echo [92mPASS[0m
    set /a PASSED_TESTS+=1
) else (
    echo [91mFAIL[0m
    set /a FAILED_TESTS+=1
)
exit /b 0
