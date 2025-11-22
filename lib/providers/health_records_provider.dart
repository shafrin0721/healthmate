import 'package:flutter/material.dart';

import '../data/health_database.dart';
import '../models/health_record.dart';

class HealthRecordsProvider extends ChangeNotifier {
  HealthRecordsProvider() {
    loadRecords();
  }

  final HealthDatabase _database = HealthDatabase.instance;

  List<HealthRecord> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, int> _todaySummary = const {
    'steps': 0,
    'calories': 0,
    'water': 0,
  };

  List<HealthRecord> get records {
    if (_searchQuery.isEmpty) return List.unmodifiable(_records);
    final query = _searchQuery.toLowerCase();
    return _records
        .where(
          (record) => record.formattedDate.toLowerCase().contains(query),
        )
        .toList();
  }

  bool get isLoading => _isLoading;

  Map<String, int> get todaySummary => _todaySummary;
  int get totalWaterToday => _todaySummary['water'] ?? 0;

  String get searchQuery => _searchQuery;

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();
    _records = await _database.fetchRecords();
    if (_records.isEmpty) {
      await _database.seedDummyData();
      _records = await _database.fetchRecords();
    }
    await _loadSummary();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSummary() async {
    _todaySummary = await _database.summaryForDate(DateTime.now());
  }

  Future<void> addRecord(HealthRecord record) async {
    await _database.insertRecord(record);
    await loadRecords();
  }

  Future<void> updateRecord(HealthRecord record) async {
    if (record.id == null) return;
    await _database.updateRecord(record);
    await loadRecords();
  }

  Future<void> deleteRecord(int id) async {
    await _database.deleteRecord(id);
    await loadRecords();
  }

  Future<void> deleteAllRecords() async {
    await _database.deleteAllRecords();
    await loadRecords();
  }

  Future<HealthRecord?> getRecord(int id) {
    return _database.getRecordById(id);
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
