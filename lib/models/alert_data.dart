// lib/models/alert_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertData {
  final String id;
  final String title;
  final String description;
  final String type;
  final Timestamp timestamp;

  AlertData({
    this.id = '',
    required this.title,
    required this.description,
    required this.type,
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();

  factory AlertData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertData(
      id: doc.id,
      title: data['title'] as String? ?? 'No Title',
      description: data['description'] as String? ?? 'No Description',
      type: data['type'] as String? ?? 'normal',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'timestamp': timestamp,
    };
  }
}
