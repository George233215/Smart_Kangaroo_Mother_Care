// lib/services/data_service.dart (UPDATED with handleBluetoothVitals)
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart'; // Retained for logging activities
import 'package:firebase_database/firebase_database.dart'; // For real-time vitals
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // REQUIRED: For firstWhereOrNull
import '../models/baby_data.dart';
import '../models/alert_data.dart';
import '../models/sleep_data.dart';
import '../models/feeding_data.dart';
import 'local_db_service.dart'; // NEW: Import the local database service

// Extension for simple list averaging (needed for pattern check)
extension on Iterable<num> {
  double get average => isEmpty ? 0.0 : sum / length;
  num get sum => fold(0, (a, b) => a + b);
}

// Global variable for app ID from Canvas environment
// ignore_for_file: non_constant_identifier_names
final String __app_id = 'default-app-id'; // This will be provided by the environment
// ignore_for_file: non_constant_identifier_names

class DataService with ChangeNotifier {
  // Database Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final LocalDbService _localDbService = LocalDbService(); // NEW: Local SQLite DB service

  final String _userId;
  String get userId => _userId;

  // Subscriptions
  StreamSubscription? _vitalsDataSubscription;
  StreamSubscription? _alertsSubscription;

  BabyData? _currentBabyData;
  List<AlertData> _alerts = [];
  List<SleepData> _sleepEntries = [];
  List<FeedingData> _feedingEntries = [];

  BabyData? get currentBabyData => _currentBabyData;
  List<AlertData> get alerts => _alerts;
  List<SleepData> get sleepEntries => _sleepEntries;
  List<FeedingData> get feedingEntries => _feedingEntries;

  // Streams for UI to listen to
  StreamController<BabyData?> _babyDataController = StreamController<BabyData?>.broadcast();
  Stream<BabyData?> get babyDataStream => _babyDataController.stream;

  StreamController<List<AlertData>> _alertsController = StreamController<List<AlertData>>.broadcast();
  Stream<List<AlertData>> get alertsStream => _alertsController.stream;

  StreamController<List<SleepData>> _sleepDataController = StreamController<List<SleepData>>.broadcast();
  Stream<List<SleepData>> get sleepDataStream => _sleepDataController.stream;

  StreamController<List<FeedingData>> _feedingDataController = StreamController<List<FeedingData>>.broadcast();
  Stream<List<FeedingData>> get feedingDataStream => _feedingDataController.stream;

  // Helper to safely check if the current user ID is valid for Firestore
  bool get _isUserIdValid => _userId.isNotEmpty && _userId != 'placeholder';

  // Timer for the daily AI pattern check
  Timer? _dailyPatternCheckTimer;

  DataService(this._userId) {
    // Initialize with default data (including SpO2 default)
    _currentBabyData = BabyData(
      heartRate: 0,
      temperature: 0.0,
      movement: 'Inactive',
      oxygenSaturation: 0, // NEW default
    );
    _babyDataController.add(_currentBabyData);
    _alertsController.add([]);
    _sleepDataController.add([]);
    _feedingDataController.add([]);

    // Start listeners
    listenToBabyData(); // Uses RTDB

    if (_isUserIdValid) {
      listenToAlerts(); // Firestore
      refreshActivityData(); // Load local SQLite data
      startMockDataGeneration(); // Firestore Logging

      // Start the daily AI pattern check timer
      _startDailyPatternCheck();
    } else {
      print("DataService initialized with placeholder ID. Deferring services.");
    }
  }

  // === RTDB Vitals Path ===
  DatabaseReference _vitalsRef() {
    return _database.ref('vitals');
  }

  // === Firestore Collection Paths (Safeguarded - Only for Alerts and Vitals Log) ===

  CollectionReference<Map<String, dynamic>> _babyDataCollection() {
    final appId = __app_id.isNotEmpty ? __app_id : 'default-app-id';
    if (!_isUserIdValid) {
      return _firestore.collection('DUMMY_SAFE_PATH').doc('DUMMY').collection('baby_data');
    }
    return _firestore.collection('artifacts').doc(appId).collection('users').doc(_userId).collection('baby_data');
  }

  CollectionReference<Map<String, dynamic>> _alertsCollection() {
    final appId = __app_id.isNotEmpty ? __app_id : 'default-app-id';
    if (!_isUserIdValid) {
      return _firestore.collection('DUMMY_SAFE_PATH').doc('DUMMY').collection('alerts');
    }
    return _firestore.collection('artifacts').doc(appId).collection('users').doc(_userId).collection('alerts');
  }

