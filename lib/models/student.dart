// lib/models/student.dart
// Defines the Student data model and provides SQLite serialization helpers.

class Student {
  final int? id;           // Auto-increment primary key (null when creating)
  final String rollNumber; // Unique roll / student ID
  final String fullName;
  final int age;
  final String gender;     // "Male", "Female", "Other"
  final String course;
  final String email;
  final String phone;

  const Student({
    this.id,
    required this.rollNumber,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.course,
    required this.email,
    required this.phone,
  });

  // Convert a Student instance → Map for inserting/updating in SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'roll_number': rollNumber,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'course': course,
      'email': email,
      'phone': phone,
    };
  }

  // Build a Student from a SQLite row Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      rollNumber: map['roll_number'] as String,
      fullName: map['full_name'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      course: map['course'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
    );
  }

  // Returns an initials string (max 2 chars) used for the avatar placeholder
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  // Returns a copy of this student with some fields replaced
  Student copyWith({
    int? id,
    String? rollNumber,
    String? fullName,
    int? age,
    String? gender,
    String? course,
    String? email,
    String? phone,
  }) {
    return Student(
      id: id ?? this.id,
      rollNumber: rollNumber ?? this.rollNumber,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      course: course ?? this.course,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() =>
      'Student(id: $id, rollNumber: $rollNumber, fullName: $fullName)';
}
