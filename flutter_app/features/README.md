# BDD Testing with Gherkin

This directory contains Behavior-Driven Development (BDD) test specifications written in Gherkin syntax for the Sheet Music Reader application.

## Overview

The test suite uses `flutter_gherkin` to provide executable specifications that serve as both documentation and automated tests. Each feature file describes the behavior of a specific part of the application in plain English.

## Directory Structure

```
features/
├── library_management.feature       # Document library operations
├── sheet_music_viewing.feature      # Music viewing and navigation
├── omr_processing.feature           # OMR engine integration
├── mobile_sync.feature              # Mobile/desktop synchronization
├── annotations.feature              # Annotation features
├── performance.feature              # Performance requirements
└── step_definitions/
    ├── test_helpers.dart           # Shared test utilities
    ├── library_steps.dart          # Library step implementations
    ├── viewer_steps.dart           # Viewer step implementations
    └── omr_steps.dart              # OMR step implementations

test_driver/
├── gherkin_suite_test.dart         # Test runner configuration
└── app.dart                        # App entry point for testing
```

## Feature Files

### Completed Features

1. **library_management.feature** (9 scenarios)
   - Empty library view
   - Document import
   - Multi-document display
   - Search by title and composer
   - Document deletion
   - Sorting operations
   - Document count display

2. **sheet_music_viewing.feature** (12 scenarios)
   - Document viewer opening
   - Page navigation (next, previous, first, last)
   - Zoom controls (in, out, limits)
   - Mobile gestures (swipe, pinch)
   - Viewer closing

3. **omr_processing.feature** (10 scenarios)
   - High-quality image processing
   - Multi-page PDF processing
   - Low-quality image handling
   - Processing cancellation
   - Error handling
   - Progress tracking
   - Queue management

4. **mobile_sync.feature** (23 scenarios)
   - Server discovery via mDNS
   - Connection management
   - Real-time synchronization
   - Offline mode
   - Conflict resolution

5. **annotations.feature** (25 scenarios)
   - Text notes
   - Highlights
   - Drawing shapes
   - Color selection
   - Cross-platform sync

6. **performance.feature** (28 scenarios)
   - Memory management
   - Pagination efficiency
   - Rendering performance
   - Cache optimization

**Total: 107 test scenarios**

## Step Definitions

### Implemented Steps

- **test_helpers.dart**: Common utilities and mock data generators
- **library_steps.dart**: 40+ step definitions for library management
- **viewer_steps.dart**: 35+ step definitions for document viewing
- **omr_steps.dart**: 35+ step definitions for OMR processing

### Step Definition Pattern

Step definitions use regex patterns to match Gherkin steps to executable code:

```dart
class GivenTheLibraryHasDocuments extends Given1<int> {
  @override
  Future<void> executeStep(int count) async {
    // Implementation
  }

  @override
  RegExp get pattern => RegExp(r'the library has (\d+) documents?');
}
```

## Running the Tests

### Prerequisites

1. Install dependencies:
```bash
cd flutter_app
flutter pub get
```

2. Ensure Audiveris is installed (for OMR tests)

3. Have test data files ready in `test_files/` directory

### Running All Tests

```bash
flutter drive \
  --target=test_driver/app.dart \
  --driver=test_driver/gherkin_suite_test.dart
```

### Running Specific Features

You can filter by tags or modify the glob pattern in `gherkin_suite_test.dart`:

```dart
..features = [Glob(r"features/library_management.feature")]
```

### Test Output

The test runner generates:
- Console output with progress
- `report.json` with detailed results
- Screenshots on failures (when configured)

## Writing New Tests

### Adding a New Scenario

1. Open or create a feature file in `features/`
2. Write the scenario using Gherkin syntax:

```gherkin
Scenario: Export document as PDF
  Given I have a document "Sonata" open
  When I click the "Export" button
  And I select "PDF" as the format
  Then a PDF file should be created
  And it should match the original layout
```

3. Implement step definitions in `features/step_definitions/`
4. Register steps in `test_driver/gherkin_suite_test.dart`

### Step Definition Guidelines

