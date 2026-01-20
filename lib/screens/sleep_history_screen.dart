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
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo[400]!, Colors.indigo[300]!],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sleep Log',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Stats Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo[100]!, Colors.indigo[50]!],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo[400]!, Colors.indigo[300]!],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.king_bed, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sleep Tracking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sleepEntries.length} entries logged',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _getTotalSleepToday(sleepEntries),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sleep Entries List
            Expanded(
              child: sleepEntries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sleepEntries.length,
                itemBuilder: (context, index) {
                  final entry = sleepEntries[index];
                  return _buildModernSleepCard(context, entry);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSleepModal(context),
        backgroundColor: Colors.indigo[400],
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Sleep',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.king_bed_outlined,
              size: 80,
              color: Colors.indigo[300],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Sleep Entries',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start tracking sleep patterns\nby tapping the + button',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSleepCard(BuildContext context, SleepData entry) {
    final isOngoing = entry.endTime == null;
    final duration = entry.durationInMinutes;
    final hours = (duration / 60).floor();
    final minutes = duration % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOngoing
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: isOngoing ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOngoing
                    ? [Colors.green[50]!, Colors.white]
                    : [Colors.indigo[50]!, Colors.white],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOngoing
                          ? [Colors.green[400]!, Colors.green[300]!]
                          : [Colors.indigo[400]!, Colors.indigo[300]!],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isOngoing ? Icons.hotel : Icons.king_bed,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isOngoing ? 'Sleeping Now' : 'Sleep Session',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isOngoing ? Colors.green : Colors.black87,
                            ),
                          ),
                          if (isOngoing) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(entry.startTime.toDate()),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${hours}h ${minutes}m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isOngoing ? Colors.green : Colors.indigo,
                      ),
                    ),
                    Text(
                      isOngoing ? 'Ongoing' : 'Duration',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTimeRow(
                  'Start Time',
                  DateFormat('hh:mm a').format(entry.startTime.toDate()),
                  Icons.bedtime,
                  Colors.blue,
                ),
                if (!isOngoing) ...[
                  const SizedBox(height: 12),
                  _buildTimeRow(
                    'End Time',
                    DateFormat('hh:mm a').format(entry.endTime!.toDate()),
                    Icons.wb_sunny,
                    Colors.orange,
                  ),
                ],
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.notes,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isOngoing) {
                        _showEndSleepModal(context, entry.id);
                      } else {
                        _showEditSleepModal(context, entry);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOngoing ? Colors.orange[400] : Colors.indigo[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isOngoing ? '⏰  End Sleep' : '✏️  Edit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getTotalSleepToday(List<SleepData> entries) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    int totalMinutes = 0;

    for (var entry in entries) {
      if (entry.startTime.toDate().isAfter(startOfToday)) {
        totalMinutes += entry.durationInMinutes;
      }
    }

    final hours = (totalMinutes / 60).floor();
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  void _showLogSleepModal(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddActivityModal(type: ActivityType.sleep),
    );
  }

  void _showEndSleepModal(BuildContext context, String sleepId) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddActivityModal(type: ActivityType.sleep, currentSleepEntryId: sleepId),
    );
  }

  void _showEditSleepModal(BuildContext context, SleepData sleep) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddActivityModal(type: ActivityType.sleep, sleepToEdit: sleep),
    );
  }
}