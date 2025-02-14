import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class MoodTrendGraph extends StatelessWidget {
  const MoodTrendGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
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

        return SizedBox(
          height: 200,
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
                      return Text(text, style: const TextStyle(fontSize: 10));
                    },
                    interval: 0.5,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= moodTrend.length) return const Text('');
                      final entry = moodTrend[value.toInt()];
                      final date = entry.timestamp;
                      return Text(
                        '${date.month}/${date.day}\n${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: (moodTrend.length - 1).toDouble(),
              minY: 0,
              maxY: 1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
