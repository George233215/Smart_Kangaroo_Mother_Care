// lib/screens/feeding_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/feeding_data.dart';
import '../services/data_service.dart';
import '../widgets/add_activity_modal.dart';

class FeedingHistoryScreen extends StatelessWidget {
  const FeedingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final feedingEntries = dataService.feedingEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feeding History',
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
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
        child: feedingEntries.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_dining_outlined, size: 80, color: Colors.pink[200]),
              const SizedBox(height: 16),
              const Text(
                'No feeding entries logged',
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
          itemCount: feedingEntries.length,
          itemBuilder: (context, index) {
            final entry = feedingEntries[index];

            String details = '${entry.type}';
            if (entry.side != null) details += ' (${entry.side})';
            if (entry.amountMl > 0) details += ' - ${entry.amountMl.toStringAsFixed(0)} ml/g';
            if (entry.durationMinutes > 0) details += ' - ${entry.durationMinutes} min';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      colors: [Colors.purple[300]!, Colors.purple[200]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_dining, color: Colors.white, size: 24),
                ),
                title: Text(
                  details,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    DateFormat('MMM d, hh:mm a').format(entry.timestamp.toDate()),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: Colors.pink[400], size: 20),
                ),
                onTap: () => _showEditFeedingModal(context, entry),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogFeedingModal(context),
        backgroundColor: Colors.purple[400],
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showLogFeedingModal(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddActivityModal(type: ActivityType.feeding),
    );
  }

  void _showEditFeedingModal(BuildContext context, FeedingData feeding) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddActivityModal(type: ActivityType.feeding, feedingToEdit: feeding),
    );
  }
}
