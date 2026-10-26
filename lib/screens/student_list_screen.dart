// lib/screens/student_list_screen.dart
// Displays all students with a live-filter search bar.
// Tap a card → Student Detail. Long-press → Delete confirmation.

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../widgets/student_card.dart';
import '../widgets/empty_state.dart';
import 'student_detail_screen.dart';
import 'add_edit_student_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();

  List<Student> _students = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final list = _query.isEmpty
        ? await _db.getAllStudents()
        : await _db.searchStudents(_query);
    if (mounted) {
      setState(() {
        _students  = list;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());
    _loadStudents();
  }

  // Delete student with confirmation dialog
  Future<void> _confirmDelete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
            'Are you sure you want to delete ${student.fullName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && student.id != null) {
      await _db.deleteStudent(student.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} has been deleted.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      _loadStudents();
    }
  }

  // Navigate to detail, then reload on return
  Future<void> _openDetail(Student student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => StudentDetailScreen(student: student)),
    );
    _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text(
          'All Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, roll no. or course…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Student count label
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
              child: Row(
                children: [
                  Text(
                    '${_students.length} student${_students.length == 1 ? '' : 's'}'
                    '${_query.isNotEmpty ? ' found' : ' registered'}',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // ── List or empty state ────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? EmptyState(
                        icon: _query.isEmpty
                            ? Icons.people_outline_rounded
                            : Icons.search_off_rounded,
                        title: _query.isEmpty
                            ? 'No Students Yet'
                            : 'No Results Found',
                        subtitle: _query.isEmpty
                            ? 'Tap the + button to add your first student.'
                            : 'Try a different name, roll number, or course.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: _students.length,
                        itemBuilder: (_, i) => StudentCard(
                          student: _students[i],
                          onTap:       () => _openDetail(_students[i]),
                          onLongPress: () => _confirmDelete(_students[i]),
                        ),
                      ),
          ),
        ],
      ),

      // FAB to add a new student
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditStudentScreen()),
          );
          _loadStudents();
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
