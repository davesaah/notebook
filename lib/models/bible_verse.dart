class BibleVerse {
  final int bookNumber;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.bookNumber,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromMap(Map<String, dynamic> map) {
    return BibleVerse(
      bookNumber: map['book_id'] ?? 0,
      chapter: map['chapter'] ?? 0,
      verse: map['verse'] ?? 0,
      text: map['text'] ?? '',
    );
  }
}
