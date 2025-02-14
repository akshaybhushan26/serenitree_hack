import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/add_medication_dialog.dart';
import '../widgets/edit_medication_dialog.dart';
import '../screens/scan_screen.dart';
import '../screens/interaction_checker_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Medications'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.document_scanner),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanScreen()),
                    );
                  },
                  tooltip: 'Scan Prescription',
                ),
                IconButton(
                  icon: const Icon(Icons.compare_arrows),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InteractionCheckerScreen()),
                    );
                  },
                  tooltip: 'Check Interactions',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildNextDoseCard(context),
                  const SizedBox(height: 24),
                  _buildMedicationList(context),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddMedicationDialog(),
          );
        },
        child: const Icon(Icons.add),
      ).animate()
        .scale(delay: 500.ms),
    );
  }

  Widget _buildNextDoseCard(BuildContext context) {
    final medications = context.watch<AppState>().medications;
    if (medications.isEmpty) {
      return const SizedBox.shrink();
    }

    final nextMedication = medications.first; // For simplicity, showing first medication
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
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
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 32,
                ).animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(width: 8),
                const Text(
                  'Next Dose',
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
            Text(
              nextMedication.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ).animate()
              .fadeIn(delay: 200.ms)
              .slideX(begin: -0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              '${nextMedication.dosage} • ${_formatTime(nextMedication.time)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
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

  Widget _buildMedicationList(BuildContext context) {
    final medications = context.watch<AppState>().medications;

    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 64,
              color: Colors.grey,
            ).animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text(
              'No medications added yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ).animate()
              .fadeIn()
              .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add medications',
              style: TextStyle(
                color: Colors.grey,
              ),
            ).animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Medications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate()
          .fadeIn()
          .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        ...medications.map((medication) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Medication'),
                      content: const Text('Are you sure you want to delete this medication?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<AppState>().removeMedication(medication.name);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditMedicationDialog(
                                  medication: medication,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildInfoChip(
                              Icons.medication,
                              medication.dosage,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.calendar_today,
                              medication.frequency,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.access_time,
                              _formatTime(medication.time),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate()
            .fadeIn()
            .slideX(begin: 0.2, end: 0);
        }),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}
