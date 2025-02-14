import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with actual API key

  Future<List<Map<String, String>>> analyzePrescription(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''
You are a medical prescription analyzer. Extract medication information from the provided text and return it in the following JSON format:
{
  "medications": [
    {
      "name": "medication name",
      "dosage": "dosage with units",
      "frequency": "frequency of intake",
      "time": "time of intake (if specified)"
    }
  ]
}
'''
            },
            {
              'role': 'user',
              'content': text
            }
          ],
          'temperature': 0.3,
          'max_tokens': 500
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final aiAnalysis = jsonResponse['choices'][0]['message']['content'];
        
        try {
          final analysisJson = jsonDecode(aiAnalysis);
          return (analysisJson['medications'] as List)
              .map((med) => {
                    'name': med['name'] as String,
                    'dosage': med['dosage'] as String,
                    'frequency': med['frequency'] as String,
                    'time': med['time'] as String,
                  })
              .toList();
        } catch (e) {
          print('Error parsing AI response: $e');
          return [];
        }
      } else {
        throw Exception('Failed to analyze with AI: ${response.statusCode}');
      }
    } catch (e) {
      print('AI Analysis Error: $e');
      return [];
    }
  }

  Future<List<String>> analyzeDrugInteractions(List<String> medications) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a pharmaceutical expert. Analyze the potential interactions between the provided medications and return a list of potential interactions or concerns.'
            },
            {
              'role': 'user',
              'content': 'Analyze interactions between: ${medications.join(", ")}'
            }
          ],
          'temperature': 0.3,
          'max_tokens': 500
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final analysis = jsonResponse['choices'][0]['message']['content'];
        return analysis.split('\n').where((line) => line.trim().isNotEmpty).toList();
      } else {
        throw Exception('Failed to analyze drug interactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Drug Interaction Analysis Error: $e');
      return [];
    }
  }
}