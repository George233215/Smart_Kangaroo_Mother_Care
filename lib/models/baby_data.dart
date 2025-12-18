// lib/models/baby_data.dart (Verified and Correct)

import 'package:cloud_firestore/cloud_firestore.dart';

class BabyData {
  final String id;
  final int heartRate;
  final double temperature;
  final String movement;
  final int oxygenSaturation;
  final Timestamp timestamp;

  BabyData({
    this.id = '',
    required this.heartRate,
    required this.temperature,
    required this.movement,
    required this.oxygenSaturation,
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();

  factory BabyData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BabyData(
      id: doc.id,
      heartRate: data['heartRate'] as int? ?? 0,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      movement: data['movement'] as String? ?? 'Inactive',
      // This line handles null data from Firestore by defaulting to 0, which is correct.
      oxygenSaturation: data['oxygenSaturation'] as int? ?? 0,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'heartRate': heartRate,
      'temperature': temperature,
      'movement': movement,
      'oxygenSaturation': oxygenSaturation,
      'timestamp': timestamp,
    };
  }
}