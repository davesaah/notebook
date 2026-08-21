import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/note.dart';
import '../services/database_helper.dart';
import '../services/bible_helper.dart';
import 'widgets/bible_picker_sheet.dart';

class EditNoteScreen extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  final String? initialContent;
  final String notebookName;
  final String notebookId;

  const EditNoteScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
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
    _titleController = TextEditingController(text: widget.initialTitle ?? '');

    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      final doc = Document()..insert(0, widget.initialContent!);
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _insertVerse({
    required String translation,
    required String bookName,
    required int bookNumber,
    required int chapter,
    required int startVerse,
    int? endVerse,
  }) async {
    List<BibleVerse> verses = [];

    if (endVerse != null && endVerse > startVerse) {
      verses = await BibleHelper.getVerseRange(
        translation: translation,
        book: bookNumber,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
      );
    } else {
      final singleVerse = await BibleHelper.getVerse(
        translation: translation,
        book: bookNumber,
        chapter: chapter,
        verse: startVerse,
      );
      if (singleVerse != null) verses.add(singleVerse);
    }

    if (verses.isEmpty) return;

    // Format single verse vs multiline range
    final String quoteBody = verses.length == 1
        ? '"${verses.first.text}"'
        : verses.map((v) => '${v.verse}. ${v.text}').join('\n');

    final verseRef = endVerse != null
        ? '— $bookName $chapter:$startVerse–$endVerse ($translation)'
        : '— $bookName $chapter:$startVerse ($translation)';

    final fullInsertedText = '\n$quoteBody\n$verseRef\n\n';

    final index = _quillController.selection.baseOffset;
    final targetIndex = index < 0 ? _quillController.document.length - 1 : index;

    // 1. Insert text into document
    _quillController.document.insert(targetIndex, fullInsertedText);

    // 2. Format verse block and citation as blockquote
    final formatStart = targetIndex + 1;
    final formatLength = quoteBody.length + 1 + verseRef.length + 1;

    _quillController.formatText(
      formatStart,
      formatLength,
      Attribute.blockQuote,
    );

    // 3. Explicitly strip blockquote attribute from the final new line
    final newCursorOffset = targetIndex + fullInsertedText.length;
    _quillController.formatText(
      newCursorOffset - 1,
      1,
      Attribute.clone(Attribute.blockQuote, null),
    );

    // 4. Move cursor to the clean line
    _quillController.updateSelection(
      TextSelection.collapsed(offset: newCursorOffset),
      ChangeSource.local,
    );
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
                  final noteToSave = Note(
                    id: widget.noteId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title.isEmpty ? 'Untitled Note' : title,
                    content: plainText,
                    notebookId: widget.notebookId,
                    dateCreated: DateTime.now(),
                  );

                  if (widget.noteId != null) {
                    await DatabaseHelper.instance.updateNote(noteToSave);
                  } else {
                    await DatabaseHelper.instance.createNote(noteToSave);
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context, true);
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                          child: BiblePickerSheet(
                            onVerseSelected: ({
                              required String translation,
                              required String bookName,
                              required int bookNumber,
                              required int chapter,
                              required int startVerse,
                              int? endVerse,
                            }) {
                              _insertVerse(
                                translation: translation,
                                bookName: bookName,
                                bookNumber: bookNumber,
                                chapter: chapter,
                                startVerse: startVerse,
                                endVerse: endVerse,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
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
          ],
        ),
      ),
    );
  }
}