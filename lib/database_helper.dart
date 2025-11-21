import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/health_record.dart';

class HealthDatabase {
  HealthDatabase._privateConstructor();
  static final HealthDatabase instance = HealthDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'health.db');

    // If DB does not exist, copy from assets
    final exists = await databaseExists(path);

    if (!exists) {
      // Ensure parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy database from assets
      ByteData data = await rootBundle.load('assets/health.db');
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    }

    // Open the database
    return await openDatabase(path, version: 1);
  }

  // ------------------ CRUD OPERATIONS ------------------

  Future<List<HealthRecord>> fetchRecords() async {
    final db = await database;
    final result = await db.query('health_records', orderBy: 'date DESC');
    return result.map((e) => HealthRecord.fromMap(e)).toList();
  }

  Future<int> insertRecord(HealthRecord record) async {
    final db = await database;
    return db.insert('health_records', record.toMap());
  }

  Future<int> updateRecord(HealthRecord record) async {
    final db = await database;
    return db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllRecords() async {
    final db = await database;
    await db.delete('health_records');
  }

  Future<HealthRecord?> getRecordById(int id) async {
    final db = await database;
    final result = await db.query('health_records', where: 'id = ?', whereArgs: [id]);

    if (result.isEmpty) return null;
    return HealthRecord.fromMap(result.first);
  }

  Future<Map<String, int>> summaryForDate(DateTime date) async {
    final db = await database;
    final formatted = date.toIso8601String().substring(0, 10);

    final result = await db.rawQuery('''
      SELECT 
        SUM(steps) AS steps,
        SUM(calories) AS calories,
        SUM(water) AS water
      FROM health_records
      WHERE date = ?
    ''', [formatted]);

    final row = result.first;
    return {
      'steps': row['steps'] != null ? (row['steps'] as int) : 0,
      'calories': row['calories'] != null ? (row['calories'] as int) : 0,
      'water': row['water'] != null ? (row['water'] as int) : 0,
    };
  }

  Future<void> seedDummyData() async {
    final db = await database;
    await db.insert('health_records', {
      'date': '2024-10-21',
      'steps': 5600,
      'calories': 350,
      'water': 900,
    });
  }
}
