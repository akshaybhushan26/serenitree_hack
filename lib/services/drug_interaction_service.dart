import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DrugInteractionService {
  final String _baseUrl = 'https://api.fda.gov/drug';
  final _rateLimiter = <String, DateTime>{};
  final _cacheDuration = const Duration(minutes: 5);
  final _cache = <String, dynamic>{};

  String _extractFirstValue(dynamic field) {
    if (field is List && field.isNotEmpty) {
      return field[0] as String;
    }
    return 'N/A';
  }

  String _extractAndTruncateText(dynamic field) {
    if (field is List && field.isNotEmpty) {
      final text = field[0] as String;
      return text.length > 200 ? '${text.substring(0, 200)}...' : text;
    }
    return 'N/A';
  }

  String _cleanInteractionText(String text) {
    // Remove HTML tags if present
    var cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove multiple spaces and newlines
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Trim to reasonable length while keeping complete sentences
    if (cleaned.length > 300) {
      final sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
      cleaned = '';
      for (var sentence in sentences) {
        if ((cleaned + sentence).length > 300) break;
        cleaned += sentence + ' ';
      }
      cleaned = cleaned.trim();
    }

    return cleaned;
  }

  String _determineSeverity(String text) {
    final lowercaseText = text.toLowerCase();

    // Check for severe interaction indicators
    if (lowercaseText.contains('severe') ||
        lowercaseText.contains('dangerous') ||
        lowercaseText.contains('fatal') ||
        lowercaseText.contains('life-threatening') ||
        lowercaseText.contains('contraindicated') ||
        lowercaseText.contains('avoid') ||
        lowercaseText.contains('serious')) {
      return 'high';
    }

    // Check for moderate interaction indicators
    if (lowercaseText.contains('moderate') ||
        lowercaseText.contains('significant') ||
        lowercaseText.contains('monitor') ||
        lowercaseText.contains('adjust') ||
        lowercaseText.contains('may increase') ||
        lowercaseText.contains('may decrease')) {
      return 'medium';
    }

    // Default to low severity
    return 'low';
  }

  String getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return '#FF5252';
      case 'medium':
        return '#FFA726';
      case 'low':
        return '#4CAF50';
      default:
        return '#9E9E9E';
    }
  }

  Future<void> _throttleRequest(String key) async {
    final lastRequest = _rateLimiter[key];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      if (timeSinceLastRequest < const Duration(milliseconds: 100)) {
        await Future.delayed(
            const Duration(milliseconds: 100) - timeSinceLastRequest);
      }
    }
    _rateLimiter[key] = DateTime.now();
  }

  dynamic _getCachedData(String key) {
    final cachedData = _cache[key];
    if (cachedData != null) {
      final timestamp = cachedData['timestamp'] as DateTime;
      if (DateTime.now().difference(timestamp) < _cacheDuration) {
        return cachedData['data'];
      }
      _cache.remove(key);
    }
    return null;
  }

  void _cacheData(String key, dynamic data) {
    _cache[key] = {
      'data': data,
      'timestamp': DateTime.now(),
    };
  }

  Future<List<String>> searchDrugs(String query) async {
  if (query.isEmpty || query.length < 3) return [];
  
  await _throttleRequest('search');
  final cacheKey = 'search_$query';
  final cachedResults = _getCachedData(cacheKey);
  
  if (cachedResults != null) {
    return List<String>.from(cachedResults);
  }

  try {
    // Create a more lenient search query
    final searchQuery = Uri.encodeComponent(
      'openfda.brand_name:"${query.trim()}"+' +
      'openfda.brand_name:"${query.trim()}*"+' +
      'openfda.generic_name:"${query.trim()}"+' +
      'openfda.generic_name:"${query.trim()}*"'
    );

    final url = Uri.parse('$_baseUrl/label.json?search=$searchQuery&limit=100');
    print('Search URL: $url'); // Debug print

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!data.containsKey('results')) {
        throw Exception('Invalid API response format');
      }

      final results = data['results'] as List<dynamic>;
      final uniqueDrugs = <String>{};

      for (final result in results) {
        if (result is Map<String, dynamic> && 
            result['openfda'] is Map<String, dynamic>) {
          final openfda = result['openfda'] as Map<String, dynamic>;
          
          // Process brand names
          if (openfda['brand_name'] is List) {
            for (final name in openfda['brand_name']) {
              if (name is String) {
                uniqueDrugs.add(name);
              }
            }
          }
          
          // Process generic names
          if (openfda['generic_name'] is List) {
            for (final name in openfda['generic_name']) {
              if (name is String) {
                uniqueDrugs.add(name);
              }
            }
          }
        }
      }

      // Filter results based on query
      final filteredDrugs = uniqueDrugs
          .where((drug) => drug.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      _cacheData(cacheKey, filteredDrugs);
      
      print('Found ${filteredDrugs.length} results'); // Debug print
      return filteredDrugs;

    } else {
      print('API Error: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print
      if (response.statusCode == 404) {
        return [];
      }
      throw Exception('Failed to search drugs: ${response.statusCode}');
    }
  } catch (e) {
    print('Error searching drugs: $e');
    return [];
  }
}
  Future<List<Map<String, dynamic>>> checkInteractions(
      List<String> drugs) async {
    final interactions = <Map<String, dynamic>>[];

    try {
      for (var i = 0; i < drugs.length; i++) {
        for (var j = i + 1; j < drugs.length; j++) {
          final drug1 = drugs[i];
          final drug2 = drugs[j];

          await _throttleRequest('interaction');

          final cacheKey = 'interaction_${drug1}_${drug2}';
          final cachedInteraction = _getCachedData(cacheKey);
          if (cachedInteraction != null) {
            if (cachedInteraction is List) {
              interactions
                  .addAll(List<Map<String, dynamic>>.from(cachedInteraction));
            }
            continue;
          }

          final response1 = await http.get(
            Uri.parse('$_baseUrl/label.json').replace(
              queryParameters: {
                'search':
                    '(openfda.brand_name:"$drug1" OR openfda.generic_name:"$drug1" OR openfda.brand_name:"$drug1"~2 OR openfda.generic_name:"$drug1"~2) AND _exists_:drug_interactions AND _exists_:openfda',
                'limit': '1',
              },
            ),
          );

          if (response1.statusCode == 200) {
            final data1 = json.decode(response1.body);
            if (!data1.containsKey('results')) {
              throw Exception('Invalid API response format');
            }

            final results = data1['results'] as List<dynamic>;
            if (results.isNotEmpty && results[0] is Map<String, dynamic>) {
              final result = results[0] as Map<String, dynamic>;
              if (result['drug_interactions'] is List &&
                  result['drug_interactions'].isNotEmpty) {
                final interactionText =
                    result['drug_interactions'][0] as String;
                final drug2Variations = [
                  drug2.toLowerCase(),
                  drug2.toLowerCase().replaceAll(' ', ''),
                  drug2.toLowerCase().replaceAll('-', ' '),
                  drug2.toLowerCase().replaceAll('-', ''),
                ];

                if (drug2Variations.any((variation) =>
                    interactionText.toLowerCase().contains(variation))) {
                  final cleanText = _cleanInteractionText(interactionText);
                  if (cleanText.isNotEmpty) {
                    interactions.add({
                      'drug1': drug1,
                      'drug2': drug2,
                      'description': cleanText,
                      'severity': _determineSeverity(interactionText),
                    });
                    continue;
                  }
                }
              }
            }
          } else if (response1.statusCode != 404) {
            throw Exception(
                'Failed to check interactions: ${response1.statusCode}');
          }

          await _throttleRequest('interaction');

          final response2 = await http.get(
            Uri.parse('$_baseUrl/label.json').replace(
              queryParameters: {
                'search':
                    '(openfda.brand_name:"$drug2" OR openfda.generic_name:"$drug2" OR openfda.brand_name:"$drug2"~2 OR openfda.generic_name:"$drug2"~2) AND _exists_:drug_interactions AND _exists_:openfda',
                'limit': '1',
              },
            ),
          );

          if (response2.statusCode == 200) {
            final data2 = json.decode(response2.body);
            if (!data2.containsKey('results')) {
              throw Exception('Invalid API response format');
            }

            final results = data2['results'] as List<dynamic>;
            if (results.isNotEmpty && results[0] is Map<String, dynamic>) {
              final result = results[0] as Map<String, dynamic>;
              if (result['drug_interactions'] is List &&
                  result['drug_interactions'].isNotEmpty) {
                final interactionText =
                    result['drug_interactions'][0] as String;
                final drug1Variations = [
                  drug1.toLowerCase(),
                  drug1.toLowerCase().replaceAll(' ', ''),
                  drug1.toLowerCase().replaceAll('-', ' '),
                  drug1.toLowerCase().replaceAll('-', ''),
                ];

                if (drug1Variations.any((variation) =>
                    interactionText.toLowerCase().contains(variation))) {
                  final cleanText = _cleanInteractionText(interactionText);
                  if (cleanText.isNotEmpty) {
                    interactions.add({
                      'drug1': drug2,
                      'drug2': drug1,
                      'description': cleanText,
                      'severity': _determineSeverity(interactionText),
                    });
                  }
                }
              }
            }
          } else if (response2.statusCode != 404) {
            throw Exception(
                'Failed to check interactions: ${response2.statusCode}');
          }
        }
      }
    } catch (e) {
      print('Error checking interactions: $e');
      throw e;
    }

    return interactions;
  }

  Future<Map<String, dynamic>> getDrugInfo(String drug) async {
    try {
      await _throttleRequest('info');

      final cacheKey = 'info_$drug';
      final cachedInfo = _getCachedData(cacheKey);
      if (cachedInfo != null) {
        return Map<String, dynamic>.from(cachedInfo);
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/label.json').replace(
          queryParameters: {
            'search':
                '(openfda.brand_name:"$drug" OR openfda.generic_name:"$drug" OR openfda.brand_name:"$drug"~2 OR openfda.generic_name:"$drug"~2) AND _exists_:openfda AND (_exists_:warnings OR _exists_:adverse_reactions)',
            'limit': '1',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data.containsKey('results')) {
          throw Exception('Invalid API response format');
        }

        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final result = results[0] as Map<String, dynamic>;
          final info = <String, String>{};

          if (result.containsKey('openfda') &&
              result['openfda'] is Map<String, dynamic>) {
            final openfda = result['openfda'] as Map<String, dynamic>;
            info['brand_name'] = _extractFirstValue(openfda['brand_name']);
            info['generic_name'] = _extractFirstValue(openfda['generic_name']);
            info['route'] = _extractFirstValue(openfda['route']);
          } else {
            info['brand_name'] = _extractFirstValue(result['brand_name']);
            info['generic_name'] = _extractFirstValue(result['generic_name']);
            info['route'] =
                _extractFirstValue(result['dosage_and_administration']);
          }

          info['warnings'] =
              _extractAndTruncateText(result['boxed_warnings']) != 'N/A'
                  ? _extractAndTruncateText(result['boxed_warnings'])
                  : _extractAndTruncateText(result['warnings']);

          info['side_effects'] =
              _extractAndTruncateText(result['adverse_reactions']);

          _cacheData(cacheKey, Map<String, dynamic>.from(info));
          return info;
        }
      } else if (response.statusCode != 404) {
        throw Exception('Failed to get drug info: ${response.statusCode}');
      }
      return {};
    } catch (e) {
      print('Error getting drug info: $e');
      return {};
    }
  }
}