  // =========================================================
  // CORE: RTDB and SpO2 Monitoring
  // =========================================================
  void listenToBabyData() {
    _vitalsDataSubscription?.cancel();
    _vitalsDataSubscription = _vitalsRef().onValue.listen((event) {
      final data = event.snapshot.value as Map?;

      if (data != null && data.isNotEmpty) {
        // Map RTDB data (Map<dynamic, dynamic>) to BabyData object
        final heartRate = (data['heartRate'] as num?)?.toInt() ?? 0;
        final temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
        final oxygenSaturation = (data['oxygenSaturation'] as num?)?.toInt() ?? 0;

        // RTDB data is missing 'movement', so we estimate it based on HR/Temp or use a default.
        String movement = 'Inactive';
        if (heartRate > 120 && heartRate < 160) {
          movement = 'Active';
        } else if (heartRate > 100) {
          movement = 'Moderate';
        }

        _currentBabyData = BabyData(
          heartRate: heartRate,
          temperature: double.parse(temperature.toStringAsFixed(1)),
          movement: movement,
          oxygenSaturation: oxygenSaturation,
        );
        _babyDataController.add(_currentBabyData);
        notifyListeners();

        _generateAlertsFromVitals(_currentBabyData!);
      } else {
        _currentBabyData = BabyData(heartRate: 0, temperature: 0.0, movement: 'Inactive', oxygenSaturation: 0);
        _babyDataController.add(_currentBabyData);
        notifyListeners();
      }
    }, onError: (error) {
      print("Error listening to RTDB vitals data: $error");
      _babyDataController.addError(error);
    });
  }

  void _generateAlertsFromVitals(BabyData data) {
    if (!_isUserIdValid) return;

    // Heart Rate and Temperature Alerts (Existing logic)
    if (data.heartRate < 100 && data.heartRate > 0) {
      addAlert(AlertData(title: 'Critical Warning: Low Heart Rate', description: 'Baby\'s HR dropped to ${data.heartRate} BPM.', type: 'critical'));
    } else if (data.heartRate > 160) {
      addAlert(AlertData(title: 'Critical Warning: High Heart Rate', description: 'Baby\'s HR increased to ${data.heartRate} BPM.', type: 'critical'));
    }
    if (data.temperature < 36.5 && data.temperature > 0.0) {
      addAlert(AlertData(title: 'Minor Concern: Low Temperature', description: 'Baby\'s temp is ${data.temperature.toStringAsFixed(1)} °C.', type: 'minor'));
    } else if (data.temperature > 37.5) {
      addAlert(AlertData(title: 'Minor Concern: High Temperature', description: 'Baby\'s temp is ${data.temperature.toStringAsFixed(1)} °C.', type: 'minor'));
    }

    // NEW: SpO2 Alert Logic
    const int SPO2_CRITICAL_THRESHOLD = 90;
    const int SPO2_CONCERN_THRESHOLD = 92;

    if (data.oxygenSaturation > 0 && data.oxygenSaturation <= SPO2_CRITICAL_THRESHOLD) {
      addAlert(AlertData(
        title: 'CRITICAL: Very Low Oxygen Saturation',
        description: 'Baby\'s SpO2 is ${data.oxygenSaturation}%. Immediate attention required.',
        type: 'critical',
      ));
    } else if (data.oxygenSaturation > SPO2_CRITICAL_THRESHOLD && data.oxygenSaturation < SPO2_CONCERN_THRESHOLD) {
      addAlert(AlertData(
        title: 'Warning: Low Oxygen Saturation',
        description: 'Baby\'s SpO2 is ${data.oxygenSaturation}%. Monitor closely.',
        type: 'minor',
      ));
    }
  }

  // =========================================================
  // CORE: SQLite Activity Log Management
  // =========================================================

  Future<void> refreshActivityData() async {
    if (!_isUserIdValid) return;

    _sleepEntries = await _localDbService.getSleepEntries(days: 7);
    _feedingEntries = await _localDbService.getFeedingEntries(days: 7);

    _sleepDataController.add(_sleepEntries);
    _feedingDataController.add(_feedingEntries);
    notifyListeners();
  }

  // Add a new sleep entry
  Future<void> addSleepEntry(SleepData sleep) async {
    if (!_isUserIdValid) return;
    try {
      await _localDbService.insertSleep(sleep);
      await refreshActivityData();
    } catch (e) {
      print("Error adding sleep entry to SQLite: $e");
    }
  }

  // Update an existing sleep entry
  Future<void> updateSleepEntry(SleepData sleep) async {
    if (!_isUserIdValid) return;
    try {
      await _localDbService.updateSleep(sleep);
      await refreshActivityData();
    } catch (e) {
      print("Error updating sleep entry in SQLite: $e");
    }
  }