- **Given** steps set up initial state (don't make assertions)
- **When** steps perform actions
- **Then** steps verify outcomes (make assertions)
- **And/But** steps inherit type from previous step

### Best Practices

1. **Keep steps reusable**: Write generic steps that work in multiple scenarios
2. **Use data tables**: For complex input data
3. **Mock external dependencies**: Don't rely on network or file system
4. **Test one thing**: Each scenario should verify a single behavior
5. **Use Background**: For common setup across scenarios

## Test Context

The `TestContext` class (in `test_helpers.dart`) maintains state between steps:

```dart
class TestContext {
  List<Map<String, dynamic>> documents = [];
  Map<String, dynamic>? selectedDocument;
  int currentPage = 1;
  double zoomLevel = 1.0;
  String? omrStatus;
  // ... more state
}
```

Access the context in step definitions:

```dart
final context = world.get<TestContext>('context');
context.documents.add(newDocument);
```

## Debugging Tests

### Enable Verbose Output

Modify `gherkin_suite_test.dart`:

```dart
..reporters = [
  ProgressReporter(),
  StdoutReporter(),  // Add this
  TestRunSummaryReporter(),
]
```

### Take Screenshots

Use the helper function:

```dart
await TestHelpers.takeScreenshot(driver, 'error_state');
```

### Print Debug Info

Add print statements in step definitions:

```dart
print('Current page: ${context.currentPage}');
print('Documents: ${context.documents.length}');
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: BDD Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter drive --target=test_driver/app.dart
```

## Limitations & Notes

### Current Limitations

1. **Mobile sync steps**: Not fully implemented (requires mock server)
2. **Annotation steps**: Not fully implemented (requires drawing API)
3. **Performance steps**: Not fully implemented (requires profiling tools)
4. **Flutter Driver**: May require modifications for actual widget interactions

### Mock vs. Real Testing

Currently using mocks for:
- File selection
- Network operations
- OMR processing
- Database operations

For integration testing with real services, you'll need to:
- Set up test database
- Configure Audiveris service
- Prepare test files
- Mock network if needed

## Extending the Test Suite

### Adding New Feature Files

1. Create `features/new_feature.feature`
2. Write scenarios using existing steps where possible
3. Create `features/step_definitions/new_feature_steps.dart` for new steps
4. Import and register in `test_driver/gherkin_suite_test.dart`

### Adding New Step Definitions

1. Identify the step pattern
2. Create a new class extending `Given1`, `When1`, or `Then1`
3. Implement `executeStep` method
4. Define regex `pattern`
5. Register in test configuration

### Example: Adding a New Step

```dart
class WhenIExportAsFormat extends When2<String, String> {
  @override
  Future<void> executeStep(String documentTitle, String format) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Click export button
    await TestHelpers.tapElement(driver, TestHelpers.findByText('Export'));
    
    // Select format
    await TestHelpers.tapElement(driver, TestHelpers.findByText(format));
    
    print('Exporting $documentTitle as $format');
  }

  @override
  RegExp get pattern => RegExp(r'I export "([^"]*)" as "([^"]*)"');
}
```

## Troubleshooting

### Tests Not Running

1. Check dependencies are installed: `flutter pub get`
2. Verify test driver app builds: `flutter run test_driver/app.dart`
3. Check feature file syntax (no tabs, proper indentation)

### Step Definition Not Found

1. Verify regex pattern matches the step exactly
2. Check step class is registered in `gherkin_suite_test.dart`
3. Ensure step file is imported

### Tests Timing Out

1. Increase timeout in test configuration
2. Check for infinite loops in step definitions
3. Verify app is actually responding

### False Failures

1. Add proper wait conditions
2. Use `TestHelpers.waitForElement()` instead of fixed delays
3. Check for race conditions in async operations

## Resources

- [Gherkin Syntax Reference](https://cucumber.io/docs/gherkin/reference/)
- [flutter_gherkin Documentation](https://pub.dev/packages/flutter_gherkin)
- [Flutter Driver Documentation](https://api.flutter.dev/flutter/flutter_driver/flutter_driver-library.html)
- [BDD Best Practices](https://cucumber.io/docs/bdd/)

## Contributing

When adding new tests:

1. Follow existing naming conventions
2. Keep step definitions atomic and reusable
3. Add comments for complex logic
4. Update this README with new features
5. Ensure all tests pass before committing

## License

Same as the main Sheet Music Reader project (AGPLv3).
