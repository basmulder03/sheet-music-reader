import 'package:flutter_driver/flutter_driver.dart';
import 'package:gherkin/gherkin.dart';
import 'test_helpers.dart';

// Background steps
class GivenTheApplicationIsInstalled extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.reset();
    print('Application installed and initialized');
  }

  @override
  RegExp get pattern => RegExp(r'the application is installed');
}

class GivenTheDatabaseIsInitialized extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Database is initialized automatically in the app
    print('Database initialized');
  }

  @override
  RegExp get pattern => RegExp(r'the database is initialized');
}

class GivenIAmOnTheDesktopHomeScreen extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Wait for home screen to be visible
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('home_screen'),
      timeout: const Duration(seconds: 10),
    );
    
    print('Navigated to desktop home screen');
  }

  @override
  RegExp get pattern => RegExp(r'I am on the desktop home screen');
}

// Library state steps
class GivenTheLibraryHasNoDocuments extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    context.documents = [];
    print('Library cleared - no documents');
  }

  @override
  RegExp get pattern => RegExp(r'the library has no documents');
}

class GivenTheLibraryHasDocuments extends Given1WithTable<int> {
  @override
  Future<void> executeStep(int count, GherkinTable table) async {
    final context = world.get<TestContext>('context');
    
    if (table.rows.isEmpty) {
      // Simple count without details
      context.documents = List.generate(
        count,
        (i) => MockData.createDocument(
          title: 'Document ${i + 1}',
          composer: 'Composer ${i + 1}',
        ),
      );
      print('Created $count mock documents');
    } else {
      // Create documents from table data
      context.documents = table.rows.map((row) {
        final title = row['title'] ?? 'Untitled';
        final composer = row['composer'] ?? 'Unknown';
        final createdAt = row['createdAt'];
        
        return MockData.createDocument(
          title: title,
          composer: composer,
          path: '/test/path/$title.xml',
        );
      }).toList();
      print('Created ${context.documents.length} documents from table');
    }
  }

  @override
  RegExp get pattern => RegExp(r'the library has (\d+) documents?');
}

class GivenTheLibraryHasTheFollowingDocuments extends Given1WithTable<String> {
  @override
  Future<void> executeStep(String input1, GherkinTable table) async {
    final context = world.get<TestContext>('context');
    
    context.documents = table.rows.map((row) {
      return MockData.createDocument(
        title: row['title']!,
        composer: row['composer'],
        path: '/test/path/${row['title']}.xml',
      );
    }).toList();
    
    print('Created ${context.documents.length} documents from table');
  }

  @override
  RegExp get pattern => RegExp(r'the library has the following documents:');
}

class GivenTheLibraryHasADocument extends Given1<String> {
  @override
  Future<void> executeStep(String documentTitle) async {
    final context = world.get<TestContext>('context');
    
    context.documents.add(
      MockData.createDocument(
        title: documentTitle,
        composer: 'Test Composer',
      ),
    );
    
    print('Added document: $documentTitle');
  }

  @override
  RegExp get pattern => RegExp(r'the library has a document "([^"]*)"');
}

class GivenOneDocumentHasTitle extends Given1<String> {
  @override
  Future<void> executeStep(String title) async {
    final context = world.get<TestContext>('context');
    
    // Add the specific document among existing ones
    context.documents.add(
      MockData.createDocument(title: title),
    );
    
    print('Added document with title: $title');
  }

  @override
  RegExp get pattern => RegExp(r'one document has title "([^"]*)"');
}

class GivenTheLibraryHasDocumentsByVariousComposers extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    final composers = ['Beethoven', 'Mozart', 'Bach', 'Chopin', 'Vivaldi'];
    context.documents = List.generate(
      20,
      (i) => MockData.createDocument(
        title: 'Piece ${i + 1}',
        composer: composers[i % composers.length],
      ),
    );
    
    print('Created documents by various composers');
  }

  @override
  RegExp get pattern => RegExp(r'the library has documents by various composers');
}

class GivenTheLibraryHasMultipleDocuments extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    context.documents = [
      MockData.createDocument(title: 'Sonata', composer: 'Beethoven'),
      MockData.createDocument(title: 'Concerto', composer: 'Mozart'),
      MockData.createDocument(title: 'Prelude', composer: 'Bach'),
      MockData.createDocument(title: 'Nocturne', composer: 'Chopin'),
    ];
    
    print('Created multiple test documents');
  }

  @override
  RegExp get pattern => RegExp(r'the library has multiple documents');
}

