import 'dart:ui';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:notebook/models/notebook.dart';
import 'package:notebook/models/note.dart';

class DatabaseHelper {
  static const _databaseName = "notebook_app.db";

  // 1. Bump the version number whenever you alter the schema
  static const _databaseVersion = 2;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // 2. Add the migration callback
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<int> insertNotebook(Notebook notebook) async {
    final db = await instance.database;
    return await db.insert(
      'notebooks', // Replace with your actual notebooks table name if different
      notebook.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Notebooks table
    await db.execute('''
  CREATE TABLE notebooks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    color INTEGER NOT NULL,
    note_count INTEGER DEFAULT 0
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

    // Seed default notebooks: Journal as default
    await db.insert('notebooks', {
      'id': 'nb_journal',
      'title': "Journal",
      'color': 0xFF2C5E58, // Dark teal green cover
    });
  }

  // Migration handler (runs when oldVersion < newVersion on existing installs)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from Version 1 -> Version 2
    if (oldVersion < 2) {
      // Example: Adding an 'is_pinned' column to the 'notes' table
      await db.execute(
        'ALTER TABLE notes ADD COLUMN is_pinned INTEGER DEFAULT 0;',
      );
    }

    // Future Migration Example: Version 2 -> Version 3
    /*
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE notebooks ADD COLUMN is_archived INTEGER DEFAULT 0;',
      );
    }
    */
  }

  // --- Notebook Operations ---

  Future<int> createNotebook(Notebook notebook) async {
    final db = await instance.database;
    return await db.insert('notebooks', {
      'id': notebook.id,
      'title': notebook.title,
      'color': notebook.color.toARGB32(),
    });
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
    ''');

    return result.map((json) {
      return Notebook(
        id: json['id'] as String,
        title: json['title'] as String,
        color: Color(json['color'] as int),
        noteCount: json['noteCount'] as int,
      );
    }).toList();
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
    return result.map((json) => Note.fromMap(json)).toList();
  }

// Search across ALL notes in the entire database by title and content
  Future<List<Note>> searchAllNotes(String query) async {
    final db = await instance.database;
    final formattedQuery = '%${query.toLowerCase()}%';

    final result = await db.query(
      'notes',
      where: 'LOWER(title) LIKE ? OR LOWER(content) LIKE ?',
      whereArgs: [formattedQuery, formattedQuery],
      orderBy: 'dateCreated DESC',
    );

    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> deleteNotebook(String id) async {
    final db = await instance.database;
    return await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Note Operations ---

  Future<int> createNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'notebookId': note.notebookId,
      'dateCreated': note.dateCreated.toIso8601String(),
    });
  }

  Future<List<Note>> getNotesByNotebook(String notebookId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
      orderBy: 'dateCreated DESC',
    );

    return result.map((json) {
      return Note(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        notebookId: json['notebookId'] as String,
        dateCreated: DateTime.parse(json['dateCreated'] as String),
      );
    }).toList();
  }

  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'dateCreated DESC');

    return result.map((json) {
      return Note(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        notebookId: json['notebookId'] as String,
        dateCreated: DateTime.parse(json['dateCreated'] as String),
      );
    }).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {
        'title': note.title,
        'content': note.content,
        'notebookId': note.notebookId,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
