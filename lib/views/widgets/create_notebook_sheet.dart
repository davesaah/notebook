import 'dart:math';

import 'package:flutter/material.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/models/notebook.dart';
import 'package:notebook/services/database_helper.dart';

class CreateNotebookSheet extends StatefulWidget {
  const CreateNotebookSheet({super.key});

  @override
  State<CreateNotebookSheet> createState() => _CreateNotebookSheetState();
}

class _CreateNotebookSheetState extends State<CreateNotebookSheet> {
  final _titleController = TextEditingController();
  late Color _selectedColor;

  static final _colorOptions = [
    CustomColors.burntOrange,
    CustomColors.darkTealGreen,
    CustomColors.lightCaramel,
    CustomColors.mutedSlateBlue,
    CustomColors.dustyPurple,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = _colorOptions[Random().nextInt(_colorOptions.length)];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final newNotebook = Notebook(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      color: _selectedColor,
      noteCount: 0,
    );

    await DatabaseHelper.instance.createNotebook(newNotebook);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(newNotebook);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Notebook',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Notebook Title',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.amber),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Accent Color',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.darkTealGreen,
              ),
              onPressed: _handleCreate,
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
