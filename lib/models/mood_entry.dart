import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 1)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final int moodLevel;

  @HiveField(2)
  final String? note;

  MoodEntry({
    required this.timestamp,
    required this.moodLevel,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'moodLevel': moodLevel,
      'note': note,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      timestamp: map['timestamp'] as DateTime,
      moodLevel: map['moodLevel'] as int,
      note: map['note'] as String?,
    );
  }
}
