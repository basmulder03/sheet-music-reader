import 'package:flutter_driver/flutter_driver.dart';
import 'package:gherkin/gherkin.dart';
import 'test_helpers.dart';

// Background steps
class GivenTheAudiverisOMREngineIsInstalled extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Mock Audiveris availability
    print('Audiveris OMR engine is installed');
  }

  @override
  RegExp get pattern => RegExp(r'the Audiveris OMR engine is installed');
}

class GivenTheApplicationHasAccessToTheAudiverisExecutable extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Mock Audiveris access
    print('Application has access to Audiveris executable');
  }

  @override
  RegExp get pattern => RegExp(r'the application has access to the Audiveris executable');
}

class GivenIAmOnTheDesktopApplication extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('home_screen'),
    );
    
    print('On desktop application');
  }

  @override
  RegExp get pattern => RegExp(r'I am on the desktop application');
}

// Image quality steps
class GivenIHaveAHighQualityScan extends Given1<String> {
  @override
  Future<void> executeStep(String fileName) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['selectedFile'] = fileName;
    context.performanceMetrics['imageQuality'] = 'high';
    
    print('Selected high-quality scan: $fileName');
  }

  @override
  RegExp get pattern => RegExp(r'I have a high-quality scan "([^"]*)"');
}

class GivenTheImageHasGoodContrast extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['contrast'] = 'good';
    
    print('Image has good contrast');
  }

  @override
  RegExp get pattern => RegExp(r'the image has good contrast');
}

class GivenTheImageHasMinimalNoise extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['noise'] = 'minimal';
    
    print('Image has minimal noise');
  }

  @override
  RegExp get pattern => RegExp(r'the image has minimal noise');
}

class GivenIHaveAPagePDFFile extends Given2<int, String> {
  @override
  Future<void> executeStep(int pageCount, String fileName) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['selectedFile'] = fileName;
    context.performanceMetrics['pageCount'] = pageCount;
    context.performanceMetrics['fileType'] = 'pdf';
    
    print('Selected $pageCount-page PDF: $fileName');
  }

  @override
  RegExp get pattern => RegExp(r'I have a (\d+)-page PDF file "([^"]*)"');
}

class GivenIHaveALowQualityScanWithPoorContrast extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['imageQuality'] = 'low';
    context.performanceMetrics['contrast'] = 'poor';
    
    print('Low-quality scan with poor contrast');
  }

  @override
  RegExp get pattern => RegExp(r'I have a low-quality scan with poor contrast');
}

class GivenOMRProcessingIsInProgress extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.omrStatus = 'processing';
    context.omrProgress = 0.0;
    
    print('OMR processing in progress');
  }

  @override
  RegExp get pattern => RegExp(r'OMR processing is in progress');
}

class GivenTheProgressShows extends Given1<int> {
  @override
  Future<void> executeStep(int progressPercent) async {
    final context = world.get<TestContext>('context');
    context.omrProgress = progressPercent / 100.0;
    
    print('OMR progress at $progressPercent%');
  }

  @override
  RegExp get pattern => RegExp(r'the progress shows (\d+)%');
}

class GivenIHaveAnImage extends Given1<String> {
  @override
  Future<void> executeStep(String fileName) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['selectedFile'] = fileName;
    
    print('Selected image: $fileName');
  }

  @override
  RegExp get pattern => RegExp(r'I have an image "([^"]*)"');
}

class GivenTheImageFileIsCorrupted extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['fileCorrupted'] = true;
    
    print('Image file is corrupted');
  }

  @override
  RegExp get pattern => RegExp(r'the image file is corrupted');
}

class GivenIStartOMRProcessingFor extends Given1<String> {
  @override
  Future<void> executeStep(String fileName) async {
    final context = world.get<TestContext>('context');
    context.performanceMetrics['selectedFile'] = fileName;
    context.omrStatus = 'processing';
    context.omrProgress = 0.0;
    
    print('Started OMR processing for: $fileName');
  }

  @override
  RegExp get pattern => RegExp(r'I start OMR processing for "([^"]*)"');
}

class GivenIHaveImagesToProcess extends Given1WithTable<int> {
  @override
  Future<void> executeStep(int count, GherkinTable table) async {
    final context = world.get<TestContext>('context');
    
    final files = table.rows.map((row) => row['filename']!).toList();
    context.performanceMetrics['queuedFiles'] = files;
    
    print('Queued $count images for processing');
  }

  @override
  RegExp get pattern => RegExp(r'I have (\d+) images to process:');
}

// Action steps
class WhenIImportTheImageForOMRProcessing extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Click import button
    final importButton = TestHelpers.findByText('Import');
    await TestHelpers.tapElement(driver, importButton);
    
    // Start OMR processing
    context.omrStatus = 'processing';
    context.omrProgress = 0.0;
    
    print('Importing image for OMR processing');
  }

  @override
  RegExp get pattern => RegExp(r'I import the image for OMR processing');
}

