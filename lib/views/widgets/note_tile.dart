import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/models/note.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final bool showDate;
  final String notebookName;
  final Color notebookColor;
  final VoidCallback onTap;

  const NoteTile({
    super.key,
    required this.note,
    required this.showDate,
    required this.notebookName,
    required this.notebookColor,
    required this.onTap,
  });

  String getNotePlainText(String contentJson) {
    final decoded = jsonDecode(contentJson);
    final doc = Document.fromJson(decoded);
    return doc.toPlainText().trim();
  }

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('d').format(note.dateCreated);
    final monthStr = DateFormat('MMM').format(note.dateCreated).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: showDate
              ? Column(
                  children: [
                    Text(
                      dayStr,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      monthStr,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CustomColors.noteTileBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      getNotePlainText(note.content),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: notebookColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notebookName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
