// lib/models/feeding_data.dart (Finalized for SQLite)

import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingData {
  final String id;
  final Timestamp timestamp;
  final String type; // e.g., 'Breast', 'Formula', 'Solid'
  final String? side; // 'Left', 'Right', or null for non-breastfeeding
  final int durationMinutes;
  final double amountMl;

  FeedingData({
    required this.id,
    required this.timestamp,
    required this.type,
    this.side, // Optional side
    required this.durationMinutes,
    required this.amountMl,
  });

  // --- SQLite Mapping Methods ---

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'side': side, // Include side
      'durationMinutes': durationMinutes,
      'amountMl': amountMl,
    };
  }

  factory FeedingData.fromSqliteMap(Map<String, dynamic> map) {
    return FeedingData(
      id: map['id'] as String,
      timestamp: Timestamp.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      type: map['type'] as String? ?? '',
      side: map['side'] as String?,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      amountMl: (map['amountMl'] as num?)?.toDouble() ?? 0.0,
    );
  }
}