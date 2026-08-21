import 'dart:ui';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:notebook/models/notebook.dart';
import 'package:notebook/models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notebook_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Notebooks table
    await db.execute('''
    CREATE TABLE notebooks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      color INTEGER NOT NULL
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
      'title': "JOURNAL",
      'color': 0xFF2C5E58, // Dark teal green cover
    });

//     final now = DateTime.now();
//
// // Yesterday's note
//     await db.insert('notes', {
//       'id': 'note_yesterday',
//       'title': 'Yesterday\'s Reflections',
//       'content': 'Taking time to review progress from yesterday.',
//       'notebookId': 'nb_journal',
//       'dateCreated': now.subtract(const Duration(days: 1)).toIso8601String(),
//     });
//
// // Note from 3 days ago
//     await db.insert('notes', {
//       'id': 'note_3days_ago',
//       'title': 'Weekly Goal Planning',
//       'content': 'Setting up priorities for the upcoming week.',
//       'notebookId': 'nb_journal',
//       'dateCreated': now.subtract(const Duration(days: 3)).toIso8601String(),
//     });
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
