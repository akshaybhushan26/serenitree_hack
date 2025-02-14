import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  String _timeRange = '7d';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
        centerTitle: true,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final moodTrend = appState.getMoodTrend();
          if (moodTrend.isEmpty) {
            return const Center(
              child: Text('No mood data available yet'),
            );
          }

          final spots = moodTrend.asMap().entries.map((entry) {
            final mood = entry.value;
            return FlSpot(
              entry.key.toDouble(),
              mood.moodLevel / 100, // Convert to 0-1 range
            );
          }).toList();

          final averageMood = spots.isEmpty
              ? 0.0
              : spots.map((spot) => spot.y).reduce((a, b) => a + b) /
                  spots.length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average Mood',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.mood,
                              color: _getMoodColor(averageMood),
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getMoodText(averageMood),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mood Trend',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: '7d',
                                  label: Text('7D'),
                                ),
                                ButtonSegment(
                                  value: '30d',
                                  label: Text('30D'),
                                ),
                                ButtonSegment(
                                  value: 'all',
                                  label: Text('All'),
                                ),
                              ],
                              selected: {_timeRange},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _timeRange = newSelection.first;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      String text = '';
                                      if (value == 0) {
                                        text = 'Very Sad';
                                      } else if (value == 0.5) text = 'Neutral';
                                      else if (value == 1) text = 'Very Happy';
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          text,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                    reservedSize: 60,
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 2 == 0 && value < spots.length) {
                                        final entry = moodTrend[value.toInt()];
                                        final date = entry.timestamp;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${date.month}/${date.day}',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              minX: 0,
                              maxX: (spots.length - 1).toDouble(),
                              minY: 0,
                              maxY: 1,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
