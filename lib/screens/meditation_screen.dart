import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/audio_service.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  String? _currentAudioId;

  final List<Map<String, dynamic>> _meditations = [
    {
      'title': 'Morning Meditation',
      'description': 'Start your day with mindfulness and clarity.',
      'duration': '10 minutes',
      'audioUrl': 'assets/audio/morning_meditation.mp3',
      'icon': Icons.wb_sunny,
    },
    {
      'title': 'Stress Relief',
      'description': 'Release tension and find inner peace.',
      'duration': '15 minutes',
      'audioUrl': 'assets/audio/stress_relief.mp3',
      'icon': Icons.spa,
    },
    {
      'title': 'Sleep Well',
      'description': 'Gentle guidance into restful sleep.',
      'duration': '20 minutes',
      'audioUrl': 'assets/audio/sleep_well.mp3',
      'icon': Icons.nightlight_round,
    },
    {
      'title': 'Focus & Clarity',
      'description': 'Sharpen your mind and enhance concentration.',
      'duration': '12 minutes',
      'audioUrl': 'assets/audio/focus_clarity.mp3',
      'icon': Icons.lens_blur,
    },
  ];

  @override
  void dispose() {
    if (_currentAudioId != null) {
      AudioService().stop(_currentAudioId!);
    }
    super.dispose();
  }

  Future<void> _playMeditation(Map<String, dynamic> meditation) async {
    final audioService = AudioService();
    final meditationId = meditation['title'].toString().toLowerCase().replaceAll(' ', '_');

    // Stop current meditation if any
    if (_currentAudioId != null) {
      await audioService.stop(_currentAudioId!);
    }

    try {
      await audioService.playAsset(meditationId, meditation['audioUrl']);
      setState(() {
        _currentAudioId = meditationId;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing ${meditation['title']}'),
          action: SnackBarAction(
            label: 'Stop',
            onPressed: () async {
              await audioService.stop(meditationId);
              setState(() {
                _currentAudioId = null;
              });
            },
          ),
        ),
      );

      // Update meditation minutes in app state
      final minutes = int.tryParse(meditation['duration'].split(' ')[0]) ?? 0;
      context.read<AppState>().addMeditationMinutes(minutes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = context.watch<AppState>().meditationMinutes;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text('Meditation'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProgressCard(context, totalMinutes),
                  const SizedBox(height: 24),
                  _buildMeditationList(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int totalMinutes) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.self_improvement,
              color: Colors.white,
              size: 48,
            ).animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              '$totalMinutes',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate()
              .fadeIn(delay: 200.ms)
              .slideX(begin: -0.2, end: 0),
            const Text(
              'Minutes Meditated',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ).animate()
              .fadeIn(delay: 400.ms)
              .slideX(begin: -0.2, end: 0),
          ],
        ),
      ),
    ).animate()
      .fadeIn()
      .scale(delay: 100.ms);
  }

  Widget _buildMeditationList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meditations',
          style: Theme.of(context).textTheme.titleLarge,
        ).animate()
          .fadeIn()
          .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        ..._meditations.asMap().entries.map((entry) {
          final index = entry.key;
          final meditation = entry.value;
          final isPlaying = _currentAudioId == meditation['title'].toString().toLowerCase().replaceAll(' ', '_');

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                meditation['icon'] as IconData,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                meditation['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(meditation['description']),
                  const SizedBox(height: 4),
                  Text(
                    meditation['duration'],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_outline),
                iconSize: 32,
                onPressed: () async {
                  if (isPlaying) {
                    await AudioService().stop(_currentAudioId!);
                    setState(() {
                      _currentAudioId = null;
                    });
                  } else {
                    await _playMeditation(meditation);
                  }
                },
              ),
            ),
          ).animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn()
            .slideX();
        }).toList(),
      ],
    );
  }
}
