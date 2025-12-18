// lib/widgets/add_activity_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_data.dart';
import '../models/feeding_data.dart';
import '../services/data_service.dart';

enum ActivityType { sleep, feeding }

class AddActivityModal extends StatefulWidget {
  final ActivityType type;
  final String? currentSleepEntryId; // Only for ending an ongoing session
  final SleepData? sleepToEdit; // Pass existing sleep entry for editing
  final FeedingData? feedingToEdit; // Pass existing feeding entry for editing

  const AddActivityModal({
    super.key,
    required this.type,
    this.currentSleepEntryId,
    this.sleepToEdit,
    this.feedingToEdit,
  });

  @override
  State<AddActivityModal> createState() => _AddActivityModalState();
}

class _AddActivityModalState extends State<AddActivityModal> {
  // For Sleep
  late DateTime _sleepStartTime;
  late DateTime _sleepEndTime;
  late TextEditingController _sleepNotesController;

  // For Feeding
  late DateTime _feedingTime;
  late TextEditingController _amountController;
  late TextEditingController _durationController;
  late String _selectedFeedingType;
  String? _selectedSide;

  bool _isSaving = false;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();

    _sleepNotesController = TextEditingController(text: widget.sleepToEdit?.notes ?? '');
    _amountController = TextEditingController(text: widget.feedingToEdit?.amountMl.toString() ?? '');
    _durationController = TextEditingController(text: widget.feedingToEdit?.durationMinutes.toString() ?? '10');

    // Initialize Sleep times
    // If ending an ongoing session, start time is irrelevant, end time is now.
    _sleepStartTime = widget.sleepToEdit?.startTime.toDate() ?? DateTime.now();
    _sleepEndTime = widget.sleepToEdit?.endTime?.toDate() ?? DateTime.now();

    // If starting a NEW ongoing session, we only call this modal from the dashboard with currentSleepEntryId: null
    // If ending an ONGOING session, currentSleepEntryId is NOT null, and we only use _sleepEndTime.
    // If editing HISTORY, sleepToEdit is NOT null, and we use both times.

