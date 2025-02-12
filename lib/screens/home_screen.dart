import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text('SereniTree'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeCard(context),
                  const SizedBox(height: 24),
                  _buildFeatureGrid(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 48,
          ).animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          const Text(
            'Welcome to SereniTree',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate()
            .fadeIn()
            .slideX(begin: -0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
            'Your personal medication assistant',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ).animate()
            .fadeIn(delay: 200.ms)
            .slideX(begin: -0.2, end: 0),
        ],
      ),
    ).animate()
      .fadeIn()
      .scale(delay: 100.ms);
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'icon': Icons.medication,
        'title': 'Medication Tracking',
        'description': 'Keep track of your medications',
        'color': Colors.blue,
      },
      {
        'icon': Icons.psychology,
        'title': 'Therapy',
        'description': 'Access therapeutic exercises and resources',
        'color': Colors.purple,
      },
      {
        'icon': Icons.self_improvement,
        'title': 'Meditation',
        'description': 'Practice mindfulness and meditation',
        'color': Colors.orange,
      },
      {
        'icon': Icons.document_scanner,
        'title': 'Prescription Scanner',
        'description': 'Scan and analyze your prescriptions',
        'color': Colors.green,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: (constraints.maxWidth / 2 - 24) / ((constraints.maxWidth / 2 - 24) * 1.2),
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  final screenIndex = {
                    'Medication Tracking': 1,
                    'Therapy': 2,
                    'Meditation': 3,
                    'Prescription Scanner': 5,
                  }[feature['title']];
                  
                  if (screenIndex != null) {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return FadeTransition(
                            opacity: animation,
                            child: MainScreen(initialIndex: screenIndex),
                          );
                        },
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        feature['icon'] as IconData,
                        size: 48,
                        color: feature['color'] as Color,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn()
              .scale();
          },
        );
      },
    );
  }
}
