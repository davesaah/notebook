import 'package:flutter/material.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/models/note.dart';
import 'package:notebook/models/notebook.dart';
import 'package:notebook/services/database_helper.dart';
import 'package:notebook/views/notebook_details_screen.dart';
import 'package:notebook/views/settings_screen.dart';
import 'package:notebook/views/widgets/create_notebook_sheet.dart';
import 'package:notebook/views/widgets/note_tile.dart';
import 'package:notebook/views/widgets/notebook_card.dart';
import 'package:notebook/views/edit_note_screen.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  List<Notebook> _notebooks = [];
  List<Note> _searchResults = [];
  bool _isLoading = true;

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

    if (!mounted) return;

    setState(() {
      _notebooks = notebooks;
      _isLoading = false;
    });

    if (_isSearching) {
      _applySearchFilter();
    }
  }

  void _onSearchChanged() {
    _applySearchFilter();
  }

  void _applySearchFilter() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final results = await DatabaseHelper.instance.searchAllNotes(query);
    if (!mounted) return;

    setState(() {
      _searchResults = results;
    });
  }

  Notebook _notebookById(String id) =>
      _notebooks.firstWhere((nb) => nb.id == id);

  void _showCreateNotebookDialog() async {
    final newNotebook = await showModalBottomSheet<Notebook>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF232323),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const CreateNotebookSheet(),
    );

    if (newNotebook != null && mounted) {
      await _refreshData();
    }
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
                'Notebook',
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
                  _searchResults.clear();
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                if (changed == true && mounted) {
                  await _refreshData();
                }
              },
            ),
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
              child: _isSearching && _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : _buildNotebooksGrid(),
            ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No notes found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final note = _searchResults[index];
        return NoteTile(
          note: note,
          showDate: true,
          notebookName: _notebookById(note.notebookId).title,
          notebookColor: _notebookById(note.notebookId).color,
          onTap: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => EditNoteScreen(
                  noteId: note.id,
                  initialTitle: note.title,
                  initialContent: note.content,
                  initialDateCreated: note.dateCreated,
                  notebookId: note.notebookId,
                ),
              ),
            );
            if (updated == true) await _refreshData();
          },
        );
      },
    );
  }

  Widget _buildNotebooksGrid() {
    if (_notebooks.isEmpty) {
      return const Center(
        child: Text(
          'No notebooks created yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust column count based on available width (~180px per item minimum)
        int crossAxisCount = (constraints.maxWidth / 180).floor();
        if (crossAxisCount < 2) {
          crossAxisCount = 2; // At least 2 columns on small screens
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1, // Aspect ratio to fit NotebookCard design
          ),
          itemCount: _notebooks.length,
          itemBuilder: (context, index) {
            final notebook = _notebooks[index];
            return NotebookCard(
              title: notebook.title,
              color: notebook.color,
              count: notebook.noteCount,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotebookDetailsScreen(notebook: notebook),
                  ),
                );
                await _refreshData();
              },
            );
          },
        );
      },
    );
  }
}