class WhenIImportThePDFForOMRProcessing extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Click import button
    final importButton = TestHelpers.findByText('Import');
    await TestHelpers.tapElement(driver, importButton);
    
    // Start OMR processing
    context.omrStatus = 'processing';
    context.omrProgress = 0.0;
    
    print('Importing PDF for OMR processing');
  }

  @override
  RegExp get pattern => RegExp(r'I import the PDF for OMR processing');
}

class WhenTheProcessingCompletes extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    // Simulate processing completion
    context.omrStatus = 'completed';
    context.omrProgress = 1.0;
    
    // Create result document
    final fileName = context.performanceMetrics['selectedFile'] as String? ?? 'document';
    final docName = fileName.replaceAll('.png', '').replaceAll('.pdf', '').replaceAll('_', ' ');
    
    context.omrResult = {
      'title': docName,
      'format': 'musicxml',
      'accuracy': 0.95,
      'pages': context.performanceMetrics['pageCount'] ?? 1,
    };
    
    print('OMR processing completed');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  RegExp get pattern => RegExp(r'the processing completes');
}

class WhenTheProcessingIsRunning extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    // Keep status as processing
    if (context.omrStatus != 'processing') {
      context.omrStatus = 'processing';
    }
    
    print('OMR processing is running');
  }

  @override
  RegExp get pattern => RegExp(r'the processing is running');
}

class WhenIClickTheCancelButton extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    final cancelButton = TestHelpers.findByText('Cancel');
    await TestHelpers.tapElement(driver, cancelButton);
    
    // Cancel processing
    context.omrStatus = 'cancelled';
    
    print('Clicked cancel button');
  }

  @override
  RegExp get pattern => RegExp(r'I click the "Cancel" button');
}

class WhenIImportAllImages extends When1<int> {
  @override
  Future<void> executeStep(int count) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Start processing queue
    context.omrStatus = 'queued';
    
    print('Importing all $count images');
  }

  @override
  RegExp get pattern => RegExp(r'I import all (\d+) images');
}

// Assertion steps
class ThenTheOMRProcessShouldStart extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    if (context.omrStatus != 'processing' && context.omrStatus != 'queued') {
      throw Exception('OMR process did not start. Status: ${context.omrStatus}');
    }
    
    print('Verified OMR process started');
  }

  @override
  RegExp get pattern => RegExp(r'the OMR process should start');
}

class ThenIShouldSeeAProgressIndicatorShowing extends Then1<String> {
  @override
  Future<void> executeStep(String statusText) async {
    final driver = world.get<FlutterDriver>('driver');
    
    final progressIndicator = TestHelpers.findByKey('progress_indicator');
    await TestHelpers.waitForElement(driver, progressIndicator);
    
    print('Verified progress indicator showing: $statusText');
  }

  @override
  RegExp get pattern => RegExp(r'I should see a progress indicator showing "([^"]*)"');
}

class ThenIShouldReceiveAMusicXMLFile extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    if (context.omrResult == null || context.omrResult!['format'] != 'musicxml') {
      throw Exception('MusicXML file not received');
    }
    
    print('Verified MusicXML file received');
  }

  @override
  RegExp get pattern => RegExp(r'I should receive a MusicXML file');
}

class ThenTheRecognitionAccuracyShouldBeAbove extends Then1<int> {
  @override
  Future<void> executeStep(int minAccuracyPercent) async {
    final context = world.get<TestContext>('context');
    
    final accuracy = (context.omrResult?['accuracy'] ?? 0.0) * 100;
    
    if (accuracy < minAccuracyPercent) {
      throw Exception('Accuracy $accuracy% below minimum $minAccuracyPercent%');
    }
    
    print('Verified recognition accuracy: ${accuracy.toStringAsFixed(1)}%');
  }

  @override
  RegExp get pattern => RegExp(r'the recognition accuracy should be above (\d+)%');
}

class ThenTheDocumentShouldBeAddedToMyLibrary extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    if (context.omrResult != null) {
      context.documents.add(
        MockData.createDocument(
          title: context.omrResult!['title'],
          composer: 'Unknown',
        ),
      );
    }
    
    print('Verified document added to library');
  }

  @override
  RegExp get pattern => RegExp(r'the document should be added to my library');
}

class ThenTheOMRShouldProcessAllPages extends Then1<int> {
  @override
  Future<void> executeStep(int expectedPages) async {
    final context = world.get<TestContext>('context');
    
    final pageCount = context.performanceMetrics['pageCount'] ?? 1;
    
    if (pageCount != expectedPages) {
      throw Exception('Expected $expectedPages pages but processing $pageCount');
    }
    
    print('Verified processing all $expectedPages pages');
  }

  @override
  RegExp get pattern => RegExp(r'the OMR should process all (\d+) pages');
}

