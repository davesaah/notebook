import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notebook/constants/colors.dart';
import 'package:notebook/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _exportDatabase() async {
    setState(() => _busy = true);
    try {
      final bytes = await DatabaseHelper.instance.exportDatabaseBytes();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'notebook_backup_$timestamp.db';

      // Opens the system save dialog to let the user pick a folder and file name
      final outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save Notebook backup',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputPath == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      _showSnack('Backup saved successfully.');
    } catch (e) {
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importDatabase() async {
    final confirmed = await _confirmImport();
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Select a Notebook backup file',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final pickedPath = file.path;
      if (pickedPath == null) {
        throw Exception('Unable to read selected file path.');
      }

      final bytes = await file.readAsBytes();

      // DatabaseHelper validates the SQLite schema structure here
      await DatabaseHelper.instance.importDatabaseBytes(bytes);

      if (!mounted) return;
      _showSnack('Backup restored successfully.');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmImport() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232323),
        title: const Text(
          'Replace all notes?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Importing a backup will permanently replace every note and '
          'notebook currently on this device. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Import',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: CustomColors.scaffoldBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.5 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Data',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.upload_outlined,
                title: 'Export backup',
                subtitle: 'Save all notebooks and notes to a .db file',
                onTap: _exportDatabase,
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Import backup',
                subtitle: 'Replace current data with a .db backup file',
                onTap: _importDatabase,
              ),
              if (_busy) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF232323),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
