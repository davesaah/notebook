import 'dart:math';

import 'package:flutter/material.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/views/widgets/note_tile.dart';
import 'package:notebook/models/note.dart';
import 'package:notebook/models/notebook.dart';
import 'package:notebook/services/database_helper.dart';
import 'package:notebook/views/edit_note_screen.dart';
import 'package:notebook/views/widgets/notebook_card.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  List<Notebook> _notebooks = [];
  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String? _selectedNotebookId;

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final notebooks = await DatabaseHelper.instance.getAllNotebooks();

    if (_selectedNotebookId == null && notebooks.isNotEmpty) {
      _selectedNotebookId = notebooks.first.id;
    }

    final notes = _selectedNotebookId != null
        ? await DatabaseHelper.instance.getNotesForNotebook(
            _selectedNotebookId!,
          )
        : await DatabaseHelper.instance.getAllNotes();

    setState(() {
      _notebooks = notebooks;
      _allNotes = notes;
      _isLoading = false;
    });

    _applySearchFilter(); // it manages its own setState/mounted check
  }

  void _onSearchChanged() {
    _applySearchFilter();
  }

  void _applySearchFilter() async {
    final query = _searchController.text.trim().toLowerCase();
    List<Note> results;

    if (query.isEmpty) {
      results = List.from(_allNotes);
    } else {
      results = await DatabaseHelper.instance.searchAllNotes(query);
    }

    if (!mounted) return; // guard against setState after dispose

    setState(() {
      _filteredNotes = results;
    });
  }

  Notebook _notebookById(String id) =>
      _notebooks.firstWhere((nb) => nb.id == id);

  String get _currentNotebookTitle => _notebookById(_selectedNotebookId!).title;

  Color _getNotebookColor(String notebookId) => _notebookById(notebookId).color;

  String _getNotebookName(String notebookId) => _notebookById(notebookId).title;

  // --- Create Notebook Modal ---
  void _showCreateNotebookDialog() {
    final titleController = TextEditingController();
    final colorOptions = [
      CustomColors.burntOrange,
      CustomColors.darkTealGreen,
      CustomColors.lightCaramel,
      CustomColors.mutedSlateBlue,
      CustomColors.dustyPurple,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF232323),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        final random = Random();
        Color selectedColor = colorOptions[random.nextInt(colorOptions.length)];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Notebook',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Notebook Title',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Accent Color',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: colorOptions.map((color) {
                      final isSelected =
                          selectedColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.darkTealGreen,
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        final newNotebook = Notebook(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          color: selectedColor,
                          noteCount: 0,
                        );

                        // 1. Database insert
                        await DatabaseHelper.instance.createNotebook(
                          newNotebook,
                        );

                        // 2. Pop dialog using root navigator
                        if (modalContext.mounted &&
                            Navigator.canPop(modalContext)) {
                          Navigator.of(modalContext, rootNavigator: true).pop();
                        }

                        // 3. Update parent screen state
                        if (mounted) {
                          setState(() {
                            _selectedNotebookId = newNotebook.id;
                          });
                          await _refreshData();
                        }
                      },
                      child: const Text(
                        'Create',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: CustomColors.scaffoldBackground,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
          else ...[
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.white),
              onPressed: _showCreateNotebookDialog,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Hide Carousel during active search query
                  if (!_isSearching || _searchController.text.isEmpty) ...[
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
                  ],

                  // Section Title & Add Note Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSearching
                              ? 'Search Results'
                              : _currentNotebookTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_isSearching)
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
                                    _selectedNotebookId ?? _notebooks.first.id;
                                final created = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditNoteScreen(
                                      notebookName: _currentNotebookTitle,
                                      notebookId: activeId,
                                    ),
                                  ),
                                );
                                if (created == true) await _refreshData();
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          notebookName: _getNotebookName(note.notebookId),
                          notebookColor: _getNotebookColor(note.notebookId),
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditNoteScreen(
                                  noteId: note.id,
                                  initialTitle: note.title,
                                  initialContent: note.content,
                                  notebookName: _getNotebookName(
                                    note.notebookId,
                                  ),
                                  notebookId: note.notebookId,
                                ),
                              ),
                            );
                            if (updated == true) await _refreshData();
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
