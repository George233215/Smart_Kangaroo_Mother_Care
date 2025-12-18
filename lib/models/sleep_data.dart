// lib/models/sleep_data.dart (Finalized for SQLite)

import 'package:cloud_firestore/cloud_firestore.dart';

class SleepData {
  final String id; // Mandatory for SQLite Primary Key
  final Timestamp startTime;
  final Timestamp? endTime;
  final String notes; // Added for editable history

  SleepData({
    required this.id, // Mandatory
    required this.startTime,
    this.endTime,
    this.notes = '', // Default to empty string
  });

  // Helper to calculate duration in minutes
  int get durationInMinutes {
    final end = endTime?.toDate() ?? DateTime.now();
    return end.difference(startTime.toDate()).inMinutes;
  }

  // --- SQLite Mapping Methods ---

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'notes': notes, // Include notes
    };
  }

  factory SleepData.fromSqliteMap(Map<String, dynamic> map) {
    return SleepData(
      id: map['id'] as String,
      startTime: Timestamp.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: (map['endTime'] != null)
          ? Timestamp.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
      notes: map['notes'] as String? ?? '',
    );
  }


}