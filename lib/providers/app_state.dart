import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Medication> _medications = [];
  List<MoodEntry> _moodEntries = [];
  final List<Map<String, dynamic>> _interactions = [];
  int _meditationMinutes = 0;
  int _completedExercises = 0;

  AppState() {
    _initializeState();
  }

  Future<void> _initializeState() async {
    await _loadMedications();
    await _loadMoodEntries();
  }

  Future<void> _loadMedications() async {
    try {
      _medications = await _storage.getAllMedications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading medications: $e');
    }
  }

  Future<void> _loadMoodEntries() async {
    try {
      _moodEntries = await _storage.getAllMoodEntries();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading mood entries: $e');
    }
  }

  // Medications
  List<Medication> get medications => List.unmodifiable(_medications);

  Future<void> addMedication({
    required String name,
    required String dosage,
    required String frequency,
    required TimeOfDay time,
  }) async {
    final medication = Medication(
      name: name,
      dosage: dosage,
      frequency: frequency,
      time: time,
    );
    await _storage.saveMedication(medication);
    await _loadMedications();
  }

  Future<void> updateMedication(Medication medication) async {
    await _storage.saveMedication(medication);
    await _loadMedications();
  }

  Future<void> removeMedication(String name) async {
    await _storage.deleteMedication(name);
    await _loadMedications();
  }

  TimeOfDay? getNextDose(String medicationName) {
    try {
      final medication = _medications.firstWhere(
        (med) => med.name == medicationName,
      );
      return medication.time;
    } catch (e) {
      return null;
    }
  }

  // Mood Entries
  List<MoodEntry> get moodEntries => List.unmodifiable(_moodEntries);

  Future<void> addMoodEntry(MoodEntry entry) async {
    await _storage.saveMoodEntry(entry);
    await _loadMoodEntries();
  }

  List<MoodEntry> getMoodTrend([int days = 7]) {
    final now = DateTime.now();
    return _moodEntries
        .where((entry) =>
            entry.timestamp.isAfter(now.subtract(Duration(days: days))))
        .toList();
  }

  // Interactions
  List<Map<String, dynamic>> get interactions => List.unmodifiable(_interactions);

  void addInteraction(Map<String, dynamic> interaction) {
    _interactions.add(interaction);
    notifyListeners();
  }

  void clearInteractions() {
    _interactions.clear();
    notifyListeners();
  }

  // Meditation
  int get meditationMinutes => _meditationMinutes;

  void addMeditationMinutes(int minutes) {
    _meditationMinutes += minutes;
    notifyListeners();
  }

  // Therapy Exercises
  int get completedExercises => _completedExercises;

  void incrementCompletedExercises() {
    _completedExercises++;
    notifyListeners();
  }
}