    // Initialize Feeding details
    _feedingTime = widget.feedingToEdit?.timestamp.toDate() ?? DateTime.now();
    _selectedFeedingType = widget.feedingToEdit?.type ?? 'Bottle';
    _selectedSide = widget.feedingToEdit?.side;
  }

  @override
  void dispose() {
    _sleepNotesController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // --- Date and Time Pickers ---
  Future<void> _selectDateTime(BuildContext context, DateTime initialDate, Function(DateTime) onDateTimeSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      // Allow slightly future time for logging an event that is just starting (e.g. End Sleep Now)
      lastDate: DateTime.now().add(const Duration(minutes: 1)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        // Construct the new DateTime object
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Ensure the callback is called within setState
        setState(() {
          onDateTimeSelected(newDateTime);
        });
      }
    }
  }


  // --- Handlers for saving data ---
  Future<void> _saveSleep() async {
    setState(() => _isSaving = true);
    final dataService = Provider.of<DataService>(context, listen: false);

    try {
      // 1. Logic for Ending an ongoing session (Called from Dashboard when a session is active)
      if (widget.currentSleepEntryId != null) {
        // Validate end time is after the start time (Start time is fetched from the DB inside endSleepEntry)
        // We only pass the end time here.
        await dataService.endSleepEntry(
          widget.currentSleepEntryId!,
          Timestamp.fromDate(_sleepEndTime),
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep session ended!')));

        // 2. Logic for Editing a historical session (Called from History screens)
      } else if (widget.sleepToEdit != null) {
        if (_sleepEndTime.isBefore(_sleepStartTime)) throw Exception("End time cannot be before start time.");

        final updatedSleep = SleepData(
          id: widget.sleepToEdit!.id,
          startTime: Timestamp.fromDate(_sleepStartTime),
          endTime: Timestamp.fromDate(_sleepEndTime),
          notes: _sleepNotesController.text,
        );
        await dataService.updateSleepEntry(updatedSleep);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep session updated!')));

        // 3. Logic for Logging a new historical session (Called from History screens to log a completed nap)
      } else {
        if (_sleepEndTime.isBefore(_sleepStartTime)) throw Exception("End time cannot be before start time.");

        final newSleep = SleepData(
          id: _uuid.v4(),
          startTime: Timestamp.fromDate(_sleepStartTime),
          endTime: Timestamp.fromDate(_sleepEndTime),
          notes: _sleepNotesController.text,
        );
        // Note: For a new log from history, we use the addSleepEntry, which accepts a fully formed SleepData object.
        await dataService.addSleepEntry(newSleep);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep session logged!')));
      }

      Navigator.of(context).pop(true); // Pop with true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveFeeding() async {
    setState(() => _isSaving = true);
    final dataService = Provider.of<DataService>(context, listen: false);

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final int duration = int.tryParse(_durationController.text) ?? 0;

    if (duration <= 0 && amount <= 0 && _selectedFeedingType != 'Breast') {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter duration or amount.')));
      return;
    }

    try {
      final feedingData = FeedingData(
        id: widget.feedingToEdit?.id ?? _uuid.v4(),
        timestamp: Timestamp.fromDate(_feedingTime),
        amountMl: amount,
        type: _selectedFeedingType,
        side: _selectedFeedingType == 'Breast' ? _selectedSide : null,
        durationMinutes: duration,
      );

      if (widget.feedingToEdit != null) {
        // Update existing entry
        await dataService.updateFeedingEntry(feedingData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feeding updated!')));
      } else {
        // Add new entry
        await dataService.addFeedingEntry(feedingData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feeding logged!')));
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging feeding: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Helper to format DateTime for display
  String _formatDateTime(DateTime dt) {
    // A simple, clear format for display in the ListTile subtitle
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.sleepToEdit != null || widget.feedingToEdit != null;
    bool isEndingSleep = widget.currentSleepEntryId != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0, right: 16.0, top: 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.type == ActivityType.sleep
                  ? (isEndingSleep ? 'End Sleep Session' : (isEditing ? 'Edit Sleep' : 'Log Sleep Session'))
                  : (isEditing ? 'Edit Feeding' : 'Log Feeding'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (widget.type == ActivityType.sleep) ...[
              // Sleep Form
              if (!isEndingSleep) // Only show start time for new or historical edits
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(_formatDateTime(_sleepStartTime)),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _selectDateTime(context, _sleepStartTime, (dt) => _sleepStartTime = dt),
                ),
              ListTile(
                title: isEndingSleep ? const Text('End Time (Now)') : const Text('End Time'),
                subtitle: Text(_formatDateTime(_sleepEndTime)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateTime(context, _sleepEndTime, (dt) => _sleepEndTime = dt),
              ),
              TextField(
                controller: _sleepNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (e.g., in crib, short nap)',
                  hintText: 'Optional notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ] else ...[
              // Feeding Form
              ListTile(
                title: const Text('Feeding Time'),
                subtitle: Text(_formatDateTime(_feedingTime)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateTime(context, _feedingTime, (dt) => _feedingTime = dt),
              ),
              DropdownButtonFormField<String>(
                value: _selectedFeedingType,
                decoration: const InputDecoration(labelText: 'Feeding Type', border: OutlineInputBorder()),
                items: ['Bottle', 'Breast', 'Solid']
                    .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFeedingType = newValue!;
                    if (newValue != 'Breast') _selectedSide = null; // Clear side if not breast
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedFeedingType == 'Breast')
                DropdownButtonFormField<String>(
                  value: _selectedSide,
                  decoration: const InputDecoration(labelText: 'Side', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String>(value: 'Left', child: Text('Left')),
                    const DropdownMenuItem<String>(value: 'Right', child: Text('Right')),
                    const DropdownMenuItem<String>(value: null, child: Text('Unknown/Both')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() => _selectedSide = newValue);
                  },
                ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (ml / g)',
                  hintText: _selectedFeedingType == 'Solid' ? 'e.g., 50g' : 'e.g., 120ml',
                  border: const OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  hintText: 'e.g., 15',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 30),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: widget.type == ActivityType.sleep ? _saveSleep : _saveFeeding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEditing ? 'Update Entry' : (isEndingSleep ? 'End Sleep Now' : 'Save Entry')),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}