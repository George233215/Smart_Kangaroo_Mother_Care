// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '../models/baby_data.dart';
import '../models/sleep_data.dart';
import '../models/feeding_data.dart';
import '../services/data_service.dart';
import '../widgets/vital_sign_card.dart';
import '../widgets/add_activity_modal.dart';
import 'package:collection/collection.dart';

// NEW IMPORTS: Navigation targets
import 'feeding_history_screen.dart';
import 'sleep_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _currentSleepEntryId; // To track an ongoing sleep session

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataService = Provider.of<DataService>(context, listen: false);
      dataService.refreshActivityData();
      _updateOngoingSleepState(dataService);
    });
  }

  void _updateOngoingSleepState(DataService dataService) {
    final ongoingSleep = dataService.sleepEntries.firstWhereOrNull((s) => s.endTime == null);

    if (ongoingSleep != null && _currentSleepEntryId == null) {
      if(mounted) {
        setState(() {
          _currentSleepEntryId = ongoingSleep.id;
        });
      }
    } else if (ongoingSleep == null && _currentSleepEntryId != null) {
      if(mounted) {
        setState(() {
          _currentSleepEntryId = null;
        });
      }
    }
  }

  // =========================================================
  // Activity Control Handlers
  // =========================================================

  // Function to handle starting a sleep session (opens modal)
  void _startSleep() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    if (_currentSleepEntryId == null) {
      final bool? success = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const AddActivityModal(type: ActivityType.sleep),
      );

      if (success == true) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _updateOngoingSleepState(dataService);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A sleep session is already ongoing. Tap "End Sleep" to log it.')),
      );
    }
  }

  // Function to handle ending a sleep session (opens modal)
  void _endSleep() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    if (_currentSleepEntryId != null) {
      final bool? success = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => AddActivityModal(
          type: ActivityType.sleep,
          currentSleepEntryId: _currentSleepEntryId, // Pass the ID of the ongoing session
        ),
      );

      if (success == true) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _updateOngoingSleepState(dataService);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ongoing sleep session to end.')),
      );
    }
  }

  // Function to handle logging a feeding event (opens modal)
  void _logFeeding() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddActivityModal(type: ActivityType.feeding),
    );
  }

  // =========================================================
  // NEW: Navigation Handlers
  // =========================================================
  void _navigateToSleepHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SleepHistoryScreen()),
    );
  }

  void _navigateToFeedingHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FeedingHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch DataService to get updated sleep/feeding summaries and user ID
    final dataService = Provider.of<DataService>(context);
    final String userId = dataService.userId;

    // Calculate daily sleep duration and feeding count
    final dailySleepDuration = dataService.calculateDailySleepDuration();
    final dailyFeedingCount = dataService.calculateDailyFeedingCount();

    // Correctly find the ongoing sleep using the 'collection' package's firstWhereOrNull
    final ongoingSleep = dataService.sleepEntries.firstWhereOrNull((s) => s.endTime == null);

    // Sync local state (_currentSleepEntryId) with the current data state (ongoingSleep)
    if (ongoingSleep != null && _currentSleepEntryId != ongoingSleep.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          setState(() {
            _currentSleepEntryId = ongoingSleep.id;
          });
        }
      });
    } else if (ongoingSleep == null && _currentSleepEntryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          setState(() {
            _currentSleepEntryId = null;
          });
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.pink[50]!, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[400]!, Colors.pink[300]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back! 💕',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFormattedDate(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            StreamBuilder<BabyData?>(
              stream: dataService.babyDataStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.pink[400]),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final babyData = snapshot.data ?? BabyData(heartRate: 0, temperature: 0.0, movement: 'Inactive', oxygenSaturation: 0);

                return Column(
                  children: [
                    VitalSignCard(
                      title: 'Heart Rate',
                      value: '${babyData.heartRate}',
                      unit: 'BPM',
                      status: _getHeartRateStatus(babyData.heartRate),
                      icon: Icons.favorite,
                      iconColor: Colors.pink[400]!,
                      normalRange: 'Normal Range: 100-160 BPM',
                    ),
                    VitalSignCard(
                      title: 'Temperature',
                      value: '${babyData.temperature.toStringAsFixed(1)}',
                      unit: '°C',
                      status: _getTemperatureStatus(babyData.temperature),
                      icon: Icons.thermostat,
                      iconColor: Colors.pink[300]!,
                      normalRange: 'Normal Range: 36.5-37.5 °C',
                    ),
                    VitalSignCard(
                      title: 'O₂ Saturation',
                      value: '${babyData.oxygenSaturation}',
                      unit: '%',
                      status: _getSpO2Status(babyData.oxygenSaturation),
                      icon: Icons.bloodtype,
                      iconColor: Colors.pinkAccent,
                      normalRange: 'Normal Range: 95-100 %',
                    ),
                    VitalSignCard(
                      title: 'Activity Level',
                      value: babyData.movement,
                      unit: '',
                      status: _getMovementStatus(babyData.movement),
                      icon: Icons.directions_run,
                      iconColor: Colors.pink[200]!,
                      normalRange: 'Movement: Active, Moderate, Inactive',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            const Text(
              'Today\'s Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToSleepHistory,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.pink[100]!, Colors.pink[50]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.king_bed, color: Colors.pink[400], size: 32),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sleep',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.pink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dailySleepDuration.inHours}h ${dailySleepDuration.inMinutes.remainder(60)}m',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ongoingSleep != null
                                  ? '🟢 Ongoing'
                                  : 'Last: ${_getFormattedTimeAgo(dataService.sleepEntries.isNotEmpty ? dataService.sleepEntries.first.endTime?.toDate() ?? dataService.sleepEntries.first.startTime.toDate() : null)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _currentSleepEntryId == null ? _startSleep : _endSleep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentSleepEntryId == null ? Colors.pink[400] : Colors.pink[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _currentSleepEntryId == null ? 'Log Sleep' : 'End Sleep',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToFeedingHistory,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.purple[100]!, Colors.purple[50]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.local_dining, color: Colors.purple[400], size: 32),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Feedings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dailyFeedingCount times',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last: ${_getFormattedTimeAgo(dataService.feedingEntries.isNotEmpty ? dataService.feedingEntries.first.timestamp.toDate() : null)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _logFeeding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[400],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Log Feeding',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Utility Methods ---

  String _getFormattedDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${_getWeekdayName(date.weekday)}, ${date.day} ${months[date.month - 1]}';
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return '';
    }
  }

  String _getFormattedTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }

  // --- Status Color Methods ---

  Color _getHeartRateStatus(int hr) {
    if (hr < 100 || hr > 160) return Colors.red;
    if (hr < 110 || hr > 150) return Colors.orange;
    return Colors.green;
  }

  Color _getTemperatureStatus(double temp) {
    if (temp < 36.0 || temp > 38.0) return Colors.red;
    if (temp < 36.5 || temp > 37.5) return Colors.orange;
    return Colors.green;
  }

  // SpO2 Status Color
  Color _getSpO2Status(int spo2) {
    if (spo2 < 90) return Colors.red;
    if (spo2 < 92) return Colors.orange;
    return Colors.green;
  }

  Color _getMovementStatus(String movement) {
    switch (movement.toLowerCase()) {
      case 'inactive':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'moderate':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
