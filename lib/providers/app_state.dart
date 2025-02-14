import 'package:flutter/material.dart';
import 'package:serenitree_hack/services/storage_service.dart';

class AppState extends ChangeNotifier {
  // Theme colors
  static const backgroundColor = Color(0xFFF5F5F5);
  static const gradientEnd = Color(0xFFE0E0E0);

  // Theme data
  ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
      );

  // Medications
  final List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> get medications => _medications;
  final StorageService _storageService = StorageService();

  AppState() {
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await _storageService.initializeHive();
    await _loadMedications();
  }

  Future<void> _loadMedications() async {
    final meds = await _storageService.getAllMedications();
    _medications.addAll(meds);
    notifyListeners();
  }

  Future<void> addMedication({required String name, required String dosage, required String frequency, required TimeOfDay time}) async {
    final medication = {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': '${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}',
    };
    _medications.add(medication);
    await _storageService.saveMedication(name, medication);
    notifyListeners();
  }

  Future<void> removeMedication(int index) async {
    final medication = _medications[index];
    _medications.removeAt(index);
    await _storageService.clearAllData(); // Since Hive doesn't support individual deletions easily
    for (var med in _medications) {
      await _storageService.saveMedication(med['name'], med);
    }
    notifyListeners();
  }

  Future<void> updateMedication(int index, Map<String, dynamic> medication) async {
    _medications[index] = medication;
    await _storageService.saveMedication(medication['name'], medication);
    notifyListeners();
  }

  // Therapy progress
  int _completedExercises = 0;
  int get completedExercises => _completedExercises;

  void incrementCompletedExercises() {
    _completedExercises++;
    notifyListeners();
  }

  // Meditation progress
  int _meditationMinutes = 0;
  int get meditationMinutes => _meditationMinutes;

  void addMeditationMinutes(int minutes) {
    _meditationMinutes += minutes;
    notifyListeners();
  }

  // Drug interactions
  final List<Map<String, dynamic>> _interactions = [];
  List<Map<String, dynamic>> get interactions => _interactions;

  void addInteraction(Map<String, dynamic> interaction) {
    _interactions.add(interaction);
    notifyListeners();
  }

  void clearInteractions() {
    _interactions.clear();
    notifyListeners();
  }

  // Mood tracking
  final List<Map<String, dynamic>> _moodEntries = [];
  List<Map<String, dynamic>> get moodEntries => _moodEntries;

  void addMoodEntry(Map<String, dynamic> entry) {
    _moodEntries.add(entry);
    notifyListeners();
  }

  // Get mood trend for the last 7 days
  List<Map<String, dynamic>> getMoodTrend() {
    final now = DateTime.now();
    return _moodEntries
        .where((entry) =>
            now.difference(entry['timestamp'] as DateTime).inDays <= 7)
        .toList();
  }

  // Get next medication dose
  Map<String, dynamic>? getNextDose() {
    if (_medications.isEmpty) return null;

    final now = TimeOfDay.now();
    return _medications.firstWhere(
      (med) {
        final doseTime = med['time'] as String;
        final parts = doseTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1].split(' ')[0]);
        final period = parts[1].split(' ')[1];
        
        final medTime = TimeOfDay(
          hour: period == 'PM' && hour != 12
              ? hour + 12
              : period == 'AM' && hour == 12
                  ? 0
                  : hour,
          minute: minute,
        );

        return medTime.hour > now.hour ||
            (medTime.hour == now.hour && medTime.minute > now.minute);
      },
      orElse: () => _medications.first,
    );
  }
}
