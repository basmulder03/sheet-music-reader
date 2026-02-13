import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:glob/glob.dart';

// Import step definition files
import '../features/step_definitions/test_helpers.dart';
import '../features/step_definitions/library_steps.dart';
import '../features/step_definitions/viewer_steps.dart';
import '../features/step_definitions/omr_steps.dart';

Future<void> main() {
  final config = FlutterTestConfiguration()
    ..features = [Glob(r"features/**.feature")]
    ..reporters = [
      ProgressReporter(),
      TestRunSummaryReporter(),
      JsonReporter(path: './report.json'),
    ]
    ..stepDefinitions = [
      // Library Management Steps
      GivenTheApplicationIsInstalled(),
      GivenTheDatabaseIsInitialized(),
      GivenIAmOnTheDesktopHomeScreen(),
      GivenTheLibraryHasNoDocuments(),
      GivenTheLibraryHasDocuments(),
      GivenTheLibraryHasTheFollowingDocuments(),
      GivenTheLibraryHasADocument(),
      GivenOneDocumentHasTitle(),
      GivenTheLibraryHasDocumentsByVariousComposers(),
      GivenTheLibraryHasMultipleDocuments(),
      GivenIHaveASheetMusicImageFile(),
      WhenIViewTheDocumentList(),
      WhenIClickTheButton(),
      WhenISelectTheFile(),
      WhenIEnterInTheSearchBox(),
      WhenISelectTheDocument(),
      WhenIClickTheDeleteButton(),
      WhenIConfirmTheDeletion(),
      WhenISelectSortOption(),
      WhenIViewTheHomeScreen(),
      ThenIShouldSeeAMessage(),
      ThenIShouldSeeAnButton(),
      ThenIShouldSeeDocuments(),
      ThenTheDocumentsShouldBeSortedBy(),
      ThenEachDocumentShouldShow(),
      ThenIShouldSeeOnlyDocumentsMatching(),
      ThenTheSearchShouldBeCaseInsensitive(),
      ThenIShouldSeeAllDocumentsBy(),
      ThenIShouldSeeTheTotalCountOfMatchingDocuments(),
      ThenTheDocumentShouldBeRemovedFromTheLibrary(),
      ThenTheDocumentsMusicXmlFileShouldBeDeleted(),
      ThenTheDocumentsDatabaseEntryShouldBeDeleted(),
      ThenIShouldSeeDisplayed(),
      ThenTheOMRProcessingShouldStart(),
      ThenIShouldSeeAProgressIndicator(),
      WhenTheOMRProcessingCompletesSuccessfully(),
      ThenTheDocumentShouldAppearInTheLibrary(),
      ThenTheDocumentShouldHaveMusicXMLContent(),
      ThenTheDocumentShouldHaveAThumbnail(),
      
      // Viewer Steps
      GivenTheApplicationIsRunning(),
      GivenIHaveADocumentInMyLibrary(),
      GivenIAmOnTheHomeScreen(),
      GivenIAmViewingAPageDocument(),
      GivenIAmViewingAMultiPageDocument(),
      GivenIAmViewingADocument(),
      GivenIAmOnPage(),
      GivenIAmViewingADocumentAtZoom(),
      WhenIClickOnTheDocument(),
      WhenIClickThePageButton(),
      WhenIClickTheZoomButton(),
      WhenIClickTheZoomButtonAgain(),
      WhenITryToClickTheButton(),
      WhenIClickTheBackButton(),
      WhenISwipeLeft(),
      WhenISwipeRight(),
      WhenIPinchToZoomIn(),
      WhenIPinchToZoomOut(),
      ThenTheDocumentViewerShouldOpen(),
      ThenIShouldSeeTheFirstPageOfTheMusic(),
      ThenIShouldSeeZoomControls(),
      ThenIShouldSeePageNavigationControls(),
      ThenIShouldSeePage(),
      ThenThePageIndicatorShouldShow(),
      ThenTheButtonShouldBeDisabled(),
      ThenTheZoomLevelShouldIncreaseTo(),
      ThenTheZoomLevelShouldDecreaseTo(),
      ThenTheZoomLevelShouldRemainAt(),
      ThenTheMusicShouldBeLargerAndClearer(),
      ThenIShouldReturnToTheHomeScreen(),
      ThenTheDocumentShouldBeClosed(),
      ThenTheMusicShouldBeScrolledHorizontally(),
      ThenTheMusicShouldBeScrolledVertically(),
      
      // OMR Steps
      GivenTheAudiverisOMREngineIsInstalled(),
      GivenTheApplicationHasAccessToTheAudiverisExecutable(),
      GivenIAmOnTheDesktopApplication(),
      GivenIHaveAHighQualityScan(),
      GivenTheImageHasGoodContrast(),
      GivenTheImageHasMinimalNoise(),
      GivenIHaveAPagePDFFile(),
      GivenIHaveALowQualityScanWithPoorContrast(),
      GivenOMRProcessingIsInProgress(),
      GivenTheProgressShows(),
      GivenIHaveAnImage(),
      GivenTheImageFileIsCorrupted(),
      GivenIStartOMRProcessingFor(),
      GivenIHaveImagesToProcess(),
      WhenIImportTheImageForOMRProcessing(),
      WhenIImportThePDFForOMRProcessing(),
      WhenTheProcessingCompletes(),
      WhenTheProcessingIsRunning(),
      WhenIClickTheCancelButton(),
      WhenIImportAllImages(),
      ThenTheOMRProcessShouldStart(),
      ThenIShouldSeeAProgressIndicatorShowing(),
      ThenIShouldReceiveAMusicXMLFile(),
      ThenTheRecognitionAccuracyShouldBeAbove(),
      ThenTheDocumentShouldBeAddedToMyLibrary(),
      ThenTheOMRShouldProcessAllPages(),
      ThenIShouldSeeProgressForEachPage(),
      ThenTheOutputShouldBeASingleMusicXMLDocumentWithPages(),
      ThenTheOMRShouldAttemptToEnhanceTheImage(),
      ButTheRecognitionMayHaveErrors(),
      ThenIShouldBeAbleToManuallyCorrectTheErrors(),
      ThenTheOMRProcessingShouldStop(),
      ThenTemporaryFilesShouldBeCleanedUp(),
      ThenTheDocumentShouldNotBeAddedToTheLibrary(),
      ThenTheOMRShouldFailGracefully(),
      ThenIShouldSeeAnErrorMessage(),
      ThenTheApplicationShouldRemainStable(),
      ThenIShouldSee(),
      ThenTheProgressShouldUpdateInRealTime(),
      ThenTheyShouldBeAddedToAProcessingQueue(),
      ThenTheyShouldBeProcessedOneAtATime(),
      ThenIShouldSeeTheQueueStatus(),
    ]
    ..customStepParameterDefinitions = []
    ..hooks = [TestHook()]
    ..restartAppBetweenScenarios = true
    ..targetAppPath = "test_driver/app.dart"
    ..exitAfterTestRun = true;

  return GherkinRunner().execute(config);
}

class TestHook extends Hook {
  final TestContext _context = TestContext();

  @override
  Future<void> onBeforeRun(TestConfiguration config) async {
    print('==============================================');
    print('Running Gherkin BDD tests for Sheet Music Reader');
    print('==============================================');
  }

  @override
  Future<void> onAfterRun(TestConfiguration config) async {
    print('==============================================');
    print('Gherkin BDD tests completed');
    print('==============================================');
  }

  @override
  Future<void> onBeforeScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    _context.reset();
    print('\n--- Starting scenario: $scenario ---');
  }

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    print('--- Completed scenario: $scenario ---\n');
  }

  @override
  int get priority => 0;
}
