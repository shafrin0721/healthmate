import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/health_record.dart';

class HealthDatabase {
  static final HealthDatabase instance = HealthDatabase._init();
  static Database? _database;

  HealthDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    final dbExists = await File(path).exists();

    if (!dbExists) {
      // Copy database from assets
      ByteData data = await rootBundle.load('assets/$fileName');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future _createTables(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS health_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      steps INTEGER NOT NULL,
      calories INTEGER NOT NULL,
      water INTEGER NOT NULL
    )
    ''');
  }

  // CRUD OPERATIONS

  Future<int> insertRecord(HealthRecord record) async {
    final db = await instance.database;
    return await db.insert('health_records', record.toMap());
  }

  Future<List<HealthRecord>> fetchRecords() async {
    final db = await instance.database;
    final result = await db.query('health_records', orderBy: 'date DESC');
    return result.map((row) => HealthRecord.fromMap(row)).toList();
  }

  Future<int> updateRecord(HealthRecord record) async {
    final db = await instance.database;
    return await db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllRecords() async {
    final db = await instance.database;
    return await db.delete('health_records');
  }

  Future<HealthRecord?> getRecordById(int id) async {
    final db = await instance.database;
    final result = await db.query('health_records', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return HealthRecord.fromMap(result.first);
    }
    return null;
  }

  Future<Map<String, int>> summaryForDate(DateTime date) async {
    final db = await instance.database;
    final todayString = DateTime(date.year, date.month, date.day).toIso8601String();

    final result = await db.rawQuery('''
      SELECT 
        SUM(steps) as steps,
        SUM(calories) as calories,
        SUM(water) as water
      FROM health_records
      WHERE date LIKE '${todayString.substring(0, 10)}%'
    ''');

    final row = result.first;

    return {
      'steps': row['steps'] as int? ?? 0,
      'calories': row['calories'] as int? ?? 0,
      'water': row['water'] as int? ?? 0,
    };
  }

  Future<void> seedDummyData() async {
    final db = await instance.database;

    await db.insert('health_records', {
      'date': DateTime.now().toIso8601String(),
      'steps': 5000,
      'calories': 1200,
      'water': 1500
    });

    await db.insert('health_records', {
      'date': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      'steps': 7000,
      'calories': 1400,
      'water': 1800
    });
  }
}
