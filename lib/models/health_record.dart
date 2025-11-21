import 'package:intl/intl.dart';

class HealthRecord {
  final int? id;
  final DateTime date;
  final int steps;
  final int calories;
  final int water;

  const HealthRecord({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.water,
  });

  HealthRecord copyWith({
    int? id,
    DateTime? date,
    int? steps,
    int? calories,
    int? water,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      water: water ?? this.water,
    );
  }

  String get formattedDate => DateFormat('MMMM d, yyyy').format(date);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'steps': steps,
      'calories': calories,
      'water': water,
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      steps: map['steps'] as int? ?? 0,
      calories: map['calories'] as int? ?? 0,
      water: map['water'] as int? ?? map['waterMl'] as int? ?? 0,
    );
  }
}

