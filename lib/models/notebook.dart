import 'package:flutter/material.dart';

class Notebook {
  final String id;
  final String title;
  final Color color;
  final int noteCount;

  Notebook({
    required this.id,
    required this.title,
    required this.color,
    this.noteCount = 0,
  });

  // Convert Notebook instance to Map for SQLite database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color.toARGB32(),
      'note_count': noteCount,
    };
  }

  // Factory to create a Notebook instance from a SQLite Map
  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'] as String,
      title: map['title'] as String,
      color: Color(map['color'] as int),
      noteCount: map['note_count'] as int? ?? 0,
    );
  }
}
