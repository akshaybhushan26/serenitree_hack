import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _apiKey = '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';

  Future<String> chat(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'mixtral-8x7b-32768',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a knowledgeable and friendly medical assistant specializing in medication information. Provide detailed, evidence-based information about medications while maintaining a conversational tone.\n\nWhen discussing medications, always include:\n1. Generic and brand names\n2. Primary uses and therapeutic class\n3. Standard dosage ranges and forms\n4. Common and serious side effects\n5. Drug interactions and contraindications\n6. Special precautions for specific populations\n7. Storage and handling guidelines\n\nIf the query is unclear or lacks context, ask clarifying questions. For complex medical situations, emphasize the importance of consulting healthcare providers. Stay within your scope as an information provider and avoid making specific medical recommendations.\n\nStructure your responses clearly with headers and bullet points when appropriate. Use plain language while maintaining medical accuracy. If information is limited or uncertain, clearly state this and suggest consulting authoritative sources.',
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']['message'] ?? 'Failed to get response from AI');
      }
    } catch (e) {
      print('Error in chat: $e');
      if (e.toString().contains('rate_limit')) {
        return 'I\'m currently experiencing high demand. Please try again in a moment.';
      } else if (e.toString().contains('invalid_api_key')) {
        return 'There\'s an authentication issue with the service. Please contact support.';
      } else if (e.toString().contains('context_length_exceeded')) {
        return 'Your query is too long. Please try asking a shorter, more specific question.';
      }
      return 'I apologize, but I\'m having trouble processing your request at the moment. Please try again.';
    }
  }

  Future<List<Map<String, String>>> analyzePrescription(String message) async {
    try {
      final prompt = '''
      Analyze the following text for medication information and extract details about:
      - Medication names
      - Dosage information
      - Frequency of intake
      - Timing of medication

      Text: $message
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'mixtral-8x7b-32768',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a medical assistant that helps analyze medication information. Extract and structure medication details from user input.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.5,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseAIResponse(content);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']['message'] ?? 'Failed to analyze medication information');
      }
    } catch (e) {
      print('Error analyzing prescription: $e');
      return [];
    }
  }

  List<Map<String, String>> _parseAIResponse(String content) {
    try {
      final List<Map<String, String>> medications = [];
      final lines = content.split('\n');
      Map<String, String> currentMed = {};

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        if (line.contains('name:') || line.contains('Name:')) {
          if (currentMed.isNotEmpty) {
            medications.add(Map.from(currentMed));
            currentMed.clear();
          }
          currentMed['name'] = line.split(':')[1].trim();
        } else if (line.contains('dosage:') || line.contains('Dosage:')) {
          currentMed['dosage'] = line.split(':')[1].trim();
        } else if (line.contains('frequency:') || line.contains('Frequency:')) {
          currentMed['frequency'] = line.split(':')[1].trim();
        } else if (line.contains('time:') || line.contains('Time:')) {
          currentMed['time'] = line.split(':')[1].trim();
        }
      }

      if (currentMed.isNotEmpty) {
        medications.add(Map.from(currentMed));
      }

      return medications;
    } catch (e) {
      print('Error parsing AI response: $e');
      return [];
    }
  }

  Future<String> getGeneralMedicationInfo(String medicationName) async {
    try {
      final prompt = '''
      Provide general information about $medicationName including:
      - Common uses
      - Typical dosage ranges
      - Common side effects
      - Important precautions
      Please format the response in a clear, easy-to-read manner.
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'mixtral-8x7b-32768',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a medical assistant providing information about medications.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.5,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']['message'] ?? 'Failed to get medication information');
      }
    } catch (e) {
      print('Error getting medication info: $e');
      return 'Sorry, I couldn\'t retrieve information about this medication at the moment.';
    }
  }
}