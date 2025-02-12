class MoodEntry {
  final int mood;
  final String note;
  final DateTime timestamp;

  MoodEntry({
    required this.mood,
    required this.note,
    required this.timestamp,
  });

  String get moodEmoji {
    switch (mood) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      mood: json['mood'] as int,
      note: json['note'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
