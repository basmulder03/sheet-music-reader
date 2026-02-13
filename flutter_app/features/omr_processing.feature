Feature: Optical Music Recognition (OMR)
  As a musician
  I want to convert scanned sheet music images to digital format
  So that I can view and edit my music digitally

  Background:
    Given the Audiveris OMR engine is installed
    And the application has access to the Audiveris executable
    And I am on the desktop application

  Scenario: Process a clean, high-quality scan
    Given I have a high-quality scan "mozart_sonata.png"
    And the image has good contrast
    And the image has minimal noise
    When I import the image for OMR processing
    Then the OMR process should start
    And I should see a progress indicator showing "Processing..."
    When the processing completes
    Then I should receive a MusicXML file
    And the recognition accuracy should be above 90%
    And the document should be added to my library

  Scenario: Process a multi-page PDF document
    Given I have a 4-page PDF file "beethoven_quartet.pdf"
    When I import the PDF for OMR processing
    Then the OMR should process all 4 pages
    And I should see progress for each page
    And the output should be a single MusicXML document with 4 pages

  Scenario: Handle low-quality scan
    Given I have a low-quality scan with poor contrast
    When I import the image for OMR processing
    Then the OMR should attempt to enhance the image
    And I should receive a MusicXML file
    But the recognition may have errors
    And I should be able to manually correct the errors

  Scenario: Cancel OMR processing
    Given OMR processing is in progress
    And the progress shows 45%
    When I click the "Cancel" button
    Then the OMR processing should stop
    And temporary files should be cleaned up
    And the document should not be added to the library

  Scenario: Handle OMR processing failure
    Given I have an image "corrupted_file.png"
    And the image file is corrupted
    When I import the image for OMR processing
    Then the OMR should fail gracefully
    And I should see an error message "Failed to process image"
    And the application should remain stable

  Scenario: View OMR processing progress
    Given I start OMR processing for "symphony.png"
    When the processing is running
    Then I should see:
      | Progress percentage |
      | Current step        |
      | Estimated time remaining |
    And the progress should update in real-time

  Scenario: Process multiple documents in queue
    Given I have 3 images to process:
      | filename           |
      | prelude.png        |
      | fugue.png          |
      | suite.png          |
    When I import all 3 images
    Then they should be added to a processing queue
    And they should be processed one at a time
    And I should see "Processing 1 of 3", then "Processing 2 of 3", etc.

  Scenario: Successful OMR generates thumbnail
    Given I import "chopin_waltz.png" for OMR processing
    When the processing completes successfully
    Then a thumbnail should be generated automatically
    And the thumbnail should show a preview of the first page

  Scenario: OMR output validation
    Given I successfully process "test_score.png"
    When the processing completes
    Then the MusicXML output should be valid
    And the MusicXML should contain:
      | Element      |
      | score-partwise |
      | part         |
      | measure      |
      | note         |
    And the file should be parseable by the MusicXML service

  Scenario: OMR performance for large files
    Given I have a large 50-page orchestral score
    When I import it for OMR processing
    Then the processing should not exceed 10 minutes
    And memory usage should not exceed 2GB
    And the application should remain responsive
