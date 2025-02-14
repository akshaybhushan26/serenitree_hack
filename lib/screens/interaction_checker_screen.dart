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
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final List<Map<String, dynamic>> _selectedMedications = [];
  bool _isLoading = false;
  final _drugInteractionService = DrugInteractionService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a medication name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final results = await _drugInteractionService
          .searchDrugs(_searchController.text.trim());
      setState(() {
        _searchResults = results.map((drug) => {'name': drug}).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching medications: ${e.toString()}'),
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

  Future<void> _checkInteractions() async {
    if (_selectedMedications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add medications to check for interactions'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedMedications.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 2 medications to check for interactions'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final drugNames =
          _selectedMedications.map((m) => m['name'] as String).toList();
      final interactions =
          await _drugInteractionService.checkInteractions(drugNames);

      if (!mounted) return;

      context.read<AppState>().clearInteractions();

      if (interactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No interactions found between your medications - it appears safe to take them together'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        for (final interaction in interactions) {
          context.read<AppState>().addInteraction(interaction);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Found ${interactions.length} potential interaction(s). Please review them carefully.'),
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

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      ).animate().fadeIn();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.length < 3
              ? 'Enter at least 3 characters to search'
              : 'No medications found',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ).animate().fadeIn().slideY(begin: 0.2, end: 0);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final drug = _searchResults[index];
        return ListTile(
          title: Text(drug['name'] as String),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _selectedMedications.add({
                  'name': drug['name'],
                  'color': Theme.of(context).colorScheme.primaryContainer,
                });
                _searchResults = [];
                _searchController.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${drug['name']} added to check interactions'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        )
            .animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn()
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildSelectedMedicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedMedications.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Selected Medications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedMedications.asMap().entries.map((entry) {
                final index = entry.key;
                final med = entry.value;
                return Chip(
                  label: Text(med['name'] as String),
                  onDeleted: () => setState(() {
                    _selectedMedications.removeAt(index);
                  }),
                  backgroundColor: med['color'] as Color?,
                )
                    .animate(delay: Duration(milliseconds: 50 * index))
                    .fadeIn()
                    .scale();
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Search and add medications to check for interactions',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        ],
      ],
    );
  }

  Widget _buildInteractionResults(List<Map<String, dynamic>> interactions) {
    if (interactions.isEmpty) {
      return const Center(
        child: Text('No interactions found between selected medications'),
      ).animate().fadeIn().slideY(begin: 0.2, end: 0);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: interactions.length,
      itemBuilder: (context, index) {
        final interaction = interactions[index];
        final severity = interaction['severity'] as String;
        final color = _drugInteractionService.getSeverityColor(severity);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${interaction['drug1']} + ${interaction['drug2']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          color:
                              Color(int.parse(color.substring(1), radix: 16)),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  interaction['description'] as String,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn()
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final interactions = context.watch<AppState>().interactions;

    return Scaffold(
        body: SafeArea(
      child: CustomScrollView(slivers: [
        const SliverAppBar.large(
          title: Text('Drug Interactions'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
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
                      Icons.health_and_safety_outlined,
                      color: Colors.white,
                      size: 48,
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    const Text(
                      'Check Drug Interactions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 8),
                    const Text(
                      'Search and add medications to check for potential interactions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(begin: -0.2, end: 0),
                  ],
                ),
              ).animate().fadeIn().scale(delay: 100.ms),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Medications',
                            hintText: 'Enter drug name (e.g., Aspirin)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          onSubmitted: (_) => _performSearch(),
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _performSearch,
                        icon: const Icon(Icons.search),
                      ).animate().fadeIn().scale(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSelectedMedicationsList(),
                  if (_selectedMedications.length >= 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: FilledButton.icon(
                        onPressed: _checkInteractions,
                        icon: const Icon(Icons.health_and_safety_outlined),
                        label: const Text('Check Interactions'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ).animate().fadeIn().scale(),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ).animate().fadeIn()
                  else if (_searchResults.isNotEmpty && !_isLoading)
                    _buildSearchResults(),
                  if (interactions.isNotEmpty ||
                      _selectedMedications.length >= 2) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Potential Interactions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (interactions.isNotEmpty &&
                              interactions.any((i) =>
                                  i['severity'].toString().toLowerCase() ==
                                  'severe'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.red, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'SEVERE',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          else if (interactions.isEmpty &&
                              _selectedMedications.length >= 2)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'SAFE',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                    if (interactions.isNotEmpty)
                      _buildInteractionResults(interactions),
                  ],
                ],
              ),
            ]),
          ),
        ),
      ]),
    ));
  }
}
