import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class StorageService {
  static const String medicationsBox = 'medications';
  static const String interactionsBox = 'interactions';
  static const String chatHistoryBox = 'chatHistory';
  static const String prescriptionsBox = 'prescriptions';

  Future<void> initializeHive() async {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    await Hive.openBox(medicationsBox);
    await Hive.openBox(interactionsBox);
    await Hive.openBox(chatHistoryBox);
    await Hive.openBox(prescriptionsBox);
  }

  // Medications
  Future<void> saveMedication(String id, Map<String, dynamic> medication) async {
    final box = await Hive.openBox(medicationsBox);
    await box.put(id, medication);
  }

  Future<Map<String, dynamic>?> getMedication(String id) async {
    final box = await Hive.openBox(medicationsBox);
    return box.get(id);
  }

  Future<List<Map<String, dynamic>>> getAllMedications() async {
    final box = await Hive.openBox(medicationsBox);
    final values = box.values.toList();
    return values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Interactions
  Future<void> saveInteraction(String key, List<Map<String, dynamic>> interactions) async {
    final box = await Hive.openBox(interactionsBox);
    await box.put(key, interactions);
  }

  Future<List<Map<String, dynamic>>?> getInteraction(String key) async {
    final box = await Hive.openBox(interactionsBox);
    final data = box.get(key);
    if (data != null) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  // Chat History
  Future<void> saveChatMessage(Map<String, dynamic> message) async {
    final box = await Hive.openBox(chatHistoryBox);
    await box.add(message);
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final box = await Hive.openBox(chatHistoryBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
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
    await Hive.deleteBoxFromDisk(interactionsBox);
    await Hive.deleteBoxFromDisk(chatHistoryBox);
    await Hive.deleteBoxFromDisk(prescriptionsBox);
  }
}