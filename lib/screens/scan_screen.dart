import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:serenitree_hack/screens/camera_preview_screen.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/app_state.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  String _error = '';

  Future<void> _handleScannedMedications(BuildContext context, List<Map<String, String>> medications) async {
    setState(() {
      _isScanning = true;
      _error = '';
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      int successCount = 0;
      List<String> errorMessages = [];

      for (final medication in medications) {
        final name = medication['name']?.trim() ?? '';
        final dosage = medication['dosage']?.trim() ?? '';
        
        if (name.isEmpty) {
          errorMessages.add('Invalid medication name detected');
          continue;
        }

        if (dosage.isNotEmpty && !RegExp(r'^[0-9]+(.?[0-9]*)?s*(mg|g|ml|mcg|IU|tablet(s)?|capsule(s)?|pill(s)?|dose(s)?)$', caseSensitive: false).hasMatch(dosage)) {
          errorMessages.add('Invalid dosage format for $name');
          continue;
        }
        
        final defaultTime = TimeOfDay(hour: 8, minute: 0);
        TimeOfDay medicationTime = defaultTime;

        if (medication['time'] != null && medication['time']!.isNotEmpty) {
          final timeStr = medication['time']!.trim();
          if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timeStr)) {
            try {
              final timeParts = timeStr.split(':');
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
                medicationTime = TimeOfDay(hour: hour, minute: minute);
              } else {
                errorMessages.add('Invalid time format for $name: Hour must be 0-23, minute must be 0-59');
              }
            } catch (e) {
              errorMessages.add('Invalid time format for $name. Using default time (8:00 AM)');
            }
          }
        }

        appState.addMedication(
          name: name,
          dosage: dosage.isNotEmpty ? dosage : 'Not specified',
          frequency: medication['frequency']?.trim().isNotEmpty == true
              ? medication['frequency']!.trim()
              : 'Daily',
          time: medicationTime
        );
        successCount++;
      }

      if (successCount > 0) {
        String message = 'Successfully added $successCount medication(s)';
        if (errorMessages.isNotEmpty) {
          message += '\nWarnings: ${errorMessages.join('. ')}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error = errorMessages.isEmpty 
              ? 'No valid medications found in the scan. Please try again.'
              : errorMessages.join('\n');
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error processing scan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<List<Map<String, String>>> _analyzeWithAI(String text) async {
    try {
      // You would replace this URL with your actual AI service endpoint
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY', // Replace with actual API key
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a medical prescription analyzer. Extract medication names, dosages, and frequencies from the following text. Return the data in a structured format.'
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
        
        // Parse the AI response and convert it to our medication format
        // This is a simplified example - you would need to parse the actual AI response
        final List<Map<String, String>> medications = [];
        // Add parsing logic here based on AI response format
        
        return medications;
      } else {
        throw Exception('Failed to analyze with AI: ${response.statusCode}');
      }
    } catch (e) {
      print('AI Analysis Error: $e');
      return [];
    }
  }

  Future<void> _processImage(XFile? image) async {
    if (image == null) return;

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        final text = recognizedText.text;
        
        // First try AI analysis
        final aiMedications = await _analyzeWithAI(text);
        if (aiMedications.isNotEmpty) {
          await _handleScannedMedications(context, aiMedications);
          return;
        }
        
        // Fallback to regex pattern if AI analysis fails
        final medicationPattern = RegExp(
          r'([A-Za-z\s-]+(?:\s*\([^)]*\))?)s*' +
          r'(?:(\d+(?:\.\d+)?\s*(?:mg|g|ml|mcg|IU|tablet(?:s)?|capsule(?:s)?|pill(?:s)?|dose(?:s)?)(?:\s*\([^)]*\))?))?s*' +
          r'(?:((?:Once|Twice|Thrice|\d+\s+times?|Every|Each|Per|q\.?d\.?|b\.?i\.?d\.?)\s*' +
          r'(?:daily|day|morning|evening|night|afternoon|hour(?:s)?|week(?:ly)?|month(?:ly)?|prn|as\s+needed))?)',
          caseSensitive: false
        );
        
        final matches = medicationPattern.allMatches(text);
        final detectedMedications = matches.map((match) => <String, String>{
          'name': match.group(1)?.trim() ?? '',
          'dosage': match.group(2)?.trim() ?? '',
          'frequency': match.group(3)?.trim() ?? '',
          'time': ''
        }).where((med) => med['name']!.isNotEmpty).toList();
        
        if (detectedMedications.isNotEmpty) {
          await _handleScannedMedications(context, detectedMedications);
        } else {
          setState(() {
            _error = 'No medications detected. Please ensure the prescription is clearly visible and try again.';
            _isScanning = false;
          });
        }
      } finally {
        textRecognizer.close();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to process prescription: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  void _scanAndProcessImage(BuildContext context) async {
    setState(() {
      _isScanning = true;
      _error = '';
    });

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraPreviewScreen(),
        ),
      );

      if (result != null) {
        final image = result as XFile;
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        
        try {
          final recognizedText = await textRecognizer.processImage(inputImage);
          final text = recognizedText.text;
          
          // Extract medication information using regex patterns
          // More flexible pattern to detect medications
          final medicationPattern = RegExp(
            r'([A-Za-z\s-]+(?:\s*\([^)]*\))?)s*' + // Medication name with optional parenthetical info
            r'(?:(d+(?:\.\d+)?\s*(?:mg|g|ml|mcg|IU|tablet(?:s)?|capsule(?:s)?|pill(?:s)?|dose(?:s)?)(?:\s*\([^)]*\))?))?s*' + // Dosage with units and optional notes
            r'(?:((?:Once|Twice|Thrice|\d+\s+times?|Every|Each|Per|q\.?d\.?|b\.?i\.?d\.?)\s*' + // Frequency with medical abbreviations
            r'(?:daily|day|morning|evening|night|afternoon|hour(?:s)?|week(?:ly)?|month(?:ly)?|prn|as\s+needed))?)', // Time periods
            caseSensitive: false
          );
          
          final matches = medicationPattern.allMatches(text);
          final detectedMedications = matches.map((match) => <String, String>{
            'name': match.group(1)?.trim() ?? '',
            'dosage': match.group(2)?.trim() ?? '',
            'frequency': match.group(3)?.trim() ?? '',
            'time': ''
          }).where((med) => med['name']!.isNotEmpty).toList();
          
          if (detectedMedications.isNotEmpty) {
            await _handleScannedMedications(context, detectedMedications.cast<Map<String, String>>());
          } else {
            setState(() {
              _error = 'No medications detected. Please ensure the prescription is clearly visible and try again.';
              _isScanning = false;
            });
          }
        } finally {
          textRecognizer.close();
        }
      } else {
        setState(() {
          _error = 'Scanning cancelled';
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to scan prescription: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text('Scan Prescription'),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_isScanning)
                        const CircularProgressIndicator()
                      else
                        Icon(
                          Icons.document_scanner,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ).animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 24),
                      if (_error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ).animate()
                          .fadeIn()
                          .slideY(begin: 0.2, end: 0),
                      if (_error.isNotEmpty)
                        const SizedBox(height: 24),
                      const Text(
                        'Scan your prescription',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate()
                        .fadeIn(),
                      const SizedBox(height: 16),
                      const Text(
                        'Your medications will be automatically added',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ).animate()
                        .fadeIn(delay: 200.ms),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isScanning ? null : () => _scanAndProcessImage(context),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(_isScanning ? 'Scanning...' : 'Use Camera'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ).animate()
                            .fadeIn(delay: 400.ms)
                            .scale(delay: 400.ms),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isScanning
                                ? null
                                : () async {
                                    final picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 100,
                                    );
                                    if (image != null) {
                                      setState(() {
                                        _isScanning = true;
                                        _error = '';
                                      });
                                      await _processImage(image);
                                    }
                                  },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('From Gallery'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ).animate()
                            .fadeIn(delay: 600.ms)
                            .scale(delay: 600.ms),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
