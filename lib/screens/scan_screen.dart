import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

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
                      Icon(
                        Icons.document_scanner,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary,
                      ).animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 24),
                      const Text(
                        'Scan your prescription',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate()
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                      const Text(
                        'Take a clear photo of your prescription to extract medication information',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ).animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () {
                          // TODO: Implement camera functionality
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ).animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement gallery functionality
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose from Gallery'),
                      ).animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(height: 8),
                            Text(
                              'Tips for best results:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Ensure good lighting\n'
                              '• Keep the prescription flat\n'
                              '• Capture all text clearly\n'
                              '• Avoid shadows and glare',
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: 800.ms)
                        .slideY(begin: 0.2, end: 0),
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