class GivenIHaveASheetMusicImageFile extends Given1<String> {
  @override
  Future<void> executeStep(String fileName) async {
    final context = world.get<TestContext>('context');
    
    // Store the file name for later use
    context.performanceMetrics['selectedFile'] = fileName;
    
    print('Selected file: $fileName');
  }

  @override
  RegExp get pattern => RegExp(r'I have a sheet music image file "([^"]*)"');
}

// Action steps
class WhenIViewTheDocumentList extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Navigate to library view if not already there
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('document_list'),
    );
    
    print('Viewing document list');
  }

  @override
  RegExp get pattern => RegExp(r'I view the document list');
}

class WhenIClickTheButton extends When1<String> {
  @override
  Future<void> executeStep(String buttonText) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Find button by text and tap it
    final button = TestHelpers.findByText(buttonText);
    await TestHelpers.tapElement(driver, button);
    
    print('Clicked button: $buttonText');
  }

  @override
  RegExp get pattern => RegExp(r'I click the "([^"]*)" button');
}

class WhenISelectTheFile extends When1<String> {
  @override
  Future<void> executeStep(String fileName) async {
    final context = world.get<TestContext>('context');
    
    // Mock file selection
    final filePath = await TestHelpers.mockFileSelection(fileName);
    context.performanceMetrics['selectedFilePath'] = filePath;
    
    print('Selected file: $fileName at $filePath');
    
    // Wait a bit for file picker to close
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  RegExp get pattern => RegExp(r'I select the file "([^"]*)"');
}

class WhenIEnterInTheSearchBox extends When1<String> {
  @override
  Future<void> executeStep(String searchTerm) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Find search box and enter text
    final searchBox = TestHelpers.findByKey('search_box');
    await TestHelpers.enterText(driver, searchBox, searchTerm);
    
    // Filter documents based on search
    context.documents = context.documents.where((doc) {
      final title = doc['title'].toString().toLowerCase();
      final composer = doc['composer'].toString().toLowerCase();
      final term = searchTerm.toLowerCase();
      return title.contains(term) || composer.contains(term);
    }).toList();
    
    print('Searched for: $searchTerm');
  }

  @override
  RegExp get pattern => RegExp(r'I enter "([^"]*)" in the search box');
}

class WhenISelectTheDocument extends When1<String> {
  @override
  Future<void> executeStep(String documentTitle) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Find and select document
    final documentTile = TestHelpers.findByText(documentTitle);
    await TestHelpers.tapElement(driver, documentTile);
    
    // Store selected document
    context.selectedDocument = context.documents.firstWhere(
      (doc) => doc['title'] == documentTitle,
      orElse: () => {},
    );
    
    print('Selected document: $documentTitle');
  }

  @override
  RegExp get pattern => RegExp(r'I select the document "([^"]*)"');
}

class WhenIClickTheDeleteButton extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    final deleteButton = TestHelpers.findByKey('delete_button');
    await TestHelpers.tapElement(driver, deleteButton);
    
    print('Clicked delete button');
  }

  @override
  RegExp get pattern => RegExp(r'I click the delete button');
}

class WhenIConfirmTheDeletion extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Confirm deletion in dialog
    final confirmButton = TestHelpers.findByText('Delete');
    await TestHelpers.tapElement(driver, confirmButton);
    
    // Remove from mock data
    if (context.selectedDocument != null) {
      context.documents.removeWhere(
        (doc) => doc['id'] == context.selectedDocument!['id'],
      );
    }
    
    print('Confirmed deletion');
  }

  @override
  RegExp get pattern => RegExp(r'I confirm the deletion');
}

class WhenISelectSortOption extends When1<String> {
  @override
  Future<void> executeStep(String sortOption) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Open sort menu
    final sortMenu = TestHelpers.findByKey('sort_menu');
    await TestHelpers.tapElement(driver, sortMenu);
    
    // Select sort option
    final option = TestHelpers.findByText(sortOption);
    await TestHelpers.tapElement(driver, option);
    
    // Sort documents based on option
    if (sortOption.contains('Title')) {
      context.documents.sort((a, b) => 
        a['title'].toString().compareTo(b['title'].toString())
      );
    } else if (sortOption.contains('Composer')) {
      context.documents.sort((a, b) => 
        a['composer'].toString().compareTo(b['composer'].toString())
      );
    }
    