  // Update an existing sleep entry to set endTime (Convenience wrapper)
  Future<void> endSleepEntry(String sleepId, Timestamp endTime) async {
    if (!_isUserIdValid) return;
    try {
      final sleepToUpdate = _sleepEntries.firstWhereOrNull((s) => s.id == sleepId);
      if (sleepToUpdate == null) return;

      final updatedSleep = SleepData(
        id: sleepToUpdate.id,
        startTime: sleepToUpdate.startTime,
        endTime: endTime,
        notes: sleepToUpdate.notes,
      );
      await updateSleepEntry(updatedSleep);
    } catch (e) {
      print("Error ending sleep entry in SQLite: $e");
    }
  }

  // Add a new feeding entry
  Future<void> addFeedingEntry(FeedingData feeding) async {
    if (!_isUserIdValid) return;
    try {
      await _localDbService.insertFeeding(feeding);
      await refreshActivityData();
    } catch (e) {
      print("Error adding feeding entry to SQLite: $e");
    }
  }

  // Update an existing feeding entry
  Future<void> updateFeedingEntry(FeedingData feeding) async {
    if (!_isUserIdValid) return;
    try {
      await _localDbService.updateFeeding(feeding);
      await refreshActivityData();
    } catch (e) {
      print("Error updating feeding entry in SQLite: $e");
    }
  }