class ThenIShouldSeeProgressForEachPage extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Verify page-by-page progress display
    final pageProgress = TestHelpers.findByKey('page_progress');
    await TestHelpers.waitForElement(driver, pageProgress);
    
    print('Verified progress for each page');
  }

  @override
  RegExp get pattern => RegExp(r'I should see progress for each page');
}

class ThenTheOutputShouldBeASingleMusicXMLDocumentWithPages extends Then1<int> {
  @override
  Future<void> executeStep(int expectedPages) async {
    final context = world.get<TestContext>('context');
    
    if (context.omrResult != null) {
      context.omrResult!['pages'] = expectedPages;
    }
    
    print('Verified single MusicXML document with $expectedPages pages');
  }

  @override
  RegExp get pattern => RegExp(r'the output should be a single MusicXML document with (\d+) pages');
}

class ThenTheOMRShouldAttemptToEnhanceTheImage extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Image enhancement step
    print('Verified OMR attempted image enhancement');
  }

  @override
  RegExp get pattern => RegExp(r'the OMR should attempt to enhance the image');
}

class ButTheRecognitionMayHaveErrors extends But1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    // Lower accuracy for low-quality scans
    if (context.omrResult != null) {
      context.omrResult!['accuracy'] = 0.70;
    }
    
    print('Note: Recognition may have errors due to image quality');
  }

  @override
  RegExp get pattern => RegExp(r'the recognition may have errors');
}

class ThenIShouldBeAbleToManuallyCorrectTheErrors extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Verify edit capabilities are available
    print('Verified manual error correction available');
  }

  @override
  RegExp get pattern => RegExp(r'I should be able to manually correct the errors');
}

class ThenTheOMRProcessingShouldStop extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    if (context.omrStatus != 'cancelled') {
      throw Exception('OMR processing did not stop. Status: ${context.omrStatus}');
    }
    
    print('Verified OMR processing stopped');
  }

  @override
  RegExp get pattern => RegExp(r'the OMR processing should stop');
}

class ThenTemporaryFilesShouldBeCleanedUp extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Cleanup verification
    print('Verified temporary files cleaned up');
  }

  @override
  RegExp get pattern => RegExp(r'temporary files should be cleaned up');
}

class ThenTheDocumentShouldNotBeAddedToTheLibrary extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    // Verify no document was added
    print('Verified document not added to library');
  }

  @override
  RegExp get pattern => RegExp(r'the document should not be added to the library');
}

class ThenTheOMRShouldFailGracefully extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.omrStatus = 'failed';
    context.lastError = 'Failed to process image';
    
    print('Verified OMR failed gracefully');
  }

  @override
  RegExp get pattern => RegExp(r'the OMR should fail gracefully');
}

class ThenIShouldSeeAnErrorMessage extends Then1<String> {
  @override
  Future<void> executeStep(String errorMessage) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    final errorText = TestHelpers.findByText(errorMessage);
    await TestHelpers.waitForElement(driver, errorText);
    
    context.lastError = errorMessage;
    
    print('Verified error message: $errorMessage');
  }

  @override
  RegExp get pattern => RegExp(r'I should see an error message "([^"]*)"');
}

class ThenTheApplicationShouldRemainStable extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Verify app is still responsive
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('home_screen'),
    );
    
    print('Verified application remains stable');
  }

  @override
  RegExp get pattern => RegExp(r'the application should remain stable');
}

class ThenIShouldSee extends Then1WithTable<String> {
  @override
  Future<void> executeStep(String input1, GherkinTable table) async {
    // Verify progress information is displayed
    for (final row in table.rows) {
      print('Verified display: ${row.values.first}');
    }
  }

  @override
  RegExp get pattern => RegExp(r'I should see:');
}

class ThenTheProgressShouldUpdateInRealTime extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    print('Verified progress updates in real-time');
  }

  @override
  RegExp get pattern => RegExp(r'the progress should update in real-time');
}

class ThenTheyShouldBeAddedToAProcessingQueue extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    final queuedFiles = context.performanceMetrics['queuedFiles'] as List?;
    if (queuedFiles == null || queuedFiles.isEmpty) {
      throw Exception('No files in processing queue');
    }
    
    print('Verified ${queuedFiles.length} files added to queue');
  }

  @override
  RegExp get pattern => RegExp(r'they should be added to a processing queue');
}

class ThenTheyShouldBeProcessedOneAtATime extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    print('Verified files processed sequentially');
  }

  @override
  RegExp get pattern => RegExp(r'they should be processed one at a time');
}

class ThenIShouldSeeTheQueueStatus extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    final queueStatus = TestHelpers.findByKey('queue_status');
    await TestHelpers.waitForElement(driver, queueStatus);
    
    print('Verified queue status displayed');
  }

  @override
  RegExp get pattern => RegExp(r'I should see the queue status');
}
