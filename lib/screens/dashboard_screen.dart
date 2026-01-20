// lib/screens/dashboard_screen_redesigned.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/baby_data.dart';
import '../models/sleep_data.dart';
import '../models/feeding_data.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../widgets/vital_sign_card.dart';
import '../widgets/add_activity_modal.dart';
import 'package:collection/collection.dart';
import 'feeding_history_screen.dart';
import 'sleep_history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _currentSleepEntryId;

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
      if (mounted) {
        setState(() => _currentSleepEntryId = ongoingSleep.id);
      }
    } else if (ongoingSleep == null && _currentSleepEntryId != null) {
      if (mounted) {
        setState(() => _currentSleepEntryId = null);
      }
    }
  }

  void _startSleep() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    if (_currentSleepEntryId == null) {
      final bool? success = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddActivityModal(type: ActivityType.sleep),
      );
      if (success == true) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _updateOngoingSleepState(dataService);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A sleep session is already ongoing.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _endSleep() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    if (_currentSleepEntryId != null) {
      final bool? success = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddActivityModal(
          type: ActivityType.sleep,
          currentSleepEntryId: _currentSleepEntryId,
        ),
      );
      if (success == true) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _updateOngoingSleepState(dataService);
        });
      }
    }
  }

  void _logFeeding() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddActivityModal(type: ActivityType.feeding),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final dailySleepDuration = dataService.calculateDailySleepDuration();
    final dailyFeedingCount = dataService.calculateDailyFeedingCount();
    final ongoingSleep = dataService.sleepEntries.firstWhereOrNull((s) => s.endTime == null);

    if (ongoingSleep != null && _currentSleepEntryId != ongoingSleep.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentSleepEntryId = ongoingSleep.id);
      });
    } else if (ongoingSleep == null && _currentSleepEntryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentSleepEntryId = null);
      });
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(dataService),
            const SizedBox(height: 24),

            // Real-time Vitals Section
            const Text(
              'Real-time Vitals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildVitalsGrid(dataService),
            const SizedBox(height: 32),

            // Activity Tracking Section
            const Text(
              'Activity Tracking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityCards(
              dailySleepDuration,
              dailyFeedingCount,
              ongoingSleep,
              dataService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(DataService dataService) {
    return StreamBuilder<BabyData?>(
      stream: dataService.babyDataStream,
      initialData: dataService.currentBabyData,
      builder: (context, snapshot) {
        final babyData = snapshot.data ?? dataService.currentBabyData;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink[400]!,
                Colors.purple[400]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Baby is Safe',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFormattedDate(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick Actions Menu
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    offset: const Offset(0, 50),
                    elevation: 8,
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.settings, color: Colors.grey[700], size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.refresh, color: Colors.blue[700], size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Refresh Data',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.logout, color: Colors.red[700], size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final dataService = Provider.of<DataService>(context, listen: false);

                      switch (value) {
                        case 'settings':
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                          break;
                        case 'refresh':
                          dataService.refreshActivityData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Data refreshed successfully!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          break;
                        case 'logout':
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.logout, color: Colors.red[700], size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign Out',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              content: const Text(
                                'Are you sure you want to sign out?',
                                style: TextStyle(fontSize: 15),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[400],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign Out',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            await authService.signOut();
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          }
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildWelcomeStat('💓', 'Heart', babyData != null && babyData.heartRate > 0 ? '${babyData.heartRate} bpm' : '-- bpm'),
                    const SizedBox(width: 24),
                    _buildWelcomeStat('🌡️', 'Temp', babyData != null && babyData.temperature > 0 ? '${babyData.temperature.toStringAsFixed(1)}°C' : '--°C'),
                    const SizedBox(width: 24),
                    _buildWelcomeStat('🫁', 'SpO₂', babyData != null && babyData.oxygenSaturation > 0 ? '${babyData.oxygenSaturation}%' : '--%'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeStat(String emoji, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(DataService dataService) {
    return StreamBuilder<BabyData?>(
      stream: dataService.babyDataStream,
      initialData: dataService.currentBabyData, // Use current data as initial value
      builder: (context, snapshot) {
        // Use snapshot data if available, otherwise fallback to provider's current data
        final babyData = snapshot.data ?? dataService.currentBabyData;

        if (babyData == null || babyData.heartRate == 0) {
          return _buildLoadingVitalsGrid();
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildModernVitalCard(
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                    value: '${babyData.heartRate}',
                    unit: 'bpm',
                    color: _getHeartRateStatus(babyData.heartRate),
                    gradient: [Colors.red[400]!, Colors.pink[300]!],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernVitalCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${babyData.temperature.toStringAsFixed(1)}',
                    unit: '°C',
                    color: _getTemperatureStatus(babyData.temperature),
                    gradient: [Colors.orange[400]!, Colors.amber[300]!],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModernVitalCard(
                    icon: Icons.air,
                    label: 'SpO₂',
                    value: '${babyData.oxygenSaturation}',
                    unit: '%',
                    color: _getSpO2Status(babyData.oxygenSaturation),
                    gradient: [Colors.blue[400]!, Colors.cyan[300]!],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernVitalCard(
                    icon: Icons.directions_run,
                    label: 'Movement',
                    value: babyData.movement,
                    unit: '',
                    color: _getMovementStatus(babyData.movement),
                    gradient: [Colors.green[400]!, Colors.teal[300]!],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernVitalCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  color == Colors.green ? 'Normal' : color == Colors.orange ? 'Warning' : 'Alert',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingVitalsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[400]!),
        ),
      ),
    );
  }

  Widget _buildActivityCards(
      Duration dailySleepDuration,
      int dailyFeedingCount,
      SleepData? ongoingSleep,
      DataService dataService,
      ) {
    return Column(
      children: [
        // Sleep Card
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SleepHistoryScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.indigo[400]!, Colors.indigo[300]!],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
                            'Sleep',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Today: ${dailySleepDuration.inHours}h ${dailySleepDuration.inMinutes.remainder(60)}m',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ongoingSleep != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _currentSleepEntryId == null ? _startSleep : _endSleep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentSleepEntryId == null ? '🛏️  Start Sleep' : '⏰  End Sleep',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Feeding Card
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const FeedingHistoryScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple[400]!, Colors.purple[300]!],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_dining, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Feeding',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Today: $dailyFeedingCount sessions',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logFeeding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '🍼  Log Feeding',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  Color _getSpO2Status(int spo2) {
    if (spo2 < 90) return Colors.red;
    if (spo2 < 92) return Colors.orange;
    return Colors.green;
  }

  Color _getMovementStatus(String movement) {
    switch (movement.toLowerCase()) {
      case 'inactive': return Colors.orange;
      case 'active':
      case 'moderate': return Colors.green;
      default: return Colors.grey;
    }
  }
}