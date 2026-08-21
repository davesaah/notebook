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
}
