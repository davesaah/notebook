class Note {
  final String id;
  final String notebookId;
  final String title;
  final String content;
  final DateTime dateCreated;

  Note({
    required this.id,
    required this.notebookId,
    required this.title,
    required this.content,
    required this.dateCreated,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      notebookId: map['notebook_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      dateCreated: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebook_id': notebookId,
      'title': title,
      'content': content,
      'created_at': dateCreated.toIso8601String(),
    };
  }
}