Feature: Sheet Music Viewing
  As a musician
  I want to view my digitized sheet music
  So that I can read and practice my music

  Background:
    Given the application is running
    And I have a document "Sonata No. 14" in my library

  Scenario: Open a document for viewing
    Given I am on the home screen
    When I click on the document "Sonata No. 14"
    Then the document viewer should open
    And I should see the first page of the music
    And I should see zoom controls
    And I should see page navigation controls

  Scenario: Navigate between pages
    Given I am viewing a 5-page document
    And I am on page 1
    When I click the "Next Page" button
    Then I should see page 2
    And the page indicator should show "Page 2 of 5"
    When I click the "Previous Page" button
    Then I should see page 1
    And the page indicator should show "Page 1 of 5"

  Scenario: Navigate to last page
    Given I am viewing a 10-page document
    And I am on page 1
    When I click the "Last Page" button
    Then I should see page 10
    And the page indicator should show "Page 10 of 10"
    And the "Next Page" button should be disabled

  Scenario: Navigate to first page
    Given I am viewing a multi-page document
    And I am on page 5
    When I click the "First Page" button
    Then I should see page 1
    And the "Previous Page" button should be disabled

  Scenario: Zoom in on sheet music
    Given I am viewing a document at 100% zoom
    When I click the "Zoom In" button
    Then the zoom level should increase to 125%
    And the music should be larger and clearer
    When I click the "Zoom In" button again
    Then the zoom level should increase to 150%

  Scenario: Zoom out on sheet music
    Given I am viewing a document at 150% zoom
    When I click the "Zoom Out" button
    Then the zoom level should decrease to 125%
    When I click the "Zoom Out" button again
    Then the zoom level should decrease to 100%

  Scenario: Maximum zoom level
    Given I am viewing a document at 300% zoom
    When I try to click the "Zoom In" button
    Then the "Zoom In" button should be disabled
    And the zoom level should remain at 300%

  Scenario: Minimum zoom level
    Given I am viewing a document at 50% zoom
    When I try to click the "Zoom Out" button
    Then the "Zoom Out" button should be disabled
    And the zoom level should remain at 50%

  Scenario: Close document viewer
    Given I am viewing a document
    When I click the back button
    Then I should return to the home screen
    And the document should be closed

  Scenario: View document on mobile device
    Given I am using the mobile app
    And I am connected to the desktop server
    When I open a document
    Then the sheet music should render correctly
    And I should be able to pan with touch gestures
    And I should be able to zoom with pinch gestures

  Scenario: Smooth scrolling performance
    Given I am viewing a document
    When I scroll through the pages
    Then the scrolling should be smooth at 60 FPS
    And there should be no visible lag or stuttering

  Scenario: Page caching for performance
    Given I am viewing page 5 of a document
    When I navigate to page 6
    Then page 6 should load quickly from cache
    And pages 4-7 should be pre-cached for smooth navigation
