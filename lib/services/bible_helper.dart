import 'dart:io';

import 'package:flutter/services.dart';
import 'package:notebook/models/bible_verse.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BibleHelper {
  static final Map<String, Database> _databases = {};

  // Open database connection for target translation ('KJV' or 'YLT')
  static Future<Database> getDatabase(String translation) async {
    final key = translation.toUpperCase();
    if (_databases.containsKey(key)) {
      return _databases[key]!;
    }

    final db = await _initBibleDatabase('$key.db');
    _databases[key] = db;
    return db;
  }

  static Future<Database> _initBibleDatabase(String dbFileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbFileName);
    final file = File(path);

    if (!await file.exists()) {
      // Ensure the databases directory exists
      await Directory(dbPath).create(recursive: true);

      // Load the bundled asset database
      final ByteData data = await rootBundle.load('assets/bible/$dbFileName');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write to a temp file first, then rename into place.
      // Avoids ever leaving a missing/corrupted DB if the write is interrupted.
      final tempFile = File('$path.tmp');
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(path);
    }

    return await openDatabase(path, readOnly: true);
  }

  // Fetch all books dynamically from KJV_books or YLT_books
  static Future<List<Map<String, dynamic>>> getBooks(String translation) async {
    final db = await getDatabase(translation);
    final tableName = '${translation.toUpperCase()}_books';

    return await db.query(tableName, orderBy: 'id ASC');
  }

  // Fetch a range of verses (e.g. verses 16 to 18)
  static Future<List<BibleVerse>> getVerseRange({
    required String translation,
    required int book,
    required int chapter,
    required int startVerse,
    required int endVerse,
  }) async {
    final db = await getDatabase(translation);
    final tableName = '${translation.toUpperCase()}_verses';

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'book_id = ? AND chapter = ? AND verse >= ? AND verse <= ?',
      whereArgs: [book, chapter, startVerse, endVerse],
      orderBy: 'verse ASC',
    );

    return List.generate(maps.length, (i) => BibleVerse.fromMap(maps[i]));
  }

  // Fetch a single verse
  static Future<BibleVerse> getVerse({
    required String translation,
    required int book,
    required int chapter,
    required int verse,
  }) async {
    final db = await getDatabase(translation);
    final tableName = '${translation.toUpperCase()}_verses';

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'book_id = ? AND chapter = ? AND verse = ?',
      whereArgs: [book, chapter, verse],
      limit: 1,
    );

    return BibleVerse.fromMap(maps.first);
  }
}
