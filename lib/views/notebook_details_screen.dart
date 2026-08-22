import 'package:flutter/material.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/models/note.dart';
import 'package:notebook/models/notebook.dart';
import 'package:notebook/services/database_helper.dart';
import 'package:notebook/views/edit_note_screen.dart';
import 'package:notebook/views/widgets/note_tile.dart';

class NotebookDetailsScreen extends StatefulWidget {
  final Notebook notebook;

  const NotebookDetailsScreen({super.key, required this.notebook});

  @override
  State<NotebookDetailsScreen> createState() => _NotebookDetailsScreenState();
}

class _NotebookDetailsScreenState extends State<NotebookDetailsScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await DatabaseHelper.instance.getNotesForNotebook(
      widget.notebook.id,
    );
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: CustomColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                children: [
                  // Title & New Note Button
                  Text(
                    widget.notebook.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditNoteScreen(
                              notebookName: widget.notebook.title,
                              notebookId: widget.notebook.id,
                            ),
                          ),
                        );
                        if (created == true) await _loadNotes();
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'New Note',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes List
                  if (_notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No notes in this notebook',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final note = _notes[index];

                        bool showDate = true;
                        if (index > 0) {
                          final prevNote = _notes[index - 1];
                          showDate =
                              !(note.dateCreated.year ==
                                      prevNote.dateCreated.year &&
                                  note.dateCreated.month ==
                                      prevNote.dateCreated.month &&
                                  note.dateCreated.day ==
                                      prevNote.dateCreated.day);
                        }

                        return NoteTile(
                          note: note,
                          showDate: showDate,
                          notebookName: widget.notebook.title,
                          notebookColor: widget.notebook.color,
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditNoteScreen(
                                  noteId: note.id,
                                  initialTitle: note.title,
                                  initialContent: note.content,
                                  initialDateCreated: note.dateCreated,
                                  notebookName: widget.notebook.title,
                                  notebookId: widget.notebook.id,
                                ),
                              ),
                            );
                            if (updated == true) await _loadNotes();
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
