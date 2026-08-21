import 'package:flutter/material.dart';
import 'package:notebook/models/notebook.dart';
import 'package:notebook/services/database_helper.dart';

class CreateNotebookSheet extends StatefulWidget {
  const CreateNotebookSheet({super.key});

  @override
  State<CreateNotebookSheet> createState() => _CreateNotebookSheetState();
}

class _CreateNotebookSheetState extends State<CreateNotebookSheet> {
  final _titleController = TextEditingController();
  Color _selectedColor = const Color(0xFF5B84B1);

  final List<Color> _palette = const [
    Color(0xFF5B84B1),
    Color(0xFFA26D53),
    Color(0xFFC84B31),
    Color(0xFFD3E4CD),
    Color(0xFF707070),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create New Notebook',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Notebook Preview
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _titleController.text.isEmpty ? 'NEW NOTEBOOK' : _titleController.text.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            onChanged: (val) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Notebook Title',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _palette.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _selectedColor == color
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
                backgroundColor: const Color(0xFF3E3E3E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () async {
                final rawTitle = _titleController.text.trim();
                final title = rawTitle.isEmpty ? 'NEW NOTEBOOK' : rawTitle;

                final newNotebook = Notebook(
                  id: 'nb_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  color: _selectedColor,
                );

                await DatabaseHelper.instance.createNotebook(newNotebook);

                if (context.mounted) {
                  Navigator.pop(context, true); // Return true to trigger home screen refresh
                }
              },
              child: const Text('Create notebook', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}