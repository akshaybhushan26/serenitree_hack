import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TherapyScreen extends StatelessWidget {
  const TherapyScreen({super.key});

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
          FilledButton.icon(
            onPressed: () {
              // Start breathing exercise
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Exercise'),
          ).animate()
            .fadeIn(delay: 600.ms)
            .slideX(begin: -0.2, end: 0),
        ],
      ),
    ).animate()
      .fadeIn()
      .scale(delay: 100.ms);
  }

  Widget _buildExerciseList(BuildContext context) {
    final exercises = [
      {
        'icon': Icons.self_improvement,
        'title': 'Progressive Relaxation',
        'description': 'Relax your muscles one group at a time',
        'duration': '10 min',
      },
      {
        'icon': Icons.psychology,
        'title': 'Thought Record',
        'description': 'Challenge and reframe negative thoughts',
        'duration': '15 min',
      },
      {
        'icon': Icons.nature,
        'title': 'Grounding Exercise',
        'description': 'Connect with your surroundings using your senses',
        'duration': '5 min',
      },
      {
        'icon': Icons.edit_note,
        'title': 'Gratitude Journal',
        'description': 'Write down things you\'re grateful for',
        'duration': '10 min',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercises',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate()
          .fadeIn()
          .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  // Start exercise
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          exercise['icon'] as IconData,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(exercise['duration'] as String),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn()
            .slideX(begin: 0.2, end: 0);
        }),
      ],
    );
  }
}
