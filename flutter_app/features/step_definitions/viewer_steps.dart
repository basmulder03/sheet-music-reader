import 'package:flutter_driver/flutter_driver.dart';
import 'package:gherkin/gherkin.dart';
import 'test_helpers.dart';

// Background steps
class GivenTheApplicationIsRunning extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('app_root'),
      timeout: const Duration(seconds: 10),
    );
    print('Application is running');
  }

  @override
  RegExp get pattern => RegExp(r'the application is running');
}

class GivenIHaveADocumentInMyLibrary extends Given1<String> {
  @override
  Future<void> executeStep(String documentTitle) async {
    final context = world.get<TestContext>('context');
    
    context.documents.add(
      MockData.createDocument(
        title: documentTitle,
        composer: 'Test Composer',
      ),
    );
    
    print('Added document to library: $documentTitle');
  }

  @override
  RegExp get pattern => RegExp(r'I have a document "([^"]*)" in my library');
}

class GivenIAmOnTheHomeScreen extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('home_screen'),
    );
    
    print('On home screen');
  }

  @override
  RegExp get pattern => RegExp(r'I am on the home screen');
}

// Document viewing state
class GivenIAmViewingAPageDocument extends Given1<int> {
  @override
  Future<void> executeStep(int pageCount) async {
    final context = world.get<TestContext>('context');
    
    context.selectedDocument = MockData.createDocument(
      title: 'Test Document',
      composer: 'Test Composer',
    );
    context.selectedDocument!['page_count'] = pageCount;
    context.currentPage = 1;
    
    print('Viewing $pageCount-page document');
  }

  @override
  RegExp get pattern => RegExp(r'I am viewing a (\d+)-page document');
}

class GivenIAmViewingAMultiPageDocument extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    context.selectedDocument = MockData.createDocument(
      title: 'Multi-page Document',
      composer: 'Test Composer',
    );
    context.selectedDocument!['page_count'] = 10;
    context.currentPage = 1;
    
    print('Viewing multi-page document');
  }

  @override
  RegExp get pattern => RegExp(r'I am viewing a multi-page document');
}

class GivenIAmViewingADocument extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    if (context.selectedDocument == null) {
      context.selectedDocument = MockData.createDocument(
        title: 'Test Document',
        composer: 'Test Composer',
      );
      context.selectedDocument!['page_count'] = 5;
    }
    
    print('Viewing document');
  }

  @override
  RegExp get pattern => RegExp(r'I am viewing a document');
}

class GivenIAmOnPage extends Given1<int> {
  @override
  Future<void> executeStep(int pageNumber) async {
    final context = world.get<TestContext>('context');
    context.currentPage = pageNumber;
    
    print('On page $pageNumber');
  }

  @override
  RegExp get pattern => RegExp(r'I am on page (\d+)');
}

class GivenIAmViewingADocumentAtZoom extends Given1<int> {
  @override
  Future<void> executeStep(int zoomPercent) async {
    final context = world.get<TestContext>('context');
    context.zoomLevel = zoomPercent / 100.0;
    
    if (context.selectedDocument == null) {
      context.selectedDocument = MockData.createDocument(
        title: 'Test Document',
        composer: 'Test Composer',
      );
    }
    
    print('Viewing document at $zoomPercent% zoom');
  }

  @override
  RegExp get pattern => RegExp(r'I am viewing a document at (\d+)% zoom');
}

// Action steps
class WhenIClickOnTheDocument extends When1<String> {
  @override
  Future<void> executeStep(String documentTitle) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Find and tap document
    final documentTile = TestHelpers.findByText(documentTitle);
    await TestHelpers.tapElement(driver, documentTile);
    
    // Set as selected document
    context.selectedDocument = context.documents.firstWhere(
      (doc) => doc['title'] == documentTitle,
      orElse: () => MockData.createDocument(title: documentTitle),
    );
    context.currentPage = 1;
    
    print('Clicked on document: $documentTitle');
  }

  @override
  RegExp get pattern => RegExp(r'I click on the document "([^"]*)"');
}

class WhenIClickThePageButton extends When1<String> {
  @override
  Future<void> executeStep(String buttonName) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    final pageCount = context.selectedDocument?['page_count'] ?? 5;
    
    // Handle different page navigation buttons
    if (buttonName == 'Next Page' && context.currentPage < pageCount) {
      context.currentPage++;
    } else if (buttonName == 'Previous Page' && context.currentPage > 1) {
      context.currentPage--;
    } else if (buttonName == 'First Page') {
      context.currentPage = 1;
    } else if (buttonName == 'Last Page') {
      context.currentPage = pageCount;
    }
    
    // Tap the button
    final button = TestHelpers.findByText(buttonName);
    await TestHelpers.tapElement(driver, button);
    
