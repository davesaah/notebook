import 'package:flutter/material.dart';
import '../../services/bible_helper.dart';

class BiblePickerSheet extends StatefulWidget {
  final Function({
  required String translation,
  required String bookName,
  required int bookNumber,
  required int chapter,
  required int startVerse,
  int? endVerse,
  }) onVerseSelected;

  const BiblePickerSheet({super.key, required this.onVerseSelected});

  @override
  State<BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends State<BiblePickerSheet> {
  String _selectedTranslation = 'KJV';
  List<Map<String, dynamic>> _booksList = [];
  int? _selectedBookId; // Store ID instead of Map reference

  final TextEditingController _chapterController = TextEditingController(text: '1');
  final TextEditingController _startVerseController = TextEditingController(text: '1');
  final TextEditingController _endVerseController = TextEditingController();
  bool _isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    _loadBooksForTranslation(_selectedTranslation);
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _startVerseController.dispose();
    _endVerseController.dispose();
    super.dispose();
  }

  // Dynamically load books table (KJV_books or YLT_books) from SQLite
  Future<void> _loadBooksForTranslation(String translation) async {
    setState(() => _isLoadingBooks = true);

    final books = await BibleHelper.getBooks(translation);

    setState(() {
      _booksList = books;
      if (books.isNotEmpty) {
        _selectedBookId = books.first['id'] as int;
      }
      _isLoadingBooks = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Insert Scripture',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                dropdownColor: const Color(0xFF333333),
                value: _selectedTranslation,
                items: ['KJV', 'YLT']
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(color: Colors.amber)),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedTranslation) {
                    setState(() => _selectedTranslation = val);
                    _loadBooksForTranslation(val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Book Selector
          if (_isLoadingBooks)
            const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: Colors.amber)))
          else
            DropdownButtonFormField<int>(
              dropdownColor: const Color(0xFF333333),
              initialValue: _selectedBookId,
              decoration: const InputDecoration(
                labelText: 'Book',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              style: const TextStyle(color: Colors.white),
              items: _booksList
                  .map((bookMap) => DropdownMenuItem<int>(
                value: bookMap['id'] as int,
                child: Text(bookMap['name'] ?? ''),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBookId = val),
            ),

          const SizedBox(height: 12),

          // Chapter, Start Verse, and Optional End Verse Inputs
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _chapterController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Chapter',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _startVerseController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'From Verse',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endVerseController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'To Verse (Opt)',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C5E58)),
              onPressed: _selectedBookId == null
                  ? null
                  : () {
                final chapter = int.tryParse(_chapterController.text) ?? 1;
                final startVerse = int.tryParse(_startVerseController.text) ?? 1;
                final rawEndVerse = int.tryParse(_endVerseController.text);

                // Ensure endVerse is valid and higher than startVerse
                final endVerse = (rawEndVerse != null && rawEndVerse > startVerse)
                    ? rawEndVerse
                    : null;

                final selectedBookMap = _booksList.firstWhere(
                      (b) => b['id'] == _selectedBookId,
                  orElse: () => {'name': ''},
                );

                widget.onVerseSelected(
                  translation: _selectedTranslation,
                  bookName: selectedBookMap['name'],
                  bookNumber: _selectedBookId!,
                  chapter: chapter,
                  startVerse: startVerse,
                  endVerse: endVerse,
                );
                Navigator.pop(context);
              },
              child: const Text('Insert Verse', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}