// lib/screens/sleep_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/sleep_data.dart';
import '../services/data_service.dart';
import '../widgets/add_activity_modal.dart';

class SleepHistoryScreen extends StatelessWidget {
  const SleepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final sleepEntries = dataService.sleepEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sleep History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink[400]!, Colors.pink[300]!],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[50]!, Colors.white],
          ),
        ),
        child: sleepEntries.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.king_bed_outlined, size: 80, color: Colors.pink[200]),
              const SizedBox(height: 16),
              const Text(
                'No sleep entries logged',
                style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap + to add your first entry',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sleepEntries.length,
          itemBuilder: (context, index) {
            final entry = sleepEntries[index];
            final isOngoing = entry.endTime == null;
            final duration = entry.durationInMinutes;
            final durationText = isOngoing
                ? 'Ongoing (${(duration / 60).floor()}h ${duration % 60}m)'
                : '${(duration / 60).floor()}h ${duration % 60}m';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isOngoing ? Border.all(color: Colors.green, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOngoing
                          ? [Colors.green[300]!, Colors.green[200]!]
                          : [Colors.pink[300]!, Colors.pink[200]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOngoing ? Icons.hotel : Icons.king_bed,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      isOngoing ? 'Sleeping Now' : 'Slept',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isOngoing ? Colors.green : Colors.black,
                      ),
                    ),
                    if (isOngoing) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start: ${DateFormat('MMM d, hh:mm a').format(entry.startTime.toDate())}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      if (!isOngoing)
                        Text(
                          'End: ${DateFormat('MMM d, hh:mm a').format(entry.endTime!.toDate())}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      if (entry.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Notes: ${entry.notes}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOngoing ? Colors.green[50] : Colors.pink[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        durationText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOngoing ? Colors.green : Colors.pink,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (isOngoing) {
                    _showEndSleepModal(context, entry.id);
                  } else {
                    _showEditSleepModal(context, entry);
                  }
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogSleepModal(context),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showLogSleepModal(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddActivityModal(type: ActivityType.sleep),
    );
  }

  void _showEndSleepModal(BuildContext context, String sleepId) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddActivityModal(type: ActivityType.sleep, currentSleepEntryId: sleepId),
    );
  }

  void _showEditSleepModal(BuildContext context, SleepData sleep) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddActivityModal(type: ActivityType.sleep, sleepToEdit: sleep),
    );
  }
}
