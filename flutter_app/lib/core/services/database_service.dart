import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart' show Color, Offset, Size;
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/sheet_music_document.dart';

/// Service for managing SQLite database persistence
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'sheet_music_reader.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _documentsTable = 'documents';
  static const String _annotationsTable = 'annotations';
  static const String _tagsTable = 'tags';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, 'sheet_music_reader', _databaseName);
    
    // Ensure directory exists
    final dbDir = Directory(path.dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE $_documentsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        composer TEXT,
        arranger TEXT,
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        source_path TEXT,
        musicxml_path TEXT NOT NULL,
        page_count INTEGER NOT NULL DEFAULT 1,
        time_signature TEXT,
        key_signature TEXT,
        tempo INTEGER,
        instruments TEXT,
        measure_count INTEGER
      )
    ''');

    // Tags table (many-to-many relationship)
    await db.execute('''
      CREATE TABLE $_tagsTable (
        document_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        PRIMARY KEY (document_id, tag),
        FOREIGN KEY (document_id) REFERENCES $_documentsTable (id) ON DELETE CASCADE
      )
    ''');

    // Annotations table
    await db.execute('''
      CREATE TABLE $_annotationsTable (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        type TEXT NOT NULL,
        page INTEGER NOT NULL,
        color INTEGER,
        position_x REAL NOT NULL,
        position_y REAL NOT NULL,
        size_width REAL,
        size_height REAL,
        text TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (document_id) REFERENCES $_documentsTable (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_documents_modified ON $_documentsTable (modified_at DESC)');
    await db.execute('CREATE INDEX idx_documents_title ON $_documentsTable (title COLLATE NOCASE)');
    await db.execute('CREATE INDEX idx_documents_composer ON $_documentsTable (composer COLLATE NOCASE)');
    await db.execute('CREATE INDEX idx_documents_created ON $_documentsTable (created_at DESC)');
    await db.execute('CREATE INDEX idx_annotations_document ON $_annotationsTable (document_id)');
    await db.execute('CREATE INDEX idx_annotations_page ON $_annotationsTable (document_id, page)');
    await db.execute('CREATE INDEX idx_tags_document ON $_tagsTable (document_id)');
    await db.execute('CREATE INDEX idx_tags_tag ON $_tagsTable (tag)');
    
    // Composite index for search queries
    await db.execute('CREATE INDEX idx_documents_search ON $_documentsTable (title COLLATE NOCASE, composer COLLATE NOCASE, modified_at DESC)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations here when needed
  }

  /// Save a document to the database
  Future<void> saveDocument(SheetMusicDocument document) async {
    final db = await database;
    
    // Insert or replace document
    await db.insert(
      _documentsTable,
      {
        'id': document.id,
        'title': document.title,
        'composer': document.composer,
        'arranger': document.arranger,
        'created_at': document.createdAt.millisecondsSinceEpoch,
        'modified_at': document.modifiedAt.millisecondsSinceEpoch,
        'source_path': document.sourcePath,
        'musicxml_path': document.musicXmlPath,
        'page_count': document.metadata.pageCount,
        'time_signature': document.metadata.timeSignature,
        'key_signature': document.metadata.keySignature,
        'tempo': document.metadata.tempo,
        'instruments': document.metadata.instruments.join(','),
        'measure_count': document.metadata.measureCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Delete existing tags
    await db.delete(_tagsTable, where: 'document_id = ?', whereArgs: [document.id]);

    // Insert tags
    if (document.tags.isNotEmpty) {
      final batch = db.batch();
      for (final tag in document.tags) {
        batch.insert(_tagsTable, {
          'document_id': document.id,
          'tag': tag,
        });
      }
      await batch.commit(noResult: true);
    }
  }

  /// Get a document by ID
  Future<SheetMusicDocument?> getDocument(String id) async {
    final db = await database;
    
    final results = await db.query(
      _documentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final docMap = results.first;
    final tags = await _getDocumentTags(id);

    return _documentFromMap(docMap, tags);
  }

  /// Get all documents
  Future<List<SheetMusicDocument>> getAllDocuments() async {
    final db = await database;
    
    final results = await db.query(
      _documentsTable,
      orderBy: 'modified_at DESC',
    );

    final documents = <SheetMusicDocument>[];
    for (final docMap in results) {
      final tags = await _getDocumentTags(docMap['id'] as String);
      documents.add(_documentFromMap(docMap, tags));
    }

    return documents;
  }

  /// Get paginated documents
  Future<List<SheetMusicDocument>> getDocumentsPage({
    required int page,
    required int pageSize,
  }) async {
    final db = await database;
    final offset = page * pageSize;
    
    final results = await db.query(
      _documentsTable,
      orderBy: 'modified_at DESC',
      limit: pageSize,
      offset: offset,
    );

    final documents = <SheetMusicDocument>[];
    for (final docMap in results) {
      final tags = await _getDocumentTags(docMap['id'] as String);
      documents.add(_documentFromMap(docMap, tags));
    }

    return documents;
  }

  /// Get total document count
  Future<int> getDocumentCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_documentsTable'),
    ) ?? 0;
  }

  /// Search documents by title, composer, or tags (optimized)
  Future<List<SheetMusicDocument>> searchDocuments(String query) async {
    final db = await database;
    
    if (query.isEmpty) {
      return getAllDocuments();
    }
    
    final lowerQuery = '%${query.toLowerCase()}%';
    
    // Optimized query using indexed columns
    final results = await db.rawQuery('''
      SELECT DISTINCT d.*
      FROM $_documentsTable d
      LEFT JOIN $_tagsTable t ON d.id = t.document_id
      WHERE LOWER(d.title) LIKE ?
         OR LOWER(d.composer) LIKE ?
         OR LOWER(d.arranger) LIKE ?
         OR LOWER(t.tag) LIKE ?
      ORDER BY d.modified_at DESC
    ''', [lowerQuery, lowerQuery, lowerQuery, lowerQuery]);

    final documents = <SheetMusicDocument>[];
    final seenIds = <String>{};
    
    for (final docMap in results) {
      final id = docMap['id'] as String;
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        final tags = await _getDocumentTags(id);
        documents.add(_documentFromMap(docMap, tags));
      }
    }

    return documents;
  }

  /// Search documents with pagination (optimized)
  Future<List<SheetMusicDocument>> searchDocumentsPage({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    final db = await database;
    
    if (query.isEmpty) {
      return getDocumentsPage(page: page, pageSize: pageSize);
    }
    
    final lowerQuery = '%${query.toLowerCase()}%';
    final offset = page * pageSize;
    
    // Optimized query with indexed columns and pagination
    final results = await db.rawQuery('''
      SELECT DISTINCT d.*
      FROM $_documentsTable d
      LEFT JOIN $_tagsTable t ON d.id = t.document_id
      WHERE LOWER(d.title) LIKE ?
         OR LOWER(d.composer) LIKE ?
         OR LOWER(d.arranger) LIKE ?
         OR LOWER(t.tag) LIKE ?
      ORDER BY d.modified_at DESC
      LIMIT ? OFFSET ?
    ''', [lowerQuery, lowerQuery, lowerQuery, lowerQuery, pageSize, offset]);

    final documents = <SheetMusicDocument>[];
    final seenIds = <String>{};
    
    for (final docMap in results) {
      final id = docMap['id'] as String;
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        final tags = await _getDocumentTags(id);
        documents.add(_documentFromMap(docMap, tags));
      }
    }

    return documents;
  }

  /// Get search result count (optimized)
  Future<int> getSearchCount(String query) async {
    final db = await database;
    
    if (query.isEmpty) {
      return getDocumentCount();
    }
    
    final lowerQuery = '%${query.toLowerCase()}%';
    
    return Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(DISTINCT d.id) FROM $_documentsTable d '
        'LEFT JOIN $_tagsTable t ON d.id = t.document_id '
        'WHERE LOWER(d.title) LIKE ? OR LOWER(d.composer) LIKE ? OR LOWER(d.arranger) LIKE ? OR LOWER(t.tag) LIKE ?',
        [lowerQuery, lowerQuery, lowerQuery, lowerQuery],
      ),
    ) ?? 0;
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(_documentsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Update document metadata
  Future<void> updateDocument(SheetMusicDocument document) async {
    await saveDocument(document);
  }

  /// Get tags for a document
  Future<List<String>> _getDocumentTags(String documentId) async {
    final db = await database;
    final results = await db.query(
      _tagsTable,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
    return results.map((row) => row['tag'] as String).toList();
  }

  /// Convert database row to SheetMusicDocument
  SheetMusicDocument _documentFromMap(Map<String, dynamic> map, List<String> tags) {
    final instruments = (map['instruments'] as String?)?.split(',') ?? [];
    
    return SheetMusicDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      composer: map['composer'] as String?,
      arranger: map['arranger'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modified_at'] as int),
      sourcePath: map['source_path'] as String?,
      musicXmlPath: map['musicxml_path'] as String,
      tags: tags,
      metadata: DocumentMetadata(
        pageCount: map['page_count'] as int,
        timeSignature: map['time_signature'] as String?,
        keySignature: map['key_signature'] as String?,
        tempo: map['tempo'] as int?,
        instruments: instruments.where((i) => i.isNotEmpty).toList(),
        measureCount: map['measure_count'] as int?,
      ),
    );
  }

  /// Save annotation to database
  Future<void> saveAnnotation(String documentId, Annotation annotation) async {
    final db = await database;
    
    await db.insert(
      _annotationsTable,
      {
        'id': annotation.id,
        'document_id': documentId,
        'type': annotation.type.toString().split('.').last,
        'page': annotation.page,
        // ignore: deprecated_member_use
        'color': annotation.color?.value,
        'position_x': annotation.position.dx,
        'position_y': annotation.position.dy,
        'size_width': annotation.size?.width,
        'size_height': annotation.size?.height,
        'text': annotation.text,
        'created_at': annotation.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get annotations for a document
  Future<List<Annotation>> getAnnotations(String documentId) async {
    final db = await database;
    
    final results = await db.query(
      _annotationsTable,
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'created_at ASC',
    );

    return results.map((map) => _annotationFromMap(map)).toList();
  }

  /// Delete an annotation
  Future<void> deleteAnnotation(String annotationId) async {
    final db = await database;
    await db.delete(_annotationsTable, where: 'id = ?', whereArgs: [annotationId]);
  }

  /// Convert database row to Annotation
  Annotation _annotationFromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String;
    final type = AnnotationType.values.firstWhere(
      (t) => t.toString().split('.').last == typeStr,
      orElse: () => AnnotationType.note,
    );

    final sizeWidth = map['size_width'] as double?;
    final sizeHeight = map['size_height'] as double?;
    final size = (sizeWidth != null && sizeHeight != null) 
        ? Size(sizeWidth, sizeHeight) 
        : null;

    return Annotation(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      type: type,
      page: map['page'] as int,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      position: Offset(
        map['position_x'] as double,
        map['position_y'] as double,
      ),
      size: size,
      text: map['text'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Get database statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final docCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_documentsTable'),
    ) ?? 0;
    
    final annotationCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_annotationsTable'),
    ) ?? 0;

    return {
      'documents': docCount,
      'annotations': annotationCount,
    };
  }

  /// Optimize database (run VACUUM and ANALYZE)
  Future<void> optimizeDatabase() async {
    try {
      final db = await database;
      
      // ANALYZE updates statistics for query optimizer
      await db.execute('ANALYZE');
      
      // VACUUM reclaims unused space and defragments
      await db.execute('VACUUM');
      
      if (kDebugMode) {
        print('[Database] Optimization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Database] Error optimizing: $e');
      }
    }
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDirectory.path, 'sheet_music_reader', _databaseName);
      final file = File(dbPath);
      
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Database] Error getting size: $e');
      }
    }
    return 0;
  }

  /// Check database integrity
  Future<bool> checkIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      final status = result.first['integrity_check'] as String?;
      return status == 'ok';
    } catch (e) {
      if (kDebugMode) {
        print('[Database] Integrity check failed: $e');
      }
      return false;
    }
  }
}