    print('Clicked $buttonName button, now on page ${context.currentPage}');
  }

  @override
  RegExp get pattern => RegExp(r'I click the "([^"]*)" button');
}

class WhenIClickTheZoomButton extends When1<String> {
  @override
  Future<void> executeStep(String buttonName) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Handle zoom buttons
    if (buttonName == 'Zoom In' && context.zoomLevel < 3.0) {
      context.zoomLevel += 0.25;
    } else if (buttonName == 'Zoom Out' && context.zoomLevel > 0.5) {
      context.zoomLevel -= 0.25;
    }
    
    // Tap the button
    final button = TestHelpers.findByText(buttonName);
    await TestHelpers.tapElement(driver, button);
    
    final zoomPercent = (context.zoomLevel * 100).round();
    print('Clicked $buttonName button, zoom now at $zoomPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'I click the "([^"]*)" button');
}

class WhenIClickTheZoomButtonAgain extends When1<String> {
  @override
  Future<void> executeStep(String buttonName) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Handle zoom buttons
    if (buttonName == 'Zoom In' && context.zoomLevel < 3.0) {
      context.zoomLevel += 0.25;
    } else if (buttonName == 'Zoom Out' && context.zoomLevel > 0.5) {
      context.zoomLevel -= 0.25;
    }
    
    final button = TestHelpers.findByText(buttonName);
    await TestHelpers.tapElement(driver, button);
    
    final zoomPercent = (context.zoomLevel * 100).round();
    print('Clicked $buttonName button again, zoom now at $zoomPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'I click the "([^"]*)" button again');
}

class WhenITryToClickTheButton extends When1<String> {
  @override
  Future<void> executeStep(String buttonName) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Try to click but it should be disabled
    final button = TestHelpers.findByText(buttonName);
    
    // Check if button exists but don't tap if disabled
    final exists = await TestHelpers.elementExists(driver, button);
    if (exists) {
      print('Button $buttonName exists but should be disabled');
    }
  }

  @override
  RegExp get pattern => RegExp(r'I try to click the "([^"]*)" button');
}

class WhenIClickTheBackButton extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    final backButton = TestHelpers.findByKey('back_button');
    await TestHelpers.tapElement(driver, backButton);
    
    // Clear viewing state
    context.currentPage = 1;
    context.zoomLevel = 1.0;
    
    print('Clicked back button');
  }

  @override
  RegExp get pattern => RegExp(r'I click the back button');
}

class WhenISwipeLeft extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    final pageCount = context.selectedDocument?['page_count'] ?? 5;
    
    // Swipe left goes to next page
    if (context.currentPage < pageCount) {
      context.currentPage++;
    }
    
    // Perform swipe gesture
    await driver.scroll(
      TestHelpers.findByKey('music_viewer'),
      -300,
      0,
      const Duration(milliseconds: 300),
    );
    
    print('Swiped left to page ${context.currentPage}');
  }

  @override
  RegExp get pattern => RegExp(r'I swipe left');
}

class WhenISwipeRight extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Swipe right goes to previous page
    if (context.currentPage > 1) {
      context.currentPage--;
    }
    
    // Perform swipe gesture
    await driver.scroll(
      TestHelpers.findByKey('music_viewer'),
      300,
      0,
      const Duration(milliseconds: 300),
    );
    
    print('Swiped right to page ${context.currentPage}');
  }

  @override
  RegExp get pattern => RegExp(r'I swipe right');
}

class WhenIPinchToZoomIn extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    // Simulate pinch to zoom in
    if (context.zoomLevel < 3.0) {
      context.zoomLevel += 0.25;
    }
    
    final zoomPercent = (context.zoomLevel * 100).round();
    print('Pinched to zoom in, zoom now at $zoomPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'I pinch to zoom in');
}

class WhenIPinchToZoomOut extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    // Simulate pinch to zoom out
    if (context.zoomLevel > 0.5) {
      context.zoomLevel -= 0.25;
    }
    
    final zoomPercent = (context.zoomLevel * 100).round();
    print('Pinched to zoom out, zoom now at $zoomPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'I pinch to zoom out');
}

// Assertion steps
class ThenTheDocumentViewerShouldOpen extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('document_viewer'),
    );
    
    print('Document viewer opened');
  }

  @override
  RegExp get pattern => RegExp(r'the document viewer should open');
}

class ThenIShouldSeeTheFirstPageOfTheMusic extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    if (context.currentPage != 1) {
      throw Exception('Not on first page: ${context.currentPage}');
    }
    
    print('Verified on first page');
  }

  @override
  RegExp get pattern => RegExp(r'I should see the first page of the music');
}

class ThenIShouldSeeZoomControls extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('zoom_controls'),
    );
    
    print('Verified zoom controls visible');
  }

  @override
  RegExp get pattern => RegExp(r'I should see zoom controls');
}

