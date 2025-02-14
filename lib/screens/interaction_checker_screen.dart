import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/drug_interaction_service.dart';

class InteractionCheckerScreen extends StatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  State<InteractionCheckerScreen> createState() => _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  final _drugInteractionService = DrugInteractionService();

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
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
      final results = await _drugInteractionService.searchDrugs(_searchController.text.trim());
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.length < 3 ? 'Enter at least 3 characters to search' : 'No medications found',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final drug = _searchResults[index];
        return ListTile(
          title: Text(drug['name']),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final appState = context.read<AppState>();
              appState.addMedication({
                'name': drug['name'],
                'color': Theme.of(context).colorScheme.primaryContainer,
                'time': '9:00 AM', // Default time
                'added': DateTime.now(),
              });
              setState(() {
                _searchResults = [];
                _searchController.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${drug["name"]} added to check for drug interactions'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInteractionResults(List<Map<String, dynamic>> interactions) {
    if (interactions.isEmpty) {
      return const Center(
        child: Text('No interactions found between selected medications'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: interactions.length,
      itemBuilder: (context, index) {
        final interaction = interactions[index];
        final severity = interaction['severity'];
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          color: Color(int.parse(color.substring(1), radix: 16)),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  interaction['description'],
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkInteractions() async {
    final medications = context.read<AppState>().medications;
    if (medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add medications to check for interactions'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (medications.length < 2) {
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
      final drugNames = medications.map((m) => m['name'] as String).toList();
      final interactions = await _drugInteractionService.checkInteractions(drugNames);

      if (!mounted) return;

      context.read<AppState>().clearInteractions();
      
      if (interactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No interactions found between your medications - it appears safe to take them together'),
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
            content: Text('Found ${interactions.length} potential interaction(s). Please review them carefully.'),
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

  Widget _buildSelectedMedicationsList() {
    final medications = context.watch<AppState>().medications;
    final interactions = context.watch<AppState>().interactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (medications.isNotEmpty) ...[          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Selected Medications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medications.map((med) => Chip(
                label: Text(med['name'] as String),
                onDeleted: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Medication'),
                      content: const Text('Are you sure you want to delete this medication?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    context.read<AppState>().removeMedication(medications.indexOf(med));
                  }
                },
                backgroundColor: med['color'] as Color?,
              )).toList(),
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
          ),
        ],
      ],
    );
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search Medications',
                                hintText: 'Enter drug name (e.g., Aspirin)',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _performSearch(),
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  setState(() {
                                    _searchResults = [];
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _performSearch,
                            icon: const Icon(Icons.search),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSelectedMedicationsList(),
                      if (context.read<AppState>().medications.length >= 2)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _checkInteractions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Check Interactions',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_searchResults.isNotEmpty)
                        _buildSearchResults(),
                      if (context.read<AppState>().medications.length >= 2) ...[                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Potential Interactions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (interactions.any((i) => i['severity']?.toLowerCase() == 'high'))
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_rounded, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'High severity interactions detected',
                                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (interactions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No interactions found between your medications - it appears safe to take them together',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                        else
                          _buildInteractionResults(interactions),
                      ],
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