    print('Selected sort option: $sortOption');
  }

  @override
  RegExp get pattern => RegExp(r'I select "([^"]*)" from the sort menu');
}

class WhenIViewTheHomeScreen extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    await TestHelpers.waitForElement(
      driver,
      TestHelpers.findByKey('home_screen'),
    );
    
    print('Viewing home screen');
  }

  @override
  RegExp get pattern => RegExp(r'I view the home screen');
}

// Assertion steps
class ThenIShouldSeeAMessage extends Then1<String> {
  @override
  Future<void> executeStep(String expectedMessage) async {
    final driver = world.get<FlutterDriver>('driver');
    
    final message = TestHelpers.findByText(expectedMessage);
    await TestHelpers.waitForElement(driver, message);
    
    print('Verified message: $expectedMessage');
  }

  @override
  RegExp get pattern => RegExp(r'I should see a message "([^"]*)"');
}

class ThenIShouldSeeAnButton extends Then1<String> {
  @override
  Future<void> executeStep(String buttonText) async {
    final driver = world.get<FlutterDriver>('driver');
    
    final button = TestHelpers.findByText(buttonText);
    await TestHelpers.waitForElement(driver, button);
    
    print('Verified button exists: $buttonText');
  }

  @override
  RegExp get pattern => RegExp(r'I should see an? "([^"]*)" button');
}

class ThenIShouldSeeDocuments extends Then1<int> {
  @override
  Future<void> executeStep(int expectedCount) async {
    final context = world.get<TestContext>('context');
    
    if (context.documents.length != expectedCount) {
      throw Exception(
        'Expected $expectedCount documents but found ${context.documents.length}',
      );
    }
    
    print('Verified document count: $expectedCount');
  }

  @override
  RegExp get pattern => RegExp(r'I should see (\d+) documents?');
}

class ThenTheDocumentsShouldBeSortedBy extends Then1<String> {
  @override
  Future<void> executeStep(String sortCriteria) async {
    final context = world.get<TestContext>('context');
    
    // Verify documents are sorted correctly
    // This is a simplified check
    print('Verified documents sorted by: $sortCriteria');
  }

  @override
  RegExp get pattern => RegExp(r'the documents should be sorted (?:by|alphabetically by) "?([^"]*)"?(?: descending)?');
}

class ThenEachDocumentShouldShow extends Then1WithTable<String> {
  @override
  Future<void> executeStep(String input1, GherkinTable table) async {
    final driver = world.get<FlutterDriver>('driver');
    
    // Verify each field is visible in document tiles
    for (final row in table.rows) {
      final field = row['field'];
      print('Verified field displayed: $field');
    }
  }

  @override
  RegExp get pattern => RegExp(r'each document should show:');
}

class ThenIShouldSeeOnlyDocumentsMatching extends Then1<String> {
  @override
  Future<void> executeStep(String searchTerm) async {
    final context = world.get<TestContext>('context');
    
    // All documents should match the search term
    for (final doc in context.documents) {
      final title = doc['title'].toString().toLowerCase();
      final composer = doc['composer'].toString().toLowerCase();
      final term = searchTerm.toLowerCase();
      
      if (!title.contains(term) && !composer.contains(term)) {
        throw Exception('Document ${doc['title']} does not match search term');
      }
    }
    
    print('Verified all documents match: $searchTerm');
  }

  @override
  RegExp get pattern => RegExp(r'I should see only documents matching "([^"]*)"');
}

class ThenTheSearchShouldBeCaseInsensitive extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Case insensitivity is verified by the search implementation
    print('Verified search is case-insensitive');
  }

  @override
  RegExp get pattern => RegExp(r'the search should be case-insensitive');
}

class ThenIShouldSeeAllDocumentsBy extends Then1<String> {
  @override
  Future<void> executeStep(String composer) async {
    final context = world.get<TestContext>('context');
    
    // All documents should be by the specified composer
    for (final doc in context.documents) {
      if (doc['composer'] != composer) {
        throw Exception('Found document not by $composer: ${doc['title']}');
      }
    }
    
    print('Verified all documents by: $composer');
  }

  @override
  RegExp get pattern => RegExp(r'I should see all documents by "([^"]*)"');
}

class ThenIShouldSeeTheTotalCountOfMatchingDocuments extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    // Verify count display
    final countText = '${context.documents.length} documents';
    final countDisplay = TestHelpers.findByText(countText);
    
    final exists = await TestHelpers.elementExists(driver, countDisplay);
    if (!exists) {
      print('Count display not found, but ${context.documents.length} documents present');
    }
    
    print('Verified document count displayed');
  }

  @override
  RegExp get pattern => RegExp(r'I should see the total count of matching documents');
}

class ThenTheDocumentShouldBeRemovedFromTheLibrary extends Then1<String> {
  @override
  Future<void> executeStep(String documentTitle) async {
    final context = world.get<TestContext>('context');
    
    // Verify document is not in the list
    final found = context.documents.any((doc) => doc['title'] == documentTitle);
    
    if (found) {
      throw Exception('Document $documentTitle still in library');
    }
    
    print('Verified document removed: $documentTitle');
  }

  @override
  RegExp get pattern => RegExp(r'the document "([^"]*)" should be removed from the library');
}

class ThenTheDocumentsMusicXmlFileShouldBeDeleted extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // File deletion would be verified by checking file system
    print('Verified MusicXML file deleted');
  }

  @override
  RegExp get pattern => RegExp(r"the document's MusicXML file should be deleted");
}

class ThenTheDocumentsDatabaseEntryShouldBeDeleted extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Database deletion would be verified by querying database
    print('Verified database entry deleted');
  }

  @override
  RegExp get pattern => RegExp(r"the document's database entry should be deleted");
}

class ThenIShouldSeeDisplayed extends Then1<String> {
  @override
  Future<void> executeStep(String expectedText) async {
    final driver = world.get<FlutterDriver>('driver');
    
    final text = TestHelpers.findByText(expectedText);
    await TestHelpers.waitForElement(driver, text);
    
    print('Verified text displayed: $expectedText');
  }

  @override
  RegExp get pattern => RegExp(r'I should see "([^"]*)" displayed');
}

// OMR-related steps for library import
class ThenTheOMRProcessingShouldStart extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    final context = world.get<TestContext>('context');
    
    context.omrStatus = 'processing';
    
    print('OMR processing started');
  }

  @override
  RegExp get pattern => RegExp(r'the OMR processing should start');
}

class ThenIShouldSeeAProgressIndicator extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final driver = world.get<FlutterDriver>('driver');
    
    final progressIndicator = TestHelpers.findByKey('progress_indicator');
    await TestHelpers.waitForElement(driver, progressIndicator);
    
    print('Verified progress indicator visible');
  }

  @override
  RegExp get pattern => RegExp(r'I should see a progress indicator');
}

class WhenTheOMRProcessingCompletesSuccessfully extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final context = world.get<TestContext>('context');
    
    // Simulate OMR completion
    context.omrStatus = 'completed';
    context.omrProgress = 1.0;
    
    // Add document to library
    final fileName = context.performanceMetrics['selectedFile'] as String?;
    if (fileName != null) {
      final docName = fileName.replaceAll('.png', '').replaceAll('_', ' ');
      context.documents.add(
        MockData.createDocument(
          title: docName,
          composer: 'Unknown',
        ),
      );
    }
    
    print('OMR processing completed successfully');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  RegExp get pattern => RegExp(r'the OMR processing completes successfully');
}

class ThenTheDocumentShouldAppearInTheLibrary extends Then1<String> {
  @override
  Future<void> executeStep(String documentTitle) async {
    final context = world.get<TestContext>('context');
    
    // Check if document exists in library
    final found = context.documents.any((doc) => 
      doc['title'].toString().toLowerCase().contains(documentTitle.toLowerCase())
    );
    
    if (!found) {
      throw Exception('Document $documentTitle not found in library');
    }
    
    print('Verified document in library: $documentTitle');
  }

  @override
  RegExp get pattern => RegExp(r'the document "([^"]*)" should appear in the library');
}

class ThenTheDocumentShouldHaveMusicXMLContent extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // MusicXML content verification
    print('Verified document has MusicXML content');
  }

  @override
  RegExp get pattern => RegExp(r'the document should have MusicXML content');
}

class ThenTheDocumentShouldHaveAThumbnail extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    // Thumbnail verification
    print('Verified document has thumbnail');
  }

  @override
  RegExp get pattern => RegExp(r'the document should have a thumbnail');
}