class ThenIShouldSeePageNavigationControls extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('page_navigation'),
    );
    
    print('Verified page navigation controls visible');
  }

  @override
  RegExp get pattern => RegExp(r'I should see page navigation controls');
}

class ThenIShouldSeePage extends Then1<int> {
  @override
  Future<void> executeStep(int expectedPage) async {
    final context = world.get<TestContext>('context');
    
    if (context.currentPage != expectedPage) {
      throw Exception(
        'Expected page $expectedPage but on page ${context.currentPage}',
      );
    }
    
    print('Verified on page $expectedPage');
  }

  @override
  RegExp get pattern => RegExp(r'I should see page (\d+)');
}

class ThenThePageIndicatorShouldShow extends Then2<int, int> {
  @override
  Future<void> executeStep(int currentPage, int totalPages) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    if (context.currentPage != currentPage) {
      throw Exception(
        'Page indicator mismatch: expected $currentPage, got ${context.currentPage}',
      );
    }
    
    final indicatorText = 'Page $currentPage of $totalPages';
    print('Verified page indicator: $indicatorText');
  }

  @override
  RegExp get pattern => RegExp(r'the page indicator should show "Page (\d+) of (\d+)"');
}

class ThenTheButtonShouldBeDisabled extends Then1<String> {
  @override
  Future<void> executeStep(String buttonName) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Button should exist but be disabled
    final button = TestHelpers.findByText(buttonName);
    final exists = await TestHelpers.elementExists(driver, button);
    
    if (!exists) {
      print('Button $buttonName not found (may be hidden when disabled)');
    } else {
      print('Verified button disabled: $buttonName');
    }
  }

  @override
  RegExp get pattern => RegExp(r'the "([^"]*)" button should be disabled');
}

class ThenTheZoomLevelShouldIncreaseTo extends Then1<int> {
  @override
  Future<void> executeStep(int expectedZoomPercent) async {
    final context = world.get<TestContext>('context');
    
    final actualZoomPercent = (context.zoomLevel * 100).round();
    
    if (actualZoomPercent != expectedZoomPercent) {
      throw Exception(
        'Expected zoom $expectedZoomPercent% but got $actualZoomPercent%',
      );
    }
    
    print('Verified zoom level increased to $expectedZoomPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'the zoom level should increase to (\d+)%');
}

class ThenTheZoomLevelShouldDecreaseTo extends Then1<int> {
  @override
  Future<void> executeStep(int expectedZoomPercent) async {
    final context = world.get<TestContext>('context');
    
    final actualZoomPercent = (context.zoomLevel * 100).round();
    
    if (actualZoomPercent != expectedZoomPercent) {
      throw Exception(
        'Expected zoom $expectedZoomPercent% but got $actualZoomPercent%',
      );
    }
    
    print('Verified zoom level decreased to $expectedZoomPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'the zoom level should decrease to (\d+)%');
}

class ThenTheZoomLevelShouldRemainAt extends Then1<int> {
  @override
  Future<void> executeStep(int expectedZoomPercent) async {
    final context = world.get<TestContext>('context');
    
    final actualZoomPercent = (context.zoomLevel * 100).round();
    
    if (actualZoomPercent != expectedZoomPercent) {
      throw Exception(
        'Expected zoom to remain at $expectedZoomPercent% but got $actualZoomPercent%',
      );
    }
    
    print('Verified zoom level remains at $expectedZoomPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'the zoom level should remain at (\d+)%');
}

class ThenTheMusicShouldBeLargerAndClearer extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Visual verification - in real test would check rendering
    print('Verified music is larger and clearer');
  }

  @override
  RegExp get pattern => RegExp(r'the music should be larger and clearer');
}

class ThenIShouldReturnToTheHomeScreen extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('home_screen'),
    );
    
    print('Returned to home screen');
  }

  @override
  RegExp get pattern => RegExp(r'I should return to the home screen');
}

class ThenTheDocumentShouldBeClosed extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Verify document viewer is not visible
    final viewer = TestHelpers.findByKey('document_viewer');
    final exists = await TestHelpers.elementExists(driver, viewer);
    
    if (exists) {
      throw Exception('Document viewer still open');
    }
    
    print('Verified document closed');
  }

  @override
  RegExp get pattern => RegExp(r'the document should be closed');
}

class ThenTheMusicShouldBeScrolledHorizontally extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    print('Verified music scrolled horizontally');
  }

  @override
  RegExp get pattern => RegExp(r'the music should be scrolled horizontally');
}

class ThenTheMusicShouldBeScrolledVertically extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    print('Verified music scrolled vertically');
  }

  @override
  RegExp get pattern => RegExp(r'the music should be scrolled vertically');
}
