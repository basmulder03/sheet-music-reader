Feature: Annotations
  As a musician
  I want to annotate my sheet music
  So that I can mark fingerings, dynamics, and personal notes

  Background:
    Given I have a document "Bach Prelude" in my library
    And I am viewing the document

  # Text Annotations

  Scenario: Add a text annotation
    Given I am on page 2 of the document
    When I tap on measure 5
    And I select "Add Text Note" from the context menu
    And I enter the text "Play softly here"
    And I confirm the annotation
    Then a text annotation should appear at measure 5
    And the annotation should show "Play softly here"
    And the annotation should be persisted to the database

  Scenario: Edit existing text annotation
    Given there is a text annotation "Check timing" on page 1
    When I tap on the annotation
    And I select "Edit"
    And I change the text to "Better timing needed"
    And I save the changes
    Then the annotation should show "Better timing needed"
    And the changes should sync across devices

  Scenario: Delete text annotation
    Given there is a text annotation on page 1
    When I tap on the annotation
    And I select "Delete"
    And I confirm the deletion
    Then the annotation should be removed
    And it should be deleted from the database
    And the deletion should sync to other devices

  # Highlight Annotations

  Scenario: Highlight a section
    Given I am viewing a document
    When I enter annotation mode
    And I select the "Highlight" tool
    And I select the color "Yellow"
    And I drag to select measures 3-5
    Then measures 3-5 should be highlighted in yellow
    And the highlight should be saved

  Scenario: Change highlight color
    Given there is a yellow highlight on measures 3-5
    When I tap on the highlight
    And I select "Change Color"
    And I choose "Red"
    Then the highlight should change to red
    And the change should be saved

  Scenario: Remove highlight
    Given there is a highlight on measures 3-5
    When I tap on the highlight
    And I select "Remove Highlight"
    Then the highlight should be removed
    And the removal should be saved

  # Shape Annotations

  Scenario: Draw a circle around a section
    Given I am viewing a document
    When I enter annotation mode
    And I select the "Circle" tool
    And I select the color "Blue"
    And I draw a circle around measure 7
    Then a blue circle should appear around measure 7
    And it should be saved as an annotation

  Scenario: Draw a rectangle
    Given I am in annotation mode
    When I select the "Rectangle" tool
    And I select the color "Green"
    And I draw a rectangle around measures 4-6
    Then a green rectangle should appear around measures 4-6

  Scenario: Draw an arrow
    Given I am in annotation mode
    When I select the "Arrow" tool
    And I select the color "Red"
    And I draw an arrow pointing to measure 3
    Then a red arrow should point to measure 3
    And it should indicate direction clearly

  Scenario: Adjust shape annotation size
    Given there is a circle annotation on the page
    When I tap on the circle
    And I drag the resize handle
    Then the circle should resize smoothly
    And the new size should be saved

  Scenario: Move shape annotation
    Given there is a rectangle annotation on the page
    When I tap and hold the rectangle
    And I drag it to a new position
    Then the rectangle should move to the new position
    And the new position should be saved

  # Annotation Colors

  Scenario: Available color options
    Given I am adding an annotation
    When I select the color picker
    Then I should see the following colors available:
      | color   |
      | Black   |
      | Red     |
      | Blue    |
      | Green   |
      | Yellow  |
      | Orange  |
      | Purple  |

  Scenario: Default annotation color
    Given I am adding a new annotation
    When I don't explicitly select a color
    Then the annotation should use the default color "Black"

  # Page-Specific Annotations

  Scenario: Annotations are page-specific
    Given I add an annotation "Repeat here" on page 2
    When I navigate to page 1
    Then I should not see the annotation "Repeat here"
    When I navigate back to page 2
    Then I should see the annotation "Repeat here"

  Scenario: View all annotations in document
    Given the document has annotations on multiple pages:
      | page | text           |
      | 1    | Start slow     |
      | 2    | Crescendo      |
      | 3    | Pause here     |
    When I open the "View All Annotations" panel
    Then I should see all 3 annotations listed
    And each should show its page number
    When I tap on an annotation in the list
    Then I should navigate to that page

  # Annotation Sync

  Scenario: Sync annotations to mobile
    Given I am on the desktop application
    And I add an annotation "Practice this section"
    When I open the same document on mobile
    Then I should see the annotation "Practice this section"
    And it should appear in the same location

  Scenario: Sync annotations from mobile to desktop
    Given I am on the mobile application
    And I add a highlight on measures 5-7
    When I view the same document on desktop
    Then I should see the highlight on measures 5-7

  Scenario: Real-time annotation sync
    Given the document is open on both desktop and mobile
    When I add an annotation on desktop
    Then the annotation should appear on mobile within 1 second
    And vice versa

  # Annotation Performance

  Scenario: Display many annotations without lag
    Given a document has 50 annotations across 10 pages
    When I navigate through the pages
    Then all annotations should render correctly
    And page navigation should remain smooth
    And frame rate should stay at 60 FPS

  Scenario: Quick annotation creation
    Given I am in annotation mode
    When I tap to add an annotation
    Then the annotation dialog should appear instantly
    And text input should be responsive

  # Annotation Persistence

  Scenario: Annotations survive app restart
    Given I add 5 annotations to a document
    When I close the application
    And I reopen the application
    And I open the same document
    Then all 5 annotations should still be present

  Scenario: Annotations survive document re-import
    Given a document has annotations
    When I delete and re-import the same document
    Then the old annotations should be preserved
    Or I should be prompted to keep or discard them

  # Error Handling

  Scenario: Handle annotation save failure
    Given I add an annotation
    When the database save fails
    Then I should see an error message "Failed to save annotation"
    And I should have the option to retry

  Scenario: Handle conflicting offline annotations
    Given I add an annotation offline on mobile
    And another annotation is added at the same location on desktop
    When I reconnect and sync
    Then both annotations should be preserved
    Or I should be prompted to resolve the conflict
