import 'package:flutter/material.dart';
import 'package:notebook/views/widgets/create_notebook_sheet.dart';

import '../models/notebook.dart';
import '../models/note.dart';
import '../services/database_helper.dart';
import 'edit_note_screen.dart';
import 'widgets/notebook_card.dart';

import 'package:intl/intl.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  List<Notebook> _notebooks = [];
  List<Note> _notes = [];
  bool _isLoading = true;
  String? _selectedNotebookId; // Set to null initially

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final notebooks = await DatabaseHelper.instance.getAllNotebooks();

    // Default to the first notebook (Journal) if none selected
    if (_selectedNotebookId == null && notebooks.isNotEmpty) {
      _selectedNotebookId = notebooks.first.id;
    }

    final notes = _selectedNotebookId != null
        ? await DatabaseHelper.instance.getNotesByNotebook(_selectedNotebookId!)
        : await DatabaseHelper.instance.getAllNotes();

    setState(() {
      _notebooks = notebooks;
      _notes = notes;
      _isLoading = false;
    });
  }

  // Resolves title for current selection
  String get _currentNotebookTitle {
    final match = _notebooks.where((nb) => nb.id == _selectedNotebookId);
    return match.isNotEmpty ? match.first.title : 'Notes';
  }

  @override
  Widget build(BuildContext context) {
    final totalNoteCount = _notebooks.fold<int>(
      0,
      (sum, item) => sum + item.noteCount,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Notes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMenuPopup(context),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Horizontal Carousel
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _notebooks.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final notebook = _notebooks[index];
                        return NotebookCard(
                          title: notebook.title,
                          color: notebook.color,
                          count: notebook.noteCount,
                          onTap: () async {
                            _selectedNotebookId = notebook.id;
                            await _refreshData();
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Header switches dynamically depending on selected notebook
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentNotebookTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
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
                              final activeId =
                                  _selectedNotebookId ??
                                  (_notebooks.isNotEmpty
                                      ? _notebooks.first.id
                                      : 'nb_journal');
                              final created = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditNoteScreen(
                                    notebookName: _currentNotebookTitle,
                                    notebookId: activeId,
                                  ),
                                ),
                              );

                              if (created == true) {
                                await _refreshData();
                              }
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'New Note',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Notes List View
                  if (_notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No notes found in this notebook',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        final dayStr = DateFormat('d').format(note.dateCreated);
                        final monthStr = DateFormat('MMM')
                            .format(note.dateCreated)
                            .toUpperCase();

                        // Check if the previous note was created on the exact same date
                        bool showDate = true;
                        if (index > 0) {
                          final prevNote = _notes[index - 1];
                          showDate = !(note.dateCreated.year == prevNote.dateCreated.year &&
                              note.dateCreated.month == prevNote.dateCreated.month &&
                              note.dateCreated.day == prevNote.dateCreated.day);
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 44,
                              child:

                              showDate
                                  ? Column(
                                children: [
                                  Text(
                                    dayStr,
                                    style: const TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    monthStr,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )

                                  : const SizedBox.shrink(), // Keeps alignment clean without showing duplicate date


                            ),
                            const SizedBox(width: 8),

                            // Note Card Container (Right)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2B2B2B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            note.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      note.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Notebook Tag Badge (Bottom Right Alignment)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getNotebookColor(
                                            note.notebookId,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _getNotebookName(note.notebookId),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  void _showMenuPopup(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 16, 0),
      color: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const CreateNotebookSheet(),
              ).then((_) => _refreshData());
            });
          },
          child: const Row(
            children: [
              Text('New Notebook', style: TextStyle(color: Colors.white)),
              Spacer(),
              Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
            ],
          ),
        ),
        const PopupMenuItem(
          child: Row(
            children: [
              Text('Manage Notebooks', style: TextStyle(color: Colors.white)),
              Spacer(),
              Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to look up a notebook's color by its ID
  Color _getNotebookColor(String notebookId) {
    final match = _notebooks.where((nb) => nb.id == notebookId);
    return match.isNotEmpty ? match.first.color : const Color(0xFFC84B31);
  }

  // Helper method to look up a notebook's name by its ID
  String _getNotebookName(String notebookId) {
    final match = _notebooks.where((nb) => nb.id == notebookId);
    return match.isNotEmpty ? match.first.title : 'Notes';
  }
}
