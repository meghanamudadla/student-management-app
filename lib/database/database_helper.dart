// lib/database/database_helper.dart
// Singleton class that manages all SQLite database operations.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';

class DatabaseHelper {
  // ── Singleton setup ────────────────────────────────────────────────────────
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  // ── Table / column constants ───────────────────────────────────────────────
  static const String _tableName    = 'students';
  static const String colId         = 'id';
  static const String colRollNumber = 'roll_number';
  static const String colFullName   = 'full_name';
  static const String colAge        = 'age';
  static const String colGender     = 'gender';
  static const String colCourse     = 'course';
  static const String colEmail      = 'email';
  static const String colPhone      = 'phone';

  // ── Open / initialise database ─────────────────────────────────────────────
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'students.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $colId         INTEGER PRIMARY KEY AUTOINCREMENT,
        $colRollNumber TEXT    NOT NULL UNIQUE,
        $colFullName   TEXT    NOT NULL,
        $colAge        INTEGER NOT NULL,
        $colGender     TEXT    NOT NULL,
        $colCourse     TEXT    NOT NULL,
        $colEmail      TEXT    NOT NULL,
        $colPhone      TEXT    NOT NULL
      )
    ''');
  }

  // ── CRUD operations ────────────────────────────────────────────────────────

  /// Insert a student. Returns the new row id, or -1 if roll number already exists.
  Future<int> insertStudent(Student student) async {
    final db = await database;
    // Check for duplicate roll number first
    final existing = await db.query(
      _tableName,
      where: '$colRollNumber = ?',
      whereArgs: [student.rollNumber],
    );
    if (existing.isNotEmpty) return -1; // Duplicate

    return db.insert(
      _tableName,
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  /// Returns all students ordered by name.
  Future<List<Student>> getAllStudents() async {
    final db   = await database;
    final rows = await db.query(_tableName, orderBy: colFullName);
    return rows.map(Student.fromMap).toList();
  }

  /// Returns students where name, roll number, or course matches [query].
  Future<List<Student>> searchStudents(String query) async {
    final db   = await database;
    final like = '%$query%';
    final rows = await db.query(
      _tableName,
      where: '$colFullName LIKE ? OR $colRollNumber LIKE ? OR $colCourse LIKE ?',
      whereArgs: [like, like, like],
      orderBy: colFullName,
    );
    return rows.map(Student.fromMap).toList();
  }

  /// Update an existing student. Returns number of rows affected.
  Future<int> updateStudent(Student student) async {
    final db = await database;

    // Check if another student already has the same roll number (excluding self)
    final existing = await db.query(
      _tableName,
      where: '$colRollNumber = ? AND $colId != ?',
      whereArgs: [student.rollNumber, student.id],
    );
    if (existing.isNotEmpty) return -1; // Duplicate roll on another record

    return db.update(
      _tableName,
      student.toMap(),
      where: '$colId = ?',
      whereArgs: [student.id],
    );
  }

  /// Delete a student by id. Returns number of rows affected.
  Future<int> deleteStudent(int id) async {
    final db = await database;
    return db.delete(
      _tableName,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// Returns total number of student records.
  Future<int> getTotalCount() async {
    final db     = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return (result.first['count'] as int?) ?? 0;
  }
}