  // =========================================================
  // CORE: AI Pattern Anomaly Detection
  // =========================================================
  void _startDailyPatternCheck() {
    _dailyPatternCheckTimer?.cancel();

    checkActivityPatternAnomaly(); // Run once now
    _dailyPatternCheckTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      checkActivityPatternAnomaly();
    });
  }

  void checkActivityPatternAnomaly() async {
    if (!_isUserIdValid) return;
    print("Running daily activity pattern check...");

    final allSleep = await _localDbService.getSleepEntries(days: 7);
    final allFeeding = await _localDbService.getFeedingEntries(days: 7);

    // 1. Calculate historical 7-day averages
    final historicalSleepDuration = allSleep.map((s) => s.durationInMinutes).average;
    final historicalFeedingCount = allFeeding.length / 7.0;

    // 2. Get today's stats
    final dailySleepDuration = calculateDailySleepDuration().inMinutes.toDouble();
    final dailyFeedingCount = calculateDailyFeedingCount().toDouble();

    // 3. Define Anomaly Threshold
    const double DEVIATION_THRESHOLD = 0.25;
    const int MINIMUM_SLEEP_CHANGE = 60;

    // Check Sleep Anomaly
    if (historicalSleepDuration > 0 &&
        ((dailySleepDuration - historicalSleepDuration).abs() / historicalSleepDuration > DEVIATION_THRESHOLD ||
            (dailySleepDuration - historicalSleepDuration).abs() > MINIMUM_SLEEP_CHANGE))
    {
      addAlert(AlertData(
        title: 'Pattern Alert: Abnormal Sleep',
        description: 'Baby\'s sleep today (${(dailySleepDuration / 60).toStringAsFixed(1)}h) deviates significantly from the average (${(historicalSleepDuration / 60).toStringAsFixed(1)}h). Consult a doctor.',
        type: 'ai_warning',
      ));
    }

    // Check Feeding Anomaly
    if (historicalFeedingCount > 1 &&
        (dailyFeedingCount - historicalFeedingCount).abs() / historicalFeedingCount > DEVIATION_THRESHOLD)
    {
      addAlert(AlertData(
        title: 'Pattern Alert: Abnormal Feeding',
        description: 'Baby\'s feeding count today (${dailyFeedingCount.toStringAsFixed(0)} times) deviates significantly from the average (${historicalFeedingCount.toStringAsFixed(1)} times). Consult a doctor.',
        type: 'ai_warning',
      ));
    }
  }

  // =========================================================
  // CORE: Bluetooth Integration Handler (NEW)
  // =========================================================

  /// Public method to receive vital signs data directly from the BluetoothService.
  /// This method is registered in the BluetoothConnectionScreen after a successful connection.
  void handleBluetoothVitals({
    required int heartRate,
    required double temperature,
    required int oxygenSaturation,
    required String movement,
  }) {
    print("Received live Bluetooth Vitals: HR=$heartRate, Temp=$temperature, SpO2=$oxygenSaturation");

    // Stop the mock data generation when real data is received
    stopMockDataGeneration();

    // Pass the real data to the method that updates RTDB and logs to Firestore
    updateBabyDataFromBluetooth(
      heartRate: heartRate,
      temperature: temperature,
      oxygenSaturation: oxygenSaturation,
      movement: movement,
    );
  }

  // =========================================================
  // Other Methods (Logging, Calculation, Mocking)
  // =========================================================

  // Listen to real-time alerts updates from Firestore
  void listenToAlerts() {
    if (!_isUserIdValid) return;
    _alertsSubscription?.cancel();
    _alertsSubscription = _alertsCollection()
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _alerts = snapshot.docs.map((doc) => AlertData.fromFirestore(doc)).toList();
      _alertsController.add(_alerts);
      notifyListeners();
    }, onError: (error) {
      print("Error listening to alerts: $error");
      _alertsController.addError(error);
    });
  }

  // Add new baby data to Firestore (Kept for mock data/logging)
  Future<void> addBabyData(BabyData data) async {
    if (!_isUserIdValid) return;
    try {
      await _babyDataCollection().add(data.toFirestore());
    } catch (e) {
      print("Error adding baby data to Firestore: $e");
    }
  }

  // Add new alert to Firestore
  Future<void> addAlert(AlertData alert) async {
    if (!_isUserIdValid) return;
    try {
      await _alertsCollection().add(alert.toFirestore());
    } catch (e) {
      print("Error adding alert: $e");
    }
  }

  // Calculate total sleep duration for the current day
  Duration calculateDailySleepDuration() {
    if (!_isUserIdValid) return Duration.zero;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    Duration totalDuration = Duration.zero;

    for (var entry in _sleepEntries) {
      final entryStartedToday = entry.startTime.toDate().isAfter(startOfToday);

      if (entryStartedToday || entry.endTime == null) {
        final start = entryStartedToday ? entry.startTime.toDate() : startOfToday;
        final end = entry.endTime?.toDate() ?? DateTime.now();

        final relevantStart = start.isBefore(startOfToday) ? startOfToday : start;
        final relevantEnd = end.isAfter(now) ? now : end;

        if (relevantEnd.isAfter(relevantStart)) {
          totalDuration += relevantEnd.difference(relevantStart);
        }
      }
    }
    return totalDuration;
  }

  // Calculate total feeding times for the current day
  int calculateDailyFeedingCount() {
    if (!_isUserIdValid) return 0;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _feedingEntries.where((entry) => entry.timestamp.toDate().isAfter(startOfToday)).length;
  }

  // Simulate real-time data and alerts for demonstration
  Timer? _mockDataTimer;
  final Random _random = Random();

  void startMockDataGeneration() {
    if (!_isUserIdValid) return;

    if (_mockDataTimer != null && _mockDataTimer!.isActive) {
      return;
    }
    print("Starting mock data generation (only logging to Firestore)...");
    _mockDataTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      int heartRate = 100 + _random.nextInt(61);
      if (_random.nextDouble() < 0.1) {
        heartRate = _random.nextBool() ? (70 + _random.nextInt(20)) : (170 + _random.nextInt(20));
      }

      double temperature = 36.5 + _random.nextDouble();
      if (_random.nextDouble() < 0.1) {
        temperature = _random.nextBool() ? (35.5 + _random.nextDouble()) : (37.6 + _random.nextDouble() * 2);
      }

      int oxygenSaturation = 95 + _random.nextInt(5);
      if (_random.nextDouble() < 0.05) {
        oxygenSaturation = 85 + _random.nextInt(7);
      }

      String movement;
      int movementRoll = _random.nextInt(10);
      if (movementRoll < 6) {
        movement = 'Active';
      } else if (movementRoll < 9) {
        movement = 'Moderate';
      } else {
        movement = 'Inactive';
      }

      final newBabyData = BabyData(
        heartRate: heartRate,
        temperature: double.parse(temperature.toStringAsFixed(1)),
        movement: movement,
        oxygenSaturation: oxygenSaturation,
      );

      // Log the full event to Firestore
      addBabyData(newBabyData);

      // We manually call the alert check since this is a mock. The RTDB stream handles real data.
      _generateAlertsFromVitals(newBabyData);
    });
  }

  void stopMockDataGeneration() {
    _mockDataTimer?.cancel();
    _mockDataTimer = null;
    print("Stopped mock data generation.");
  }

  // Method to update baby data from Bluetooth (called by handleBluetoothVitals)
  Future<void> updateBabyDataFromBluetooth({
    required int heartRate,
    required double temperature,
    required int oxygenSaturation,
    required String movement,
  }) async {
    // 1. Update RTDB to trigger the stream (which updates the UI immediately)
    try {
      await _vitalsRef().set({
        'heartRate': heartRate,
        'temperature': temperature,
        'oxygenSaturation': oxygenSaturation,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print("Error setting RTDB vitals: $e");
    }

    // 2. Log the full event to Firestore for history
    if (_isUserIdValid) {
      final newBabyData = BabyData(
        heartRate: heartRate,
        temperature: temperature,
        oxygenSaturation: oxygenSaturation,
        movement: movement,
      );
      await addBabyData(newBabyData);
    }
  }

  @override
  void dispose() {
    _vitalsDataSubscription?.cancel();
    _alertsSubscription?.cancel();
    _mockDataTimer?.cancel();
    _dailyPatternCheckTimer?.cancel();
    _babyDataController.close();
    _alertsController.close();
    _sleepDataController.close();
    _feedingDataController.close();
    super.dispose();
  }
}