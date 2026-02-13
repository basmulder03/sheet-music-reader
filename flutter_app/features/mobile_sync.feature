Feature: Mobile-Desktop Synchronization
  As a musician with both desktop and mobile devices
  I want to sync my sheet music library between devices
  So that I can access my music anywhere

  Background:
    Given the desktop application is running
    And the desktop has a library with 10 documents
    And the mobile application is installed

  # Server Discovery

  Scenario: Discover desktop server automatically
    Given the mobile app is launched
    And the desktop and mobile are on the same WiFi network
    When I navigate to the "Connect to Server" screen
    Then the mobile app should discover the desktop server automatically
    And I should see the server name "My Desktop"
    And I should see the server IP address

  Scenario: Multiple servers on network
    Given there are 2 desktop servers on the network:
      | name           | ip          |
      | Studio Desktop | 192.168.1.5 |
      | Home Desktop   | 192.168.1.8 |
    When I open the server discovery screen
    Then I should see both servers listed
    And each server should show its name and IP

  Scenario: No servers found
    Given no desktop servers are running
    When I open the server discovery screen
    Then I should see "No servers found"
    And I should see a "Refresh" button

  Scenario: Manually refresh server list
    Given I am on the server discovery screen
    When I pull down to refresh
    Then the app should search for servers again
    And the list should update with any newly discovered servers

  # Connection

  Scenario: Connect to desktop server
    Given I have discovered a server "Studio Desktop"
    When I tap on "Studio Desktop"
    Then the mobile app should connect to the server
    And I should see "Connected" status
    And I should be navigated to the document list

  Scenario: Connection failure
    Given I try to connect to a server at "192.168.1.100"
    But the server is unreachable
    When the connection times out
    Then I should see an error message "Failed to connect"
    And I should remain on the server discovery screen

  Scenario: Maintain connection in background
    Given I am connected to a server
    When I switch to another app
    And return after 2 minutes
    Then the connection should still be active
    And I should not need to reconnect

  Scenario: Reconnect after connection lost
    Given I am connected to a server
    When the WiFi connection is lost
    Then I should see "Connection lost" notification
    When the WiFi connection is restored
    Then the app should automatically attempt to reconnect

  # Document Synchronization

  Scenario: Initial document sync
    Given I connect to a desktop server with 50 documents
    When the connection is established
    Then the mobile app should download the first page of documents (20 items)
    And I should see the document list
    And each document should show:
      | title     |
      | composer  |
      | thumbnail |

  Scenario: Paginated document loading
    Given I am viewing the document list with 100 total documents
    And I have loaded the first 20 documents
    When I scroll to the bottom of the list
    Then the next 20 documents should load automatically
    And I should see a loading indicator during the load

  Scenario: Download MusicXML for viewing
    Given I am connected to the server
    And I tap on a document "Moonlight Sonata"
    When the document viewer opens
    Then the MusicXML content should be downloaded from the server
    And the sheet music should render on the mobile device
    And the download should be cached for offline viewing

  Scenario: Real-time annotation sync
    Given I am viewing a document on mobile
    And the same document is open on desktop
    When I add an annotation on the mobile device
    Then the annotation should sync to the desktop in real-time
    And the desktop should show the new annotation within 1 second

  Scenario: Real-time document addition
    Given I am viewing the document list on mobile
    When a new document is imported on the desktop
    Then the mobile document list should update automatically
    And the new document should appear at the top of the list

  Scenario: Real-time document deletion
    Given I am viewing the document list on mobile
    And the list contains "Old Practice Sheet"
    When "Old Practice Sheet" is deleted on the desktop
    Then it should disappear from the mobile list automatically

  # Offline Mode

  Scenario: View cached documents offline
    Given I have previously viewed 5 documents while connected
    When I disconnect from the server
    And I navigate to the document list
    Then I should still see the 5 cached documents
    And each document should have an offline indicator

  Scenario: Open cached document offline
    Given I have a cached document "Für Elise"
    And I am offline
    When I open "Für Elise"
    Then the sheet music should display from cache
    And I should be able to view all cached pages
    But I should not be able to download new pages

  Scenario: Cannot sync changes when offline
    Given I am offline
    And I am viewing a cached document
    When I try to add an annotation
    Then I should see a message "Offline - changes will sync when connected"
    And the annotation should be saved locally
    When I reconnect to the server
    Then the annotation should sync to the desktop

  # Performance

  Scenario: Efficient bandwidth usage
    Given I connect to a server with 100 documents
    When syncing the document list
    Then only thumbnails and metadata should be downloaded
    And full MusicXML should only download when opening a document
    And the total data transfer should be less than 5MB

  Scenario: Fast document list loading
    Given I have 500 documents on the server
    When I view the document list
    Then the first page should load in less than 2 seconds
    And subsequent pages should load in less than 1 second

  Scenario: Smooth real-time updates
    Given I am connected to the server
    When real-time updates are received via WebSocket
    Then the UI should update smoothly without freezing
    And the frame rate should remain at 60 FPS

  # Error Handling

  Scenario: Handle server shutdown gracefully
    Given I am connected to a server
    And I am viewing the document list
    When the desktop application is closed
    Then I should see "Server disconnected" notification
    And the app should switch to offline mode
    And cached documents should remain accessible

  Scenario: Handle network timeout
    Given I am downloading a large document
    When the network becomes very slow
    And the request times out after 30 seconds
    Then I should see "Download timed out" message
    And I should have the option to retry

  Scenario: Handle conflicting annotations
    Given I add an annotation offline on mobile
    And the same document is modified on desktop
    When I reconnect and sync
    Then both annotations should be preserved
    And there should be no data loss
