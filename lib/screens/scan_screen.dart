import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../providers/app_state.dart';
import 'camera_preview_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  String _error = '';
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> _scanAndProcessImage(BuildContext context) async {
    setState(() {
      _isScanning = true;
      _error = '';
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 3200,
        imageQuality: 100,
      );
      if (image == null) {
        setState(() {
          _isScanning = false;
          _error = 'No image selected';
        });
        return;
      }

      await _processImage(image);
    } catch (e) {
      setState(() {
        _error = 'Error processing image: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      debugPrint('Starting image processing from path: ${image.path}');
      
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      debugPrint('Raw recognized text:\n${recognizedText.text}');
      debugPrint('Number of text blocks: ${recognizedText.blocks.length}');
      
      for (final block in recognizedText.blocks) {
        debugPrint('Block text: ${block.text}');
        debugPrint('Block corner points: ${block.cornerPoints}');
        debugPrint('Block languages: ${block.recognizedLanguages}');
        
        for (final line in block.lines) {
          debugPrint('Line text: ${line.text}');
          debugPrint('Line corner points: ${line.cornerPoints}');
        }
      }

      if (recognizedText.text.isEmpty) {
        setState(() {
          _error = 'No text detected in the image. Please ensure the prescription is well-lit and clearly visible.';
          _isScanning = false;
        });
        return;
      }

      final medications = _extractMedicationsFromText(recognizedText.text);

      debugPrint('Extracted medications: $medications');

      if (medications.isEmpty) {
        setState(() {
          _error = 'No medications found in the image. Please ensure the prescription is clear and contains medication details.';
          _isScanning = false;
        });
        return;
      }

      await _handleScannedMedications(context, medications);
    } catch (e) {
      debugPrint('Error during image processing: $e');
      if (mounted) {
        setState(() {
          _error = 'Error processing image: ${e.toString()}';
          _isScanning = false;
        });
      }
    }
  }

  List<Map<String, String>> _extractMedicationsFromText(String text) {
    debugPrint('Extracting medications from text block:\n$text');
    
    final List<Map<String, String>> medications = [];
    
    // Normalize text
    text = text.replaceAll(RegExp(r'[\u2018\u2019]'), "'")
             .replaceAll(RegExp(r'[\u201C\u201D]'), '"')
             .replaceAll(RegExp(r'[^\w\s.,;:\/\-()%+]'), ' ')
             .replaceAll(RegExp(r'\s+'), ' ')
             .trim();

    // Split into lines and process each line
    final lines = text.split(RegExp(r'[\n\r]+'));
    
    // Pattern to match medication entries (specifically for the prescription format)
    final medicationPattern = RegExp(
      r'\b(?:TAB|CAP|INJ|SYR|SUSP|SOL|OINT|GEL|DROP|CREAM)\s+([A-Z0-9\s-]+(?:\s+(?:CR|SR|XR|ER|IR|PR|MR|DR|XL|LA|HD|HS|DS|ES|XT|CD|TR|HCT|Plus|Forte|Junior|Adult|Pediatric|Max))?)(?:\s+(?:\d+(?:\.\d+)?\s*(?:MG|MCG|ML|G|IU|%)))?\b',
      caseSensitive: true
    );

    // Pattern to match dosage information
    final dosagePattern = RegExp(
      r'\b(?:\d+(?:\.\d+)?\s*(?:MG|MCG|ML|G|IU|%)|(?:HALF|ONE|TWO|THREE|FOUR|FIVE)\s+(?:TAB|CAP|ML|TABLET|CAPSULE)S?)\b',
      caseSensitive: true
    );

    // Pattern to match frequency information
    final frequencyPattern = RegExp(
      r'\b(?:ONCE|TWICE|THRICE|DAILY|WEEKLY|MONTHLY|(?:IN|AT)\s+(?:MORNING|NIGHT|EVENING|AFTERNOON)|(?:BEFORE|AFTER)\s+(?:MEAL|FOOD)|(?:\d+\s*TIMES?\s*(?:A|PER)?\s*DAY)|SOS|PRN)\b',
      caseSensitive: true
    );

    String? currentMedication;
    String? currentDosage;
    String? currentFrequency;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check for medication name
      final medMatch = medicationPattern.firstMatch(line);
      if (medMatch != null) {
        // Save previous medication if exists
        if (currentMedication != null) {
          medications.add({
            'name': currentMedication,
            'dosage': currentDosage ?? 'As prescribed',
            'frequency': currentFrequency ?? 'Daily'
          });
        }

        // Start new medication
        currentMedication = line.trim();
        currentDosage = null;
        currentFrequency = null;
        continue;
      }

      // Check for dosage
      if (currentMedication != null) {
        final dosageMatch = dosagePattern.firstMatch(line);
        if (dosageMatch != null) {
          currentDosage = line.trim();
          continue;
        }

        // Check for frequency
        final freqMatch = frequencyPattern.firstMatch(line);
        if (freqMatch != null) {
          currentFrequency = line.trim();
        }
      }
    }

    // Add the last medication if exists
    if (currentMedication != null) {
      medications.add({
        'name': currentMedication,
        'dosage': currentDosage ?? 'As prescribed',
        'frequency': currentFrequency ?? 'Daily'
      });
    }

    return medications;
  }

  Future<void> _handleScannedMedications(BuildContext context, List<Map<String, String>> medications) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      int successCount = 0;

      for (final medication in medications) {
        final name = medication['name']?.trim() ?? '';
        if (name.isEmpty) continue;

        // Extract actual medication name by removing common prefixes
        final cleanName = name.replaceAll(RegExp(r'^(?:TAB|CAP|INJ|SYR|SUSP|SOL|OINT|GEL|DROP|CREAM)\s+'), '');
        
        await appState.addMedication(
          name: cleanName,
          dosage: medication['dosage']?.trim() ?? 'As prescribed',
          frequency: medication['frequency']?.trim() ?? 'Daily',
          time: const TimeOfDay(hour: 8, minute: 0)
        );
        successCount++;
      }

      if (successCount > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully added $successCount medication(s)')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error = 'No valid medications found in the scan. Please try again.';
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

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Scan Prescription',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_error.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.document_scanner,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Choose Scan Method',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),
                            FilledButton.icon(
                              onPressed: _isScanning
                                  ? null
                                  : () async {
                                      final image = await Navigator.push<XFile?>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CameraPreviewScreen(),
                                        ),
                                      );
                                      if (image != null) {
                                        setState(() {
                                          _isScanning = true;
                                          _error = '';
                                        });
                                        await _processImage(image);
                                      }
                                    },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Scan with Camera'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _isScanning ? null : () => _scanAndProcessImage(context),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Import from Gallery'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideY(
                            begin: 0.3,
                            duration: const Duration(milliseconds: 500),
                          ),
                      if (_isScanning)
                        Padding(
                          padding: const EdgeInsets.only(top: 32.0),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Processing image...',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
