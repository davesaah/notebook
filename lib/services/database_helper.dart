import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/models/note.dart';
import 'package:notebook/models/notebook.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "notebook.db";

  /// Singleton pattern: ensures only one instance of DatabaseHelper
  /// exists throughout the app, so all DB reads/writes share the
  /// same connection instead of opening multiple sqlite handles.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _createDB(Database db, int version) async {
    // Notebooks table
    await db.execute('''
  CREATE TABLE notebooks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    color INTEGER NOT NULL,
    noteCount INTEGER NOT NULL
    )
  ''');

    // Notes table
    await db.execute('''
    CREATE TABLE notes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      notebookId TEXT NOT NULL,
      dateCreated TEXT NOT NULL,
      FOREIGN KEY (notebookId) REFERENCES notebooks (id) ON DELETE CASCADE
    )
  ''');

    // Seed default notebook: Journal
    final journal = Notebook(
      id: 'nb_journal',
      title: "Journal",
      color: CustomColors.darkTealGreen,
    );
    await db.insert(
      'notebooks',
      journal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Notebook Operations ---
  Future<int> createNotebook(Notebook notebook) async {
    final db = await instance.database;
    return await db.insert(
      'notebooks',
      notebook.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Notebook>> getAllNotebooks() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        n.id, 
        n.title, 
        n.color, 
        COUNT(nt.id) AS noteCount
      FROM notebooks n
      LEFT JOIN notes nt ON n.id = nt.notebookId
      GROUP BY n.id
      ORDER BY noteCount DESC, LOWER(n.title) ASC
    ''');
    return result.map((item) => Notebook.fromMap(item)).toList();
  }

  // --- Note Operations ---
  Future<int> createNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // Fetch notes for the currently active notebook
  Future<List<Note>> getNotesForNotebook(String notebookId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
      orderBy: 'dateCreated DESC',
    );
    return result.map((item) => Note.fromMap(item)).toList();
  }

  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'dateCreated DESC');
    return result.map((item) => Note.fromMap(item)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Search across ALL notes in the entire database by title and content
  Future<List<Note>> searchAllNotes(String query) async {
    final db = await instance.database;
    final formattedQuery = '%$query%';

    final result = await db.query(
      'notes',
      where: 'LOWER(title) LIKE ? OR LOWER(content) LIKE ?',
      whereArgs: [formattedQuery, formattedQuery],
      orderBy: 'dateCreated DESC',
    );

    return result.map((item) => Note.fromMap(item)).toList();
  }

  // Search across notes in the notebook database by title and content
  Future<List<Note>> searchNotesInNotebook(
    String query,
    String notebookId,
  ) async {
    final db = await instance.database;
    final formattedQuery = '%$query%';

    final result = await db.query(
      'notes',
      where:
          'notebookId = ? AND (LOWER(title) LIKE ? OR LOWER(content) LIKE ?)',
      whereArgs: [notebookId, formattedQuery, formattedQuery],
      orderBy: 'dateCreated DESC',
    );

    return result.map((item) => Note.fromMap(item)).toList();
  }

  // --- Export / Import ---
  /// Full path to the underlying sqlite file.
  Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _databaseName);
  }

  /// Closes the current connection so the file can be safely
  /// read, copied, or overwritten elsewhere.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Raw bytes of the current database file — flushes SQLite WAL first.
  Future<Uint8List> exportDatabaseBytes() async {
    final db = await instance.database;

    // Checkpoint any pending Write-Ahead Log entries to the main .db file
    await db.rawQuery('PRAGMA wal_checkpoint(FULL);');

    final path = await getDatabaseFilePath();
    return File(path).readAsBytes();
  }

  /// Validates and swaps in a backup file, then reopens the database safely.
  Future<void> importDatabaseBytes(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(join(tempDir.path, 'notebook_import_check.db'));
    await tempFile.writeAsBytes(bytes, flush: true);

    Database? checkDb;
    try {
      checkDb = await openDatabase(tempFile.path, readOnly: true);
      final tables = await checkDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('notes','notebooks')",
      );
      if (tables.length < 2) {
        throw const FormatException(
          'Selected file is not a valid Notebook backup.',
        );
      }
    } finally {
      await checkDb?.close();
    }

    // Safely close the existing database instance
    await close();

    final path = await getDatabaseFilePath();

    // Clear old SQLite auxiliary files to prevent database corruption
    final walFile = File('$path-wal');
    final shmFile = File('$path-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    // Overwrite database file
    await tempFile.copy(path);
    await tempFile.delete();

    // Re-initialize database handle
    _database = await _initDatabase();
  }
}
