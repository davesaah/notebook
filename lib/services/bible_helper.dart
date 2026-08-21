// lib/services/bible_helper.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BibleVerse {
  final int bookNumber;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.bookNumber,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromMap(Map<String, dynamic> map) {
    return BibleVerse(
      bookNumber: map['book_id'] ?? 0,
      chapter: map['chapter'] ?? 0,
      verse: map['verse'] ?? 0,
      text: map['text'] ?? '',
    );
  }
}

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

    // Force delete cached DB so Flutter copies the clean asset version
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    ByteData data = await rootBundle.load('assets/bible/$dbFileName');
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await file.writeAsBytes(bytes, flush: true);

    return await openDatabase(path, readOnly: true);
  }

  // Fetch all books dynamically from KJV_books or YLT_books
  static Future<List<Map<String, dynamic>>> getBooks(String translation) async {
    final db = await getDatabase(translation);
    final tableName = '${translation.toUpperCase()}_books';

    return await db.query(tableName, orderBy: 'id ASC');
  }

  // Fetch a single verse
  static Future<BibleVerse?> getVerse({
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

    if (maps.isNotEmpty) {
      return BibleVerse.fromMap(maps.first);
    }
    return null;
  }

  // Fetch an entire chapter
  static Future<List<BibleVerse>> getChapter({
    required String translation,
    required int book,
    required int chapter,
  }) async {
    final db = await getDatabase(translation);
    final tableName = '${translation.toUpperCase()}_verses';

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse ASC',
    );

    return List.generate(maps.length, (i) => BibleVerse.fromMap(maps[i]));
  }
}