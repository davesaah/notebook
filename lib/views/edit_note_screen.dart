import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/models/bible_verse.dart';
import 'package:notebook/models/note.dart';
import 'package:notebook/services/database_helper.dart';
import 'package:notebook/services/bible_helper.dart';
import 'package:notebook/views/widgets/bible_picker_sheet.dart';

class EditNoteScreen extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  final String? initialContent;
  final String notebookId;
  final DateTime? initialDateCreated;
  final Future<void> Function()? onNoteSaved;

  const EditNoteScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
    required this.notebookId,
    this.initialDateCreated,
    this.onNoteSaved,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late final QuillController _quillController;
  late final TextEditingController _titleController;
  late final DateTime _dateCreated;
  Timer? _autoSaveTimer;
  late String _noteId;
  String? _lastSavedTitle;
  String? _lastSavedContent;
  bool _noteExists = false;

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _noteExists = widget.noteId != null;
    _lastSavedTitle = widget.initialTitle?.trim() ?? '';
    _lastSavedContent = widget.initialContent ?? '';
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _dateCreated = widget.initialDateCreated ?? DateTime.now();

    // decode existing note contents to show rich text
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      final json = jsonDecode(widget.initialContent!);
      final doc = Document.fromJson(json);
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      // present a fresh rich text editor
      _quillController = QuillController.basic();
    }

    _titleController.addListener(_onNoteChanged);
    _quillController.addListener(_onNoteChanged);
  }

  void _onNoteChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), _autoSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.removeListener(_onNoteChanged);
    _quillController.removeListener(_onNoteChanged);
    _quillController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _stripItalicMarkers(
    String input,
    int inputBufferLength,
    List<MapEntry<int, int>> ranges,
  ) {
    final regex = RegExp(r'<FI>(.*?)<Fi>'); // italic markers in YLT
    final buffer = StringBuffer();
    int lastEnd = 0;

    for (final match in regex.allMatches(input)) {
      buffer.write(input.substring(lastEnd, match.start));
      final italicStart = inputBufferLength + buffer.length;
      final content = match.group(1)!;
      buffer.write(content);
      ranges.add(MapEntry(italicStart, content.length));
      lastEnd = match.end;
    }
    buffer.write(input.substring(lastEnd));
    return buffer.toString();
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
      verses.add(singleVerse);
    }
    if (verses.isEmpty) return;

    // Build quoteBody while tracking italic ranges relative to quoteBody's own start
    final List<MapEntry<int, int>> relativeItalicRanges = [];
    final quoteBuffer = StringBuffer();

    if (verses.length == 1) {
      quoteBuffer.write('"');
      final cleaned = _stripItalicMarkers(
        verses.first.text,
        quoteBuffer.length,
        relativeItalicRanges,
      );
      quoteBuffer.write(cleaned);
      quoteBuffer.write('"');
    } else {
      for (var i = 0; i < verses.length; i++) {
        final v = verses[i];
        quoteBuffer.write('${v.verse}. ');
        final cleaned = _stripItalicMarkers(
          v.text,
          quoteBuffer.length,
          relativeItalicRanges,
        );
        quoteBuffer.write(cleaned);
        if (i != verses.length - 1) quoteBuffer.write('\n');
      }
    }

    final String quoteBody = quoteBuffer.toString();
    final int verseRefStart = quoteBody.length;
    final verseRef = endVerse != null
        ? '$bookName $chapter:$startVerse-$endVerse ($translation)'
        : '$bookName $chapter:$startVerse ($translation)';
    final int verseRefEnd = verseRefStart + verseRef.length;
    final fullInsertedText = '\n$quoteBody\n$verseRef\n\n';

    final index = _quillController.selection.baseOffset;
    final targetIndex = index < 0
        ? _quillController.document.length - 1
        : index;

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

    // 2b. Apply bold + italics to show where <FI>..<Fi> markers were
    for (final range in relativeItalicRanges) {
      _quillController.formatText(
        formatStart + range.key,
        range.value,
        Attribute.italic,
      );
      _quillController.formatText(
        formatStart + range.key,
        range.value,
        Attribute.bold,
      );
    }

    // 2c. Make verse reference bold
    _quillController.formatText(
      formatStart + verseRefStart,
      verseRefEnd,
      Attribute.bold,
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
      backgroundColor: CustomColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: CustomColors.scaffoldBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.darkTealGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _saveNote,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(_dateCreated),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 24),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: QuillEditor.basic(
                  controller: _quillController,
                  config: const QuillEditorConfig(
                    placeholder: 'Start typing...',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            Container(
              color: CustomColors.containerBackground,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(ctx).viewInsets.bottom,
                          ),
                          child: BiblePickerSheet(
                            onVerseSelected:
                                ({
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

  Future<void> _saveNote() async {
    _autoSaveTimer?.cancel();

    await _autoSave();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _autoSave() async {
    final title = _titleController.text.trim();
    final content = _quillController.document.toPlainText().trim();

    if (title.isEmpty && content.isEmpty) {
      return;
    }

    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    final hasChanged =
        title != _lastSavedTitle || deltaJson != _lastSavedContent;

    if (!hasChanged) {
      return;
    }

    final noteToSave = Note(
      id: _noteId,
      title: title.isEmpty ? 'Untitled Note' : title,
      content: deltaJson,
      notebookId: widget.notebookId,
      dateCreated: _dateCreated,
    );

    if (_noteExists) {
      await DatabaseHelper.instance.updateNote(noteToSave);
    } else {
      await DatabaseHelper.instance.createNote(noteToSave);
      _noteExists = true;
    }

    // Update local snapshot only after the database save succeeds.
    _lastSavedTitle = title;
    _lastSavedContent = deltaJson;

    // Tell the previous screen that the note has changed.
    await widget.onNoteSaved?.call();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, ${date.year} · $hour12:$minute $period';
  }
}
