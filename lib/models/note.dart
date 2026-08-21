class Note {
  final String id;
  final String title;
  final String content;
  final String notebookId;
  final DateTime dateCreated;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.notebookId,
    required this.dateCreated,
  });
}
