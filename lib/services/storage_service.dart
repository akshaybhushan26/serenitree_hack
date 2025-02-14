import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication.dart';
import '../models/mood_entry.dart';

class StorageService {
  static const String medicationsBox = 'medications';
  static const String interactionsBox = 'interactions';
  static const String chatHistoryBox = 'chatHistory';
  static const String prescriptionsBox = 'prescriptions';
  static const String moodEntriesBox = 'moodEntries';

  Future<void> initializeHive() async {
    try {
      await Hive.initFlutter();
      
      // Clear existing boxes due to model changes
      await Hive.deleteBoxFromDisk(medicationsBox);
      await Hive.deleteBoxFromDisk(moodEntriesBox);
      await Hive.deleteBoxFromDisk(interactionsBox);
      await Hive.deleteBoxFromDisk(chatHistoryBox);
      await Hive.deleteBoxFromDisk(prescriptionsBox);
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MedicationAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MoodEntryAdapter());
      }
      
      // Open all boxes
      await Future.wait([
        Hive.openBox<Medication>(medicationsBox),
        Hive.openBox<MoodEntry>(moodEntriesBox),
        Hive.openBox(interactionsBox),
        Hive.openBox(chatHistoryBox),
        Hive.openBox(prescriptionsBox),
      ]);
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
      rethrow;
    }
  }

  // Mood Entries
  Future<void> saveMoodEntry(MoodEntry entry) async {
    final box = await Hive.openBox<MoodEntry>(moodEntriesBox);
    try {
      // Create a new instance of MoodEntry to avoid storing the same instance
      final newEntry = MoodEntry(
        timestamp: entry.timestamp,
        moodLevel: entry.moodLevel,
        note: entry.note
      );
      await box.add(newEntry);
    } catch (e) {
      debugPrint('Error saving mood entry: $e');
      rethrow;
    }
  }

  Future<List<MoodEntry>> getAllMoodEntries() async {
    final box = await Hive.openBox<MoodEntry>(moodEntriesBox);
    return box.values.toList();
  }

  // Medications
  Future<void> saveMedication(Medication medication) async {
    final box = await Hive.openBox<Medication>(medicationsBox);
    await box.put(medication.name, medication);
  }

  Future<Medication?> getMedication(String name) async {
    final box = await Hive.openBox<Medication>(medicationsBox);
    return box.get(name);
  }

  Future<List<Medication>> getAllMedications() async {
    final box = await Hive.openBox<Medication>(medicationsBox);
    try {
      return box.values.toList();
    } catch (e) {
      debugPrint('Error getting medications: $e');
      await box.clear();
      return [];
    }
  }

  Future<void> deleteMedication(String name) async {
    final box = await Hive.openBox<Medication>(medicationsBox);
    await box.delete(name);
  }

  // Interactions
  Future<void> saveInteraction(String key, List<Map<String, dynamic>> interactions) async {
    final box = await Hive.openBox(interactionsBox);
    await box.put(key, interactions);
  }

  Future<List<Map<String, dynamic>>?> getInteraction(String key) async {
    final box = await Hive.openBox(interactionsBox);
    final data = box.get(key);
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  // Chat History
  Future<void> saveChatMessage(Map<String, dynamic> message) async {
    final box = await Hive.openBox(chatHistoryBox);
    try {
      final messages = box.get('messages') != null ? List<Map<String, dynamic>>.from(box.get('messages')) : [];
      messages.add(message);
      await box.put('messages', messages);
    } catch (e) {
      debugPrint('Error saving chat message: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>?> getChatHistory() async {
    final box = await Hive.openBox(chatHistoryBox);
    final data = box.get('messages');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(data);
  }

  // Prescriptions
  Future<void> savePrescription(String id, Map<String, dynamic> prescription) async {
    final box = await Hive.openBox(prescriptionsBox);
    await box.put(id, prescription);
  }

  Future<Map<String, dynamic>?> getPrescription(String id) async {
    final box = await Hive.openBox(prescriptionsBox);
    return box.get(id);
  }

  Future<List<Map<String, dynamic>>> getAllPrescriptions() async {
    final box = await Hive.openBox(prescriptionsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Clear Data
  Future<void> clearAllData() async {
    await Hive.deleteBoxFromDisk(medicationsBox);
    await Hive.deleteBoxFromDisk(moodEntriesBox);
    await Hive.deleteBoxFromDisk(interactionsBox);
    await Hive.deleteBoxFromDisk(chatHistoryBox);
    await Hive.deleteBoxFromDisk(prescriptionsBox);
    await initializeHive(); // Reinitialize after clearing
  }
}
