import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/note.dart';
import '../services/database_helper.dart';

class EditNoteScreen extends StatefulWidget {
  final String? initialTitle;
  final String notebookName;
  final String notebookId;

  const EditNoteScreen({
    super.key,
    this.initialTitle,
    required this.notebookName,
    required this.notebookId,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late final QuillController _quillController;
  late final TextEditingController _titleController;
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _quillController.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5E58),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () async {
                final title = _titleController.text.trim();
                final plainText = _quillController.document.toPlainText().trim();

                if (title.isNotEmpty || plainText.isNotEmpty) {
                  final newNote = Note(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title.isEmpty ? 'Untitled Note' : title,
                    content: plainText,
                    notebookId: widget.notebookId,
                    dateCreated: DateTime.now(),
                  );

                  await DatabaseHelper.instance.createNote(newNote);
                }

                if (context.mounted) {
                  Navigator.pop(context, true); // Return true to trigger UI refresh
                }
              },
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 24),
                  border: InputBorder.none,
                ),
              ),
            ),
            // Expanded prevents RenderFlex overflow by giving QuillEditor bounded height
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: QuillEditor.basic(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  config: const QuillEditorConfig(
                    placeholder: 'Start typing...',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            Container(
              color: const Color(0xFF282828),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: QuillSimpleToolbar(
                  controller: _quillController,
                  config: const QuillSimpleToolbarConfig(
                    showFontFamily: false,
                    showFontSize: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showAlignmentButtons: false,
                    showHeaderStyle: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}