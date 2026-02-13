Feature: Performance and Optimization
  As a user
  I want the application to be fast and responsive
  So that I can work efficiently with my music library

  # Pagination

  Scenario: Load large library with pagination
    Given I have a library with 1000 documents
    When I open the home screen
    Then only the first 20 documents should be loaded
    And the UI should be responsive
    And memory usage should be reasonable

  Scenario: Lazy load documents on scroll
    Given I am viewing a library with 500 documents
    And I have loaded the first 20 documents
    When I scroll to the bottom of the list
    Then the next 20 documents should load automatically
    And the scrolling should remain smooth
    And there should be no visible lag

  Scenario: Show loading indicator during pagination
    Given I am scrolling through a large library
    When the next page of documents is loading
    Then I should see a loading spinner at the bottom of the list
    And the current documents should remain visible

  Scenario: Display total document count
    Given I have 250 documents in my library
    And I have loaded 40 documents
    When I view the library
    Then I should see "40 of 250 loaded"
    And the count should update as I scroll

  # Memory Management

  Scenario: Memory limit for loaded documents
    Given the memory manager is configured with 100MB limit
    When I load multiple large documents
    Then the total memory usage should not exceed 100MB
    And old documents should be evicted automatically

  Scenario: LRU eviction strategy
    Given I have loaded documents A, B, C, and D in that order
    And document A is the least recently used
    When memory limit is reached
    And I load document E
    Then document A should be evicted from memory
    But documents B, C, and D should remain loaded

  Scenario: Access recently used document
    Given document "Sonata" was loaded 30 seconds ago
    When I open "Sonata" again
    Then it should load instantly from memory
    And there should be no delay

  Scenario: Cleanup inactive documents
    Given I have loaded several documents
    And I haven't accessed "Old Practice" for 10 minutes
    When the cleanup process runs
    Then "Old Practice" should be unloaded from memory
    And memory should be freed

  Scenario: Memory usage statistics
    Given I have loaded multiple documents
    When I view memory statistics
    Then I should see:
      | Current memory usage |
      | Memory limit        |
      | Number of loaded documents |
      | Memory usage percentage |

  # Image Caching

  Scenario: Cache thumbnails in memory
    Given I view the document list
    When thumbnails are loaded
    Then they should be cached in memory (50MB limit)
    And subsequent views should load instantly from cache

  Scenario: Cache thumbnails on disk
    Given thumbnails are downloaded
    Then they should be cached on disk (200MB limit)
    And they should persist across app restarts

  Scenario: Evict old disk cache entries
    Given the disk cache is at 200MB limit
    When new thumbnails are cached
    Then the oldest cache entries should be deleted
    And the cache should stay under 200MB

  Scenario: Cache expiry
    Given a thumbnail was cached 35 days ago
    When the app checks the cache
    Then the thumbnail should be considered expired (30-day limit)
    And it should be removed from cache

  # Network Optimization

  Scenario: Debounce rapid sync requests
    Given I make 5 sync requests within 100ms
    When the debouncing is applied (300ms delay)
    Then only 1 actual network request should be made
    And it should happen 300ms after the last request

  Scenario: Batch multiple network requests
    Given I have 10 annotation updates to sync
    When the batch window is 500ms
    Then all 10 updates should be sent in a single batch
    And the batch should be sent 500ms after the first update

  Scenario: Efficient WebSocket message batching
    Given I am connected via WebSocket
    When 20 messages are generated within 100ms
    Then they should be batched together
    And sent as a single WebSocket message
    And the batch should contain all 20 messages

  # Database Optimization

  Scenario: Fast document queries with indexes
    Given the database has 5000 documents
    And indexes exist on title, composer, and modified date
    When I search for documents by composer
    Then the query should complete in under 100ms
    And the results should be accurate

  Scenario: Paginated database queries
    Given the database has 10000 documents
    When I request page 5 with 20 documents per page
    Then the database should use LIMIT and OFFSET
    And only 20 documents should be loaded
    And the query should be fast (< 50ms)

  Scenario: Full-text search optimization
    Given the database has indexed search columns
    When I search for "Beethoven Symphony"
    Then the search should use the search index
    And results should return in under 200ms
    And the search should be case-insensitive

  # Rendering Performance

  Scenario: Smooth scrolling at 60 FPS
    Given I am viewing a document
    When I scroll through the pages
    Then the frame rate should be maintained at 60 FPS
    And there should be no dropped frames
    And the scrolling should feel smooth

  Scenario: No dropped frames during navigation
    Given I am navigating between pages
    When I monitor frame timing
    Then dropped frames should be less than 1%
    And average frame time should be under 16ms

  Scenario: Profile rendering performance
    Given the rendering profiler is enabled
    When I perform various operations
    Then I should be able to view:
      | Average FPS |
      | Min FPS     |
      | Max FPS     |
      | Dropped frame count |
      | Operation timings   |

  Scenario: Detect performance issues
    Given the rendering profiler is active
    When the FPS drops below 30
    Then the profiler should flag it as "poor performance"
    And it should provide recommendations

  # MusicXML Parsing Performance

  Scenario: Fast parsing with cache
    Given I have parsed "Symphony No. 5" before
    When I open "Symphony No. 5" again
    Then the MusicXML should load from cache
    And parsing time should be under 100ms

  Scenario: Isolate-based parsing for large files
    Given I have a MusicXML file larger than 100KB
    When parsing is initiated
    Then parsing should run in a separate isolate
    And the UI should remain responsive
    And the main thread should not block

  Scenario: MusicXML cache size limit
    Given the MusicXML cache is configured with 50MB limit
    When the cache size exceeds 50MB
    Then least recently used entries should be evicted
    And the cache should stay under 50MB

  # Startup Performance

  Scenario: Fast application startup
    Given the application is closed
    When I launch the application
    Then it should be ready to use in under 3 seconds
    And the home screen should appear quickly

  Scenario: Fast database initialization
    Given the database is not yet opened
    When the app starts
    Then the database should open in under 500ms
    And migrations should run automatically if needed

  Scenario: Lazy loading of services
    Given the application is starting
    When services are initialized
    Then only essential services should load immediately
    And other services should load on demand

  # Large Library Performance

  Scenario: Handle 10000 document library
    Given I have 10000 documents in my library
    When I view the home screen
    Then the app should remain responsive
    And the first page should load in under 2 seconds
    And memory usage should be manageable

  Scenario: Fast search in large library
    Given I have 5000 documents in my library
    When I search for "Mozart"
    Then results should appear in under 1 second
    And the search should be accurate

  Scenario: Efficient document deletion in large library
    Given I have 1000 documents
    When I delete a document
    Then the deletion should complete in under 500ms
    And the UI should update smoothly

  # Network Performance

  Scenario: Fast initial sync
    Given I connect to a server with 200 documents
    When the initial sync begins
    Then metadata for the first 20 documents should load in under 2 seconds
    And thumbnails should load progressively

  Scenario: Bandwidth-efficient sync
    Given I am syncing 100 documents
    When only metadata and thumbnails are needed
    Then full MusicXML should not be downloaded
    And total bandwidth should be under 5MB

  Scenario: Fast WebSocket real-time updates
    Given I am connected via WebSocket
    When a real-time update is sent from the server
    Then the mobile app should receive it in under 500ms
    And the UI should update immediately

  # Error Recovery Performance

  Scenario: Graceful degradation
    Given the network is slow (2G speed)
    When I try to load documents
    Then the app should remain usable
    And it should show loading indicators
    And cached content should be accessible

  Scenario: Fast recovery from errors
    Given a network request fails
    When I retry the operation
    Then the retry should happen quickly
    And there should be no lingering issues
