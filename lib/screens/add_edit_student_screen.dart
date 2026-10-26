// lib/screens/add_edit_student_screen.dart
// Shared form for adding a new student (student == null) or editing one (student != null).
// Returns the saved Student object via Navigator.pop so callers can refresh.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/student.dart';

class AddEditStudentScreen extends StatefulWidget {
  /// Pass null (or omit) to add a new student.
  /// Pass an existing Student to pre-fill the form for editing.
  final Student? student;

  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _db         = DatabaseHelper();

  // Text controllers
  late final TextEditingController _rollController;
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _courseController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String _selectedGender = 'Male';
  bool   _isSaving       = false;

  static const _genders = ['Male', 'Female', 'Other'];

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _rollController   = TextEditingController(text: s?.rollNumber ?? '');
    _nameController   = TextEditingController(text: s?.fullName   ?? '');
    _ageController    = TextEditingController(text: s != null ? '${s.age}' : '');
    _courseController = TextEditingController(text: s?.course     ?? '');
    _emailController  = TextEditingController(text: s?.email      ?? '');
    _phoneController  = TextEditingController(text: s?.phone      ?? '');
    _selectedGender   = s?.gender ?? 'Male';
  }

  @override
  void dispose() {
    _rollController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _courseController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Email regex validator
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(email);
  }

  // Save: validate → insert/update → show feedback → pop
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final student = Student(
      id:         widget.student?.id,
      rollNumber: _rollController.text.trim(),
      fullName:   _nameController.text.trim(),
      age:        int.parse(_ageController.text.trim()),
      gender:     _selectedGender,
      course:     _courseController.text.trim(),
      email:      _emailController.text.trim(),
      phone:      _phoneController.text.trim(),
    );

    try {
      if (_isEditing) {
        final result = await _db.updateStudent(student);
        if (!mounted) return;

        if (result == -1) {
          _showError(
              'Roll number "${student.rollNumber}" is already used by another student.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Student updated successfully!'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context, student);
        }
      } else {
        final result = await _db.insertStudent(student);
        if (!mounted) return;

        if (result == -1) {
          _showError(
              'Roll number "${student.rollNumber}" already exists. Please use a different one.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Student added successfully!'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context, student);
        }
      }
    } catch (e) {
      if (mounted) _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(
          _isEditing ? 'Edit Student' : 'Add Student',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Section: Identity ─────────────────────────────────────────
                _SectionHeader(label: 'Identity'),
                const SizedBox(height: 12),

                _buildField(
                  controller: _rollController,
                  label: 'Roll / Student ID',
                  hint: 'e.g. CS2024001',
                  icon: Icons.badge_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Roll number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. Meghana Sharma',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // Age field (takes 1/3 width)
                    Expanded(
                      flex: 2,
                      child: _buildField(
                        controller: _ageController,
                        label: 'Age',
                        hint: '18',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          final age = int.tryParse(v.trim());
                          if (age == null || age < 1 || age > 99) {
                            return '1–99';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Gender dropdown (takes 2/3 width)
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.wc_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                        ),
                        items: _genders
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedGender = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ── Section: Academic ─────────────────────────────────────────
                _SectionHeader(label: 'Academic'),
                const SizedBox(height: 12),

                _buildField(
                  controller: _courseController,
                  label: 'Course / Department',
                  hint: 'e.g. Computer Science',
                  icon: Icons.school_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Course is required'
                      : null,
                ),

                const SizedBox(height: 22),

                // ── Section: Contact ──────────────────────────────────────────
                _SectionHeader(label: 'Contact'),
                const SizedBox(height: 12),

                _buildField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'e.g. meghana@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!_isValidEmail(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'e.g. 9876543210',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone is required';
                    }
                    if (v.trim().length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // ── Submit button ─────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_isEditing
                          ? Icons.save_outlined
                          : Icons.person_add_alt_1_rounded),
                  label:
                      Text(_isEditing ? 'Save Changes' : 'Register Student'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build a consistently styled TextFormField
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}

// ── Section header widget ─────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: theme.colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
