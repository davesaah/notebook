import 'package:flutter/material.dart';
import 'package:notebook/models/notebook.dart';
import 'package:notebook/models/note.dart';
import 'package:notebook/services/database_helper.dart';
import 'package:notebook/views/edit_note_screen.dart';
import 'package:notebook/views/widgets/notebook_card.dart';
import 'package:notebook/views/widgets/create_notebook_sheet.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  List<Notebook> _notebooks = [];
  List<Note> _notes = [];
  bool _isLoading = true;
  String _selectedNotebookId = 'all';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final notebooks = await DatabaseHelper.instance.getAllNotebooks();
    final notes = _selectedNotebookId == 'all'
        ? await DatabaseHelper.instance.getAllNotes()
        : await DatabaseHelper.instance.getNotesByNotebook(_selectedNotebookId);

    setState(() {
      _notebooks = notebooks;
      _notes = notes;
      _isLoading = false;
    });
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
        const PopupMenuItem(
          child: Row(
            children: [
              Text('Recently Deleted', style: TextStyle(color: Colors.white)),
              Spacer(),
              Icon(Icons.delete_outline, color: Colors.white, size: 20),
            ],
          ),
        ),
      ],
    );
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
                  // Horizontal Notebook Carousel
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _notebooks.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return NotebookCard(
                            title: 'ALL NOTES',
                            color: Colors.white,
                            count: totalNoteCount,
                            onTap: () {
                              setState(() => _selectedNotebookId = 'all');
                              _refreshData();
                            },
                          );
                        }
                        final notebook = _notebooks[index - 1];
                        return NotebookCard(
                          title: notebook.title,
                          color: notebook.color,
                          count: notebook.noteCount,
                          onTap: () {
                            setState(() => _selectedNotebookId = notebook.id);
                            _refreshData();
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pinned Bible banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.push_pin_outlined,
                            size: 18,
                            color: Color(0xFF2C5E58),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No notes pinned in Bible',
                            style: TextStyle(
                              color: Color(0xFF2C5E58),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Header & New Note Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All Notes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Date Created (Newest)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
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
                              final defaultNotebook = _notebooks.isNotEmpty
                                  ? _notebooks.first
                                  : null;
                              final created = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditNoteScreen(
                                    notebookName:
                                        defaultNotebook?.title ?? 'Notes',
                                    notebookId:
                                        defaultNotebook?.id ?? 'nb_notes',
                                  ),
                                ),
                              );
                              if (created == true) _refreshData();
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

                  // Notes List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Container(
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
                                Text(
                                  note.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
