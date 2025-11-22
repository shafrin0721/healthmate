import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_record.dart';
import 'health_database_stub.dart';

class HealthDatabase extends HealthDatabaseBase {
  HealthDatabase._internal();
  static final HealthDatabase instance = HealthDatabase._internal();
  static const String _key = 'health_records';
  static int _nextId = 1;

  Future<List<HealthRecord>> _getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      final idString = prefs.getString('_nextId');
      if (idString != null) {
        _nextId = int.parse(idString);
      }
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    final idString = prefs.getString('_nextId');
    if (idString != null) {
      _nextId = int.parse(idString);
    }
    return jsonList
        .map((json) => HealthRecord.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllRecords(List<HealthRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = records.map((r) => r.toMap()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
    await prefs.setString('_nextId', _nextId.toString());
  }

  @override
  Future<HealthRecord> insertRecord(HealthRecord record) async {
    final records = await _getAllRecords();
    final newRecord = record.copyWith(id: _nextId++);
    records.add(newRecord);
    await _saveAllRecords(records);
    return newRecord;
  }

  @override
  Future<List<HealthRecord>> fetchRecords({String? dateFilter}) async {
    var records = await _getAllRecords();
    records.sort((a, b) => b.date.compareTo(a.date));

    if (dateFilter != null && dateFilter.isNotEmpty) {
      final filter = dateFilter.toLowerCase();
      records = records.where((record) {
        return record.formattedDate.toLowerCase().contains(filter);
      }).toList();
    }

    return records;
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    if (record.id == null) return 0;
    final records = await _getAllRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index == -1) return 0;
    records[index] = record;
    await _saveAllRecords(records);
    return 1;
  }

  @override
  Future<int> deleteRecord(int id) async {
    final records = await _getAllRecords();
    final initialLength = records.length;
    records.removeWhere((r) => r.id == id);
    await _saveAllRecords(records);
    return initialLength - records.length;
  }

  @override
  Future<void> deleteAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove('_nextId');
    _nextId = 1;
  }

  @override
  Future<HealthRecord?> getRecordById(int id) async {
    final records = await _getAllRecords();
    try {
      return records.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> totalWaterForDate(DateTime date) async {
    final records = await _getAllRecords();
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    int total = 0;
    for (final record in records) {
      if (record.date
              .isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
          record.date.isBefore(dayEnd)) {
        total += record.water;
      }
    }
    return total;
  }

  @override
  Future<Map<String, int>> summaryForDate(DateTime date) async {
    final records = await _getAllRecords();
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    int steps = 0;
    int calories = 0;
    int water = 0;

    for (final record in records) {
      if (record.date
              .isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
          record.date.isBefore(dayEnd)) {
        steps += record.steps;
        calories += record.calories;
        water += record.water;
      }
    }

    return {
      'steps': steps,
      'calories': calories,
      'water': water,
    };
  }

  @override
  Future<void> seedDummyData() async {
    final records = await _getAllRecords();
    if (records.isNotEmpty) return;

    final now = DateTime.now();
    final samples = List.generate(5, (index) {
      final date = now.subtract(Duration(days: index));
      return HealthRecord(
        date: date,
        steps: 7500 + (index * 400),
        calories: 1900 + (index * 150),
        water: 1800 + (index * 120),
      ).copyWith(id: _nextId + index);
    });
    _nextId += samples.length;
    await _saveAllRecords(samples);
  }
}
