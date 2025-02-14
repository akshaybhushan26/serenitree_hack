import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class EditMedicationDialog extends StatefulWidget {
  final int index;
  final Map<String, dynamic> medication;

  const EditMedicationDialog({
    super.key,
    required this.index,
    required this.medication,
  });

  @override
  State<EditMedicationDialog> createState() => _EditMedicationDialogState();
}

class _EditMedicationDialogState extends State<EditMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late String _frequency;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication['name'] as String);
    _dosageController = TextEditingController(text: widget.medication['dosage'] as String);
    _frequency = widget.medication['frequency'] as String;

    final timeStr = widget.medication['time'] as String;
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minuteParts = parts[1].split(' ');
    final minute = int.parse(minuteParts[0]);
    final period = minuteParts[1];
    
    _time = TimeOfDay(
      hour: period == 'PM' && hour != 12
          ? hour + 12
          : period == 'AM' && hour == 12
              ? 0
              : hour,
      minute: minute,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final medication = {
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'frequency': _frequency,
        'time': _formatTime(_time),
        'color': widget.medication['color'],
        'added': widget.medication['added'], // Preserve the original timestamp
      };

      context.read<AppState>().updateMedication(widget.index, medication);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Medication'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'As needed', child: Text('As needed')),
                ],
                onChanged: (value) {
                  setState(() {
                    _frequency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(_formatTime(_time)),
                trailing: const Icon(Icons.access_time),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                onTap: _selectTime,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
