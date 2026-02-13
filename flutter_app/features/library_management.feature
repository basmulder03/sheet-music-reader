Feature: Document Library Management
  As a musician
  I want to manage my sheet music library
  So that I can organize and access my music collection

  Background:
    Given the application is installed
    And the database is initialized
    And I am on the desktop home screen

  Scenario: View empty library
    Given the library has no documents
    When I view the document list
    Then I should see a message "No documents yet"
    And I should see an "Import" button

  Scenario: Import a new sheet music document
    Given I have a sheet music image file "beethoven_symphony.png"
    When I click the "Import" button
    And I select the file "beethoven_symphony.png"
    Then the OMR processing should start
    And I should see a progress indicator
    When the OMR processing completes successfully
    Then the document "beethoven_symphony" should appear in the library
    And the document should have MusicXML content
    And the document should have a thumbnail

  Scenario: View library with multiple documents
    Given the library has the following documents:
      | title                | composer          | createdAt  |
      | Moonlight Sonata     | Beethoven         | 2026-01-15 |
      | Für Elise            | Beethoven         | 2026-01-20 |
      | Turkish March        | Mozart            | 2026-02-01 |
    When I view the document list
    Then I should see 3 documents
    And the documents should be sorted by "modified date" descending
    And each document should show:
      | field     |
      | title     |
      | composer  |
      | thumbnail |
      | modified date |

  Scenario: Search documents by title
    Given the library has 50 documents
    And one document has title "Canon in D"
    When I enter "Canon" in the search box
    Then I should see only documents matching "Canon"
    And the search should be case-insensitive

  Scenario: Search documents by composer
    Given the library has documents by various composers
    When I enter "Beethoven" in the search box
    Then I should see all documents by "Beethoven"
    And I should see the total count of matching documents

  Scenario: Delete a document
    Given the library has a document "Old Practice Sheet"
    When I select the document "Old Practice Sheet"
    And I click the delete button
    And I confirm the deletion
    Then the document "Old Practice Sheet" should be removed from the library
    And the document's MusicXML file should be deleted
    And the document's database entry should be deleted

  Scenario: Sort documents by title
    Given the library has multiple documents
    When I select "Sort by Title" from the sort menu
    Then the documents should be sorted alphabetically by title

  Scenario: Sort documents by composer
    Given the library has multiple documents
    When I select "Sort by Composer" from the sort menu
    Then the documents should be sorted alphabetically by composer

  Scenario: View document count
    Given the library has 42 documents
    When I view the home screen
    Then I should see "42 documents" displayed
