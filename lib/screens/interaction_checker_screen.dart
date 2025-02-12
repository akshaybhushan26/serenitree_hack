import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/drug_interaction_service.dart';

class InteractionCheckerScreen extends StatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  State<InteractionCheckerScreen> createState() =>
      _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen> {
  Widget _buildSeverityInfo(String level, String description, String color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final _searchController = TextEditingController();
  final _drugInteractionService = DrugInteractionService();
  List<String> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchDrugs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    if (query.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _drugInteractionService.searchDrugs(query);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Only show "no results" message if the query is long enough
      if (results.isEmpty && query.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No medications found matching "$query"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _searchResults = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching medications: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _checkInteractions() async {
    final medications = context.read<AppState>().medications;
    if (medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add medications to check for interactions'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (medications.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 2 medications to check for interactions'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final drugNames = medications.map((m) => m['name'] as String).toList();
      final interactions =
          await _drugInteractionService.checkInteractions(drugNames);

      if (!mounted) return;

      context.read<AppState>().clearInteractions();
      if (interactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No interactions found between your medications'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        for (final interaction in interactions) {
          context.read<AppState>().addInteraction(interaction);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Found ${interactions.length} potential interaction(s)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking interactions: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactions = context.watch<AppState>().interactions;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text('Drug Interactions'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Medications',
                          hintText: 'Enter drug name (e.g., Aspirin)',
                          border: const OutlineInputBorder(),
                          suffixIcon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                )
                              : const Icon(Icons.search),
                        ),
                        onChanged: _searchDrugs,
                      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                      if (_searchController.text.isNotEmpty &&
                          _searchController.text.length < 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Enter at least 3 characters to search',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final drug = _searchResults[index];
                          return GestureDetector(
                            onTap: () {
                              context.read<AppState>().addMedication({
                                'name': drug,
                                'dosage': '1 tablet',
                                'frequency': 'Daily',
                                'time': '8:00 AM',
                                'color': Colors.blue[100],
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added $drug to medications'),
                                  action: SnackBarAction(
                                    label: 'Check Interactions',
                                    onPressed: _checkInteractions,
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: _drugInteractionService.getDrugInfo(drug),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return ListTile(
                                    title: Text(drug),
                                    subtitle: Text(
                                      'Error loading drug information',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return ListTile(
                                    title: Text(drug),
                                    trailing: const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final drugInfo = snapshot.data ?? {};
                                return ListTile(
                                  title: Text(drug),
                                  subtitle: drugInfo.isNotEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${drugInfo['generic_name']} • ${drugInfo['route']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            if (drugInfo['warnings'] != 'N/A')
                                              Text(
                                                'Warning: ${drugInfo['warnings']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        )
                                      : Text(
                                          'No detailed information available',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                  trailing: drugInfo.isNotEmpty
                                      ? Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 120),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Chip(
                                                  label: Text(
                                                    drugInfo['brand_name']
                                                        as String,
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .surfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.add),
                                            ],
                                          ),
                                        )
                                      : const Icon(Icons.add),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _checkInteractions,
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('Check Interactions'),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  if (interactions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Potential Interactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Severity Levels'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSeverityInfo(
                                      'High',
                                      'Potentially dangerous. Avoid combination.',
                                      _drugInteractionService
                                          .getSeverityColor('high'),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSeverityInfo(
                                      'Medium',
                                      'Monitor for side effects. Adjust if needed.',
                                      _drugInteractionService
                                          .getSeverityColor('medium'),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSeverityInfo(
                                      'Low',
                                      'Minor interaction. Monitor as usual.',
                                      _drugInteractionService
                                          .getSeverityColor('low'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...interactions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final interaction = entry.value;
                      final severity = interaction['severity'] as String;
                      final color =
                          _drugInteractionService.getSeverityColor(severity);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Color(
                                    int.parse(color.substring(1), radix: 16) +
                                        0xFF000000),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${interaction['drug1']} + ${interaction['drug2']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Chip(
                                    label: Text(
                                      severity.toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Color(
                                      int.parse(color.substring(1), radix: 16) +
                                          0xFF000000,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                interaction['description'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: Duration(milliseconds: 100 * index))
                          .fadeIn()
                          .slideX(begin: 0.2, end: 0);
                    }),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
