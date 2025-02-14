import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/audio_service.dart';

class TherapyScreen extends StatefulWidget {
  const TherapyScreen({super.key});

  @override
  State<TherapyScreen> createState() => _TherapyScreenState();
}

class _TherapyScreenState extends State<TherapyScreen> {
  bool _isExerciseInProgress = false;
  int _exerciseTimeLeft = 300; // 5 minutes in seconds
  String? _currentAudioId;

  final List<Map<String, dynamic>> _exercises = [
    {
      'title': 'Mindful Breathing',
      'description': 'Take 5 minutes to practice deep breathing and center yourself.',
      'duration': '5 minutes',
      'audioUrl': 'assets/audio/mindful_breathing.mp3',
    },
    {
      'title': 'Progressive Relaxation',
      'description': 'Systematically relax each muscle group in your body.',
      'duration': '10 minutes',
      'audioUrl': 'assets/audio/progressive_relaxation.mp3',
    },
    {
      'title': 'Guided Visualization',
      'description': 'Journey through a peaceful mental landscape.',
      'duration': '8 minutes',
      'audioUrl': 'assets/audio/guided_visualization.mp3',
    },
  ];

  @override
  void dispose() {
    if (_currentAudioId != null) {
      AudioService().stop(_currentAudioId!);
    }
    super.dispose();
  }

  Future<void> _startExercise() async {
    setState(() {
      _isExerciseInProgress = true;
    });

    // Start audio for mindful breathing
    try {
      final audioService = AudioService();
      _currentAudioId = 'mindful_breathing';
      await audioService.playAsset(_currentAudioId!, 'assets/audio/mindful_breathing.mp3');
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }

    // Start timer
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _exerciseTimeLeft--;
      });
      if (_exerciseTimeLeft > 0 && _isExerciseInProgress) {
        _startExercise();
      } else if (_exerciseTimeLeft == 0) {
        _completeExercise();
      }
    });
  }

  Future<void> _completeExercise() async {
    if (_currentAudioId != null) {
      await AudioService().stop(_currentAudioId!);
      _currentAudioId = null;
    }

    setState(() {
      _isExerciseInProgress = false;
      _exerciseTimeLeft = 300;
    });
    
    if (!mounted) return;
    context.read<AppState>().incrementCompletedExercises();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Great job! Exercise completed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cancelExercise() async {
    if (_currentAudioId != null) {
      await AudioService().stop(_currentAudioId!);
      _currentAudioId = null;
    }

    setState(() {
      _isExerciseInProgress = false;
      _exerciseTimeLeft = 300;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text('Therapy'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDailyExercise(context),
                  const SizedBox(height: 24),
                  _buildProgress(context),
                  const SizedBox(height: 24),
                  _buildExerciseList(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyExercise(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 32,
              ).animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 8),
              const Text(
                'Daily Exercise',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate()
                .fadeIn()
                .slideX(begin: -0.2, end: 0),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Mindful Breathing',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate()
            .fadeIn(delay: 200.ms)
            .slideX(begin: -0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
            'Take 5 minutes to practice deep breathing and center yourself.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ).animate()
            .fadeIn(delay: 400.ms)
            .slideX(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          if (_isExerciseInProgress) ...[            
            Text(
              _formatTime(_exerciseTimeLeft),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _cancelExercise,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.stop),
              label: const Text('Stop Exercise'),
            ),
          ] else ...[            
            FilledButton.icon(
              onPressed: _startExercise,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Exercise'),
            ),
          ],
        ],
      ),
    ).animate()
      .fadeIn()
      .scale(delay: 100.ms);
  }

  Widget _buildProgress(BuildContext context) {
    final completedExercises = context.watch<AppState>().completedExercises;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: Theme.of(context).textTheme.titleLarge,
        ).animate()
          .fadeIn()
          .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exercises Completed'),
                    Text(
                      '$completedExercises',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn()
          .slideX(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildExerciseList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Exercises',
          style: Theme.of(context).textTheme.titleLarge,
        ).animate()
          .fadeIn()
          .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        ..._exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                exercise['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(exercise['description']),
                  const SizedBox(height: 4),
                  Text(
                    exercise['duration'],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_outline),
                iconSize: 32,
                onPressed: () async {
                  final audioService = AudioService();
                  final exerciseId = exercise['title'].toString().toLowerCase().replaceAll(' ', '_');
                  
                  // Stop current exercise if any
                  if (_currentAudioId != null) {
                    await audioService.stop(_currentAudioId!);
                  }

                  try {
                    await audioService.playAsset(exerciseId, exercise['audioUrl']);
                    setState(() {
                      _currentAudioId = exerciseId;
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing ${exercise['title']}'),
                        action: SnackBarAction(
                          label: 'Stop',
                          onPressed: () async {
                            await audioService.stop(exerciseId);
                            setState(() {
                              _currentAudioId = null;
                            });
                          },
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error playing audio: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
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
