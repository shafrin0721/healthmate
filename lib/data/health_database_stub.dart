import '../models/health_record.dart';

// Stub file for conditional imports
abstract class HealthDatabaseBase {
  Future<HealthRecord> insertRecord(HealthRecord record);
  Future<List<HealthRecord>> fetchRecords({String? dateFilter});
  Future<int> updateRecord(HealthRecord record);
  Future<int> deleteRecord(int id);
  Future<void> deleteAllRecords();
  Future<HealthRecord?> getRecordById(int id);
  Future<int> totalWaterForDate(DateTime date);
  Future<Map<String, int>> summaryForDate(DateTime date);
  Future<void> seedDummyData();
}
