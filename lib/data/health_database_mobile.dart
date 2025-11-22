import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/health_record.dart';
import 'health_database_stub.dart';

class HealthDatabase extends HealthDatabaseBase {
  HealthDatabase._internal();
  static final HealthDatabase instance = HealthDatabase._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'healthmate.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE health_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            steps INTEGER NOT NULL,
            calories INTEGER NOT NULL,
            water INTEGER NOT NULL
          )
        ''');
        await _seedDummyData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE health_records RENAME TO health_records_old');
          await db.execute('''
            CREATE TABLE health_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              steps INTEGER NOT NULL,
              calories INTEGER NOT NULL,
              water INTEGER NOT NULL
            )
          ''');
          final oldRecords = await db.query('health_records_old');
          for (final record in oldRecords) {
            await db.insert('health_records', {
              'id': record['id'],
              'date': record['date'],
              'steps': record['steps'],
              'calories': record['calories'],
              'water': record['waterMl'] ?? record['water'] ?? 0,
            });
          }
          await db.execute('DROP TABLE health_records_old');
        }
      },
    );

    return _database!;
  }

  @override
  Future<HealthRecord> insertRecord(HealthRecord record) async {
    final db = await database;
    final id = await db.insert(
      'health_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return record.copyWith(id: id);
  }

  @override
  Future<List<HealthRecord>> fetchRecords({String? dateFilter}) async {
    final db = await database;
    String? whereClause;
    List<Object?>? whereArgs;
    if (dateFilter != null && dateFilter.isNotEmpty) {
      whereClause = 'date LIKE ?';
      whereArgs = ['%$dateFilter%'];
    }
    final maps = await db.query(
      'health_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map((map) => HealthRecord.fromMap(map)).toList();
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    if (record.id == null) return 0;
    final db = await database;
    return db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<HealthRecord?> getRecordById(int id) async {
    final db = await database;
    final maps = await db.query(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HealthRecord.fromMap(maps.first);
  }

  @override
  Future<int> totalWaterForDate(DateTime date) async {
    final db = await database;
    final isoDate = DateTime(date.year, date.month, date.day).toIso8601String();
    final result = await db.rawQuery(
      'SELECT SUM(water) as total FROM health_records WHERE date LIKE ?',
      ['${isoDate.substring(0, 10)}%'],
    );
    if (result.isEmpty) return 0;
    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<Map<String, int>> summaryForDate(DateTime date) async {
    final db = await database;
    final dayStart =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT 
        SUM(steps) as steps,
        SUM(calories) as calories,
        SUM(water) as water
      FROM health_records
      WHERE date LIKE ?
      ''',
      ['${dayStart.substring(0, 10)}%'],
    );
    final row = result.first;
    return {
      'steps': (row['steps'] as int?) ?? 0,
      'calories': (row['calories'] as int?) ?? 0,
      'water': (row['water'] as int?) ?? 0,
    };
  }

  @override
  Future<void> deleteAllRecords() async {
    final db = await database;
    await db.delete('health_records');
  }

  @override
  Future<void> seedDummyData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM health_records'),
    );
    if (count != null && count > 0) return;
    await _seedDummyData(db);
  }

  Future<void> _seedDummyData(Database db) async {
    final now = DateTime.now();
    final List<HealthRecord> samples = List.generate(5, (index) {
      final date = now.subtract(Duration(days: index));
      return HealthRecord(
        date: date,
        steps: 8000 + (index * 500),
        calories: 2000 + (index * 120),
        water: 2000 + (index * 150),
      );
    });

    for (final record in samples) {
      await db.insert('health_records', record.toMap());
    }
  }
}
