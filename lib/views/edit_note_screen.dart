import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notebook/models/note.dart';
import 'package:notebook/services/database_helper.dart';

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

  bool _showMentionMenu = false;
  String _mentionQuery = '';

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');

    // Listen for '@' input to trigger mention/verse overlay
    _quillController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _quillController.document.toPlainText();
    final selection = _quillController.selection;

    if (!selection.isCollapsed || selection.start <= 0) {
      if (_showMentionMenu) setState(() => _showMentionMenu = false);
      return;
    }

    // Check character before current cursor position
    final lastChar = text.substring(selection.start - 1, selection.start);
    if (lastChar == '@') {
      setState(() {
        _showMentionMenu = true;
        _mentionQuery = '';
      });
    } else if (_showMentionMenu && lastChar == ' ') {
      setState(() => _showMentionMenu = false);
    }
  }

  void _insertReference(String referenceText) {
    final selection = _quillController.selection;

    // Replace '@' with selected reference chip text
    _quillController.replaceText(
      selection.start - 1,
      1,
      '@$referenceText ',
      TextSelection.collapsed(
        offset: selection.start + referenceText.length + 1,
      ),
    );

    setState(() => _showMentionMenu = false);
  }

  @override
  void dispose() {
    _quillController.removeListener(_onTextChanged);
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5E58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                final title = _titleController.text.trim();
                final jsonContent = jsonEncode(
                  _quillController.document.toDelta().toJson(),
                );

                if (title.isNotEmpty) {
                  final newNote = Note(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    content: jsonContent,
                    notebookId: widget.notebookId,
                    dateCreated: DateTime.now(),
                  );

                  await DatabaseHelper.instance.createNote(newNote);
                }

                if (context.mounted) {
                  Navigator.pop(
                    context,
                    true,
                  ); // Return true to trigger home screen refresh
                }
              },
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView(
                    children: [
                      // Note Title Field
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rich Text Writing Area
                      QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _editorFocusNode,
                        config: const QuillEditorConfig(
                          placeholder: 'Start typing...',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Metadata Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved to ${widget.notebookName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Text(
                      'August 21, 2026',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Formatting Toolbar
              Container(
                color: const Color(0xFF282828),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {},
                      ),
                      QuillSimpleToolbar(
                        controller: _quillController,
                        config: const QuillSimpleToolbarConfig(
                          showFontFamily: false,
                          showFontSize: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showAlignmentButtons: false,
                          showLeftAlignment: false,
                          showCenterAlignment: false,
                          showRightAlignment: false,
                          showJustifyAlignment: false,
                          showHeaderStyle: true,
                          showCodeBlock: false,
                          showInlineCode: false,
                          showQuote: false,
                          showLink: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Mention Trigger Overlay
          if (_showMentionMenu)
            Positioned(
              left: 20,
              bottom: 120,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2A3A3F),
                child: Container(
                  width: 220,
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          '@Mention a verse...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      ListTile(
                        dense: true,
                        title: const Text(
                          'Psalm 1:2',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () => _insertReference('ps1:2'),
                      ),
                      ListTile(
                        dense: true,
                        title: const Text(
                          'John 3:16',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () => _insertReference('john3:16'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
