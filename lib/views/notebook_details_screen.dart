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
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes(showLoading: true);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes({bool showLoading = false}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final notes = await DatabaseHelper.instance.getNotesForNotebook(
        widget.notebook.id,
      );

      if (!mounted) return;

      setState(() {
        _notes = notes;
        _isLoading = false;
      });

      await _applySearchFilter();
    } finally {
      _isRefreshing = false;
    }
  }

  void _onSearchChanged() {
    _applySearchFilter();
  }

  Future<void> _applySearchFilter() async {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _filteredNotes = List.from(_notes);
      });

      return;
    }

    final results = await DatabaseHelper.instance.searchNotesInNotebook(
      query,
      widget.notebook.id,
    );

    if (!mounted) return;

    setState(() {
      _filteredNotes = results;
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Search notebook...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              )
            : null,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
        ],
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
                  // Hide title & New Note button while searching
                  if (!_isSearching || _searchController.text.isEmpty) ...[
                    Text(
                      widget.notebook.title.toUpperCase(),
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
                          await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditNoteScreen(
                                notebookId: widget.notebook.id,
                                onNoteSaved: _loadNotes,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'New Note',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notes List View
                  if (_filteredNotes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No notes found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredNotes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final note = _filteredNotes[index];

                        bool showDate = true;
                        if (index > 0) {
                          final prevNote = _filteredNotes[index - 1];
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
                            await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditNoteScreen(
                                  noteId: note.id,
                                  initialTitle: note.title,
                                  initialContent: note.content,
                                  initialDateCreated: note.dateCreated,
                                  notebookId: widget.notebook.id,
                                  onNoteSaved: _loadNotes,
                                ),
                              ),
                            );
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
