import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _buildBreathingCircle(context),
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

  Widget _buildBreathingCircle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Breathing Exercise',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn()
            .slideY(begin: -0.2, end: 0),
          const SizedBox(height: 24),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.self_improvement,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          )
            .scaleXY(
              duration: 4.seconds,
              curve: Curves.easeInOut,
              begin: 0.8,
              end: 1.2,
            )
            .then()
            .scaleXY(
              duration: 4.seconds,
              curve: Curves.easeInOut,
              begin: 1.2,
              end: 0.8,
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Start breathing exercise
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Breathing'),
          ).animate()
            .fadeIn(delay: 400.ms)
            .slideY(begin: 0.2, end: 0),
        ],
      ),
    ).animate()
      .fadeIn()
      .scale(delay: 100.ms);
  }

  Widget _buildMeditationList(BuildContext context) {
    final meditations = [
      {
        'title': 'Mindful Breathing',
        'description': 'Focus on your breath to calm your mind',
        'duration': '5 min',
        'color': Colors.blue[100],
        'icon': Icons.air,
      },
      {
        'title': 'Body Scan',
        'description': 'Release tension throughout your body',
        'duration': '10 min',
        'color': Colors.green[100],
        'icon': Icons.accessibility_new,
      },
      {
        'title': 'Loving Kindness',
        'description': 'Cultivate compassion for yourself and others',
        'duration': '15 min',
        'color': Colors.pink[100],
        'icon': Icons.favorite,
      },
      {
        'title': 'Mindful Walking',
        'description': 'Practice mindfulness while walking',
        'duration': '10 min',
        'color': Colors.orange[100],
        'icon': Icons.directions_walk,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meditations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate()
          .fadeIn()
          .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        ...meditations.asMap().entries.map((entry) {
          final index = entry.key;
          final meditation = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  // Start meditation
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: meditation['color'] as Color?,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          meditation['icon'] as IconData,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meditation['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meditation['description'] as String,
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
                        label: Text(meditation['duration'] as String),
                        backgroundColor: Colors.white,
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
