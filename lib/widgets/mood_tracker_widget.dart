import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serenitree_hack/screens/mood_history_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_entry.dart';
import '../providers/app_state.dart';
import '../services/audio_service.dart';

class MoodTrackerWidget extends StatefulWidget {
  const MoodTrackerWidget({super.key});

  @override
  State<MoodTrackerWidget> createState() => _MoodTrackerWidgetState();
}

class _MoodTrackerWidgetState extends State<MoodTrackerWidget> {
  double _moodValue = 0.5;
  late Box<MoodEntry> _moodBox;
  String? _currentExerciseId;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  @override
  void dispose() {
    if (_currentExerciseId != null) {
      AudioService().stop(_currentExerciseId!);
    }
    super.dispose();
  }

  Future<void> _initHive() async {
    _moodBox = await Hive.openBox<MoodEntry>('mood_entries');
  }

  final List<Map<String, dynamic>> _exercises = [
    {
      'title': 'Deep Breathing',
      'description': 'Calming breath exercise with guided audio',
      'duration': '5 minutes',
      'audioUrl': 'assets/audio/deep_breathing.mp3',
      'moodRange': [0.0, 0.3], // For sad moods
    },
    {
      'title': 'Progressive Muscle Relaxation',
      'description': 'Relax your body and mind systematically',
      'duration': '10 minutes',
      'audioUrl': 'assets/audio/muscle_relaxation.mp3',
      'moodRange': [0.0, 0.4], // For tense/anxious moods
    },
    {
      'title': 'Mindful Walking',
      'description': 'Gentle walking meditation with nature sounds',
      'duration': '15 minutes',
      'audioUrl': 'assets/audio/mindful_walking.mp3',
      'moodRange': [0.3, 0.7], // For neutral moods
    },
    {
      'title': 'Gratitude Meditation',
      'description': 'Focus on positive aspects of life',
      'duration': '8 minutes',
      'audioUrl': 'assets/audio/gratitude.mp3',
      'moodRange': [0.6, 1.0], // For positive moods
    },
  ];

  String _getMoodText(double value) {
    if (value < 0.2) return 'Very Sad';
    if (value < 0.4) return 'Sad';
    if (value < 0.6) return 'Neutral';
    if (value < 0.8) return 'Happy';
    return 'Very Happy';
  }

  Color _getMoodColor(double value) {
    if (value < 0.2) return Colors.red[300]!;
    if (value < 0.4) return Colors.orange[300]!;
    if (value < 0.6) return Colors.yellow[300]!;
    if (value < 0.8) return Colors.lightGreen[300]!;
    return Colors.green[300]!;
  }

  List<Map<String, dynamic>> _getRecommendedExercises() {
    return _exercises.where((exercise) {
      final range = exercise['moodRange'] as List<double>;
      return _moodValue >= range[0] && _moodValue <= range[1];
    }).toList();
  }

  Future<void> _playExercise(Map<String, dynamic> exercise) async {
    final audioService = AudioService();
    final exerciseId = exercise['title'].toString().toLowerCase().replaceAll(' ', '_');

    // Stop current exercise if any
    if (_currentExerciseId != null) {
      await audioService.stop(_currentExerciseId!);
    }

    try {
      await audioService.playAsset(exerciseId, exercise['audioUrl']);
      setState(() {
        _currentExerciseId = exerciseId;
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
                _currentExerciseId = null;
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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.sentiment_very_dissatisfied),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _getMoodColor(_moodValue),
                      thumbColor: _getMoodColor(_moodValue),
                    ),
                    child: Slider(
                      value: _moodValue,
                      onChanged: (value) {
                        setState(() => _moodValue = value);
                        final moodEntry = MoodEntry(
                          moodLevel: (value * 100).toInt(),
                          timestamp: DateTime.now(),
                          note: '',
                        );
                        _moodBox.add(moodEntry);
                        context.read<AppState>().addMoodEntry(moodEntry);
                      },
                    ),
                  ),
                ),
                const Icon(Icons.sentiment_very_satisfied),
              ],
            ),
            Center(
              child: Text(
                _getMoodText(_moodValue),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recommended Exercises',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._getRecommendedExercises().map((exercise) => ListTile(
              title: Text(exercise['title']),
              subtitle: Text(exercise['description']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(exercise['duration']),
                  if (_currentExerciseId == exercise['title'].toString().toLowerCase().replaceAll(' ', '_'))
                    const Icon(Icons.volume_up, size: 16),
                ],
              ),
              onTap: () => _playExercise(exercise),
            )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Mood History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MoodHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
