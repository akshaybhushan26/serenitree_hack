import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 0)
class Medication extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String dosage;

  @HiveField(2)
  final String frequency;

  @HiveField(3)
  final int hour;

  @HiveField(4)
  final int minute;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required TimeOfDay time,
  })  : hour = time.hour,
        minute = time.minute;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String formatTime(BuildContext? context) {
    if (context != null) {
      return time.format(context);
    }
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'hour': hour,
      'minute': minute,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      time: TimeOfDay(
        hour: map['hour'] as int,
        minute: map['minute'] as int,
      ),
    );
  }

  @override
  String toString() {
    final timeStr = formatTime(null);
    return 'Medication(name: $name, dosage: $dosage, frequency: $frequency, time: $timeStr)';
  }
}
