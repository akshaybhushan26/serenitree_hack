import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DrugInteractionService {
  final String _baseUrl = 'https://api.fda.gov/drug';
  final _rateLimiter = <String, DateTime>{};
  final _cacheDuration = const Duration(minutes: 5);
  final _cache = <String, dynamic>{};
  final _minRequestInterval = const Duration(milliseconds: 200);

  bool _isValidDrugName(String name) {
    return name.isNotEmpty && RegExp(r'^[a-zA-Z0-9\- ]+$').hasMatch(name);
  }

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
    var cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.length > 300) {
      final sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
      cleaned = '';
      for (var sentence in sentences) {
        if ((cleaned + sentence).length > 300) break;
        cleaned += '$sentence ';
      }
      cleaned = cleaned.trim();
    }

    return cleaned;
  }

  String _determineSeverity(String text) {
    final lowercaseText = text.toLowerCase();

    if (lowercaseText.contains('severe') ||
        lowercaseText.contains('dangerous') ||
        lowercaseText.contains('fatal') ||
        lowercaseText.contains('life-threatening') ||
        lowercaseText.contains('contraindicated') ||
        lowercaseText.contains('avoid') ||
        lowercaseText.contains('serious') ||
        lowercaseText.contains('warning') ||
        lowercaseText.contains('stop') ||
        lowercaseText.contains('emergency')) {
      return 'high';
    }

    if (lowercaseText.contains('moderate') ||
        lowercaseText.contains('significant') ||
        lowercaseText.contains('monitor') ||
        lowercaseText.contains('adjust') ||
        lowercaseText.contains('may increase') ||
        lowercaseText.contains('may decrease') ||
        lowercaseText.contains('caution') ||
        lowercaseText.contains('consider') ||
        lowercaseText.contains('potential') ||
        lowercaseText.contains('possible')) {
      return 'medium';
    }

    if (lowercaseText.contains('mild') ||
        lowercaseText.contains('minor') ||
        lowercaseText.contains('minimal') ||
        lowercaseText.contains('slight') ||
        lowercaseText.contains('rarely')) {
      return 'low';
    }

    if (lowercaseText.contains('interaction') ||
        lowercaseText.contains('effect') ||
        lowercaseText.contains('level')) {
      return 'medium';
    }

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
    final now = DateTime.now();
    final lastRequest = _rateLimiter[key];
    
    if (lastRequest != null) {
      final timeSinceLastRequest = now.difference(lastRequest);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
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
    if (query.isEmpty) {
      throw Exception('Please enter a drug name to search');
    }

    if (query.length < 3) {
      throw Exception('Please enter at least 3 characters to search');
    }

    await _throttleRequest('search');
    final cacheKey = 'search_$query';
    final cachedResults = _getCachedData(cacheKey);

    if (cachedResults != null) {
      if (cachedResults.isEmpty) {
        throw Exception('No medications found matching "$query"');
      }
      return List<String>.from(cachedResults);
    }

    try {
      final searchQuery = Uri.encodeComponent(
        'openfda.brand_name:"${query.trim()}" OR ' 'openfda.brand_name:"${query.trim()}*" OR ' 'openfda.generic_name:"${query.trim()}" OR ' +
        'openfda.generic_name:"${query.trim()}*"'
      );

      final url = Uri.parse('$_baseUrl/label.json?search=$searchQuery&limit=100');
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
            
            if (openfda['brand_name'] is List) {
              for (final name in openfda['brand_name']) {
                if (name is String) {
                  uniqueDrugs.add(name);
                }
              }
            }
            
            if (openfda['generic_name'] is List) {
              for (final name in openfda['generic_name']) {
                if (name is String) {
                  uniqueDrugs.add(name);
                }
              }
            }
          }
        }

        final filteredDrugs = uniqueDrugs
            .where((drug) => drug.toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        _cacheData(cacheKey, filteredDrugs);
        
        if (filteredDrugs.isEmpty) {
          throw Exception('No medications found matching "$query"');
        }
        return filteredDrugs;

      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a few moments.');
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to search drugs (Status ${response.statusCode}). Please try again.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while searching. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> checkInteractions(List<String> drugs) async {
    if (drugs.isEmpty) {
      return [];
    }

    for (final drug in drugs) {
      if (!_isValidDrugName(drug)) {
        throw Exception('Invalid drug name format: "$drug". Drug names should only contain letters, numbers, spaces, and hyphens.');
      }
    }

    final interactions = <Map<String, dynamic>>[];
    final processedPairs = <String>{};

    try {
      for (var i = 0; i < drugs.length; i++) {
        for (var j = i + 1; j < drugs.length; j++) {
          final drug1 = drugs[i];
          final drug2 = drugs[j];
          final drugNames = [drug1.toLowerCase(), drug2.toLowerCase()];
          drugNames.sort();
          final pairKey = drugNames.join('_');
          
          if (processedPairs.contains(pairKey)) continue;
          processedPairs.add(pairKey);

          await _throttleRequest('interaction');

          final cacheKey = 'interaction_$pairKey';
          final cachedInteraction = _getCachedData(cacheKey);
          if (cachedInteraction != null) {
            if (cachedInteraction is List) {
              interactions.addAll(List<Map<String, dynamic>>.from(cachedInteraction));
            }
            continue;
          }

          final pairInteractions = await _checkDrugPairInteractions(drug1, drug2);
          if (pairInteractions.isNotEmpty) {
            interactions.addAll(pairInteractions);
            _cacheData(cacheKey, pairInteractions);
          }
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while checking interactions. Please try again.');
    }

    return interactions;
  }

  Future<List<Map<String, dynamic>>> _checkDrugPairInteractions(String drug1, String drug2) async {
    final interactions = <Map<String, dynamic>>[];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/label.json').replace(
          queryParameters: {
            'search': '(openfda.brand_name:"$drug1" OR openfda.generic_name:"$drug1") AND _exists_:drug_interactions AND _exists_:openfda',
            'limit': '1',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          if (result['drug_interactions'] != null) {
            final interactionTexts = result['drug_interactions'] as List<dynamic>;
            for (final text in interactionTexts) {
              if (_containsDrug(text.toString(), drug2)) {
                final cleanText = _cleanInteractionText(text.toString());
                if (cleanText.isNotEmpty) {
                  interactions.add({
                    'drug1': drug1,
                    'drug2': drug2,
                    'description': cleanText,
                    'severity': _determineSeverity(text.toString()),
                  });
                  break;
                }
              }
            }
          }
        }
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a few moments.');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request format. Please check drug names and try again.');
      } else if (response.statusCode != 404) {
        throw Exception('Failed to check interactions (Status ${response.statusCode}). Please try again.');
      }

      if (interactions.isEmpty) {
        final reverseResponse = await http.get(
          Uri.parse('$_baseUrl/label.json').replace(
            queryParameters: {
              'search': '(openfda.brand_name:"$drug2" OR openfda.generic_name:"$drug2") AND _exists_:drug_interactions AND _exists_:openfda',
              'limit': '1',
            },
          ),
        );

        if (reverseResponse.statusCode == 200) {
          final data = json.decode(reverseResponse.body);
          if (data['results'] != null && data['results'].isNotEmpty) {
            final result = data['results'][0];
            if (result['drug_interactions'] != null) {
              final interactionTexts = result['drug_interactions'] as List<dynamic>;
              for (final text in interactionTexts) {
                if (_containsDrug(text.toString(), drug1)) {
                  final cleanText = _cleanInteractionText(text.toString());
                  if (cleanText.isNotEmpty) {
                    interactions.add({
                      'drug1': drug2,
                      'drug2': drug1,
                      'description': cleanText,
                      'severity': _determineSeverity(text.toString()),
                    });
                    break;
                  }
                }
              }
            }
          }
        } else if (reverseResponse.statusCode == 429) {
          throw Exception('Too many requests. Please try again in a few moments.');
        } else if (reverseResponse.statusCode == 400) {
          throw Exception('Invalid request format. Please check drug names and try again.');
        } else if (reverseResponse.statusCode != 404) {
          throw Exception('Failed to check interactions (Status ${reverseResponse.statusCode}). Please try again.');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while checking drug interactions. Please try again.');
    }

    return interactions;
  }

  bool _containsDrug(String text, String drugName) {
    final variations = [
      drugName.toLowerCase(),
      drugName.toLowerCase().replaceAll(' ', ''),
      drugName.toLowerCase().replaceAll('-', ' '),
      drugName.toLowerCase().replaceAll('-', ''),
    ];
    
    return variations.any((variation) => text.toLowerCase().contains(variation));
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
            info['route'] = _extractFirstValue(result['dosage_and_administration']);
          }

          info['warnings'] =
              _extractAndTruncateText(result['boxed_warnings']) != 'N/A'
                  ? _extractAndTruncateText(result['boxed_warnings'])
                  : _extractAndTruncateText(result['warnings']);

          info['side_effects'] = _extractAndTruncateText(result['adverse_reactions']);

          _cacheData(cacheKey, Map<String, dynamic>.from(info));
          return info;
        }
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a few moments.');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request format. Please check drug name and try again.');
      } else if (response.statusCode != 404) {
        throw Exception('Failed to get drug info (Status ${response.statusCode}). Please try again.');
      }
      return {};
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while getting drug information. Please try again.');
    }
  }
}
