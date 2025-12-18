// lib/services/bluetooth_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp; // Alias added
import 'dart:async';

class BluetoothService with ChangeNotifier {
  fbp.BluetoothDevice? _connectedDevice; // Use fbp.BluetoothDevice
  fbp.BluetoothAdapterState _bluetoothState = fbp.BluetoothAdapterState.unknown; // Use fbp.BluetoothAdapterState
  bool _isScanning = false;
  List<fbp.ScanResult> _scanResults = []; // Use fbp.ScanResult
  StreamSubscription? _scanSubscription;
  StreamSubscription? _bluetoothStateSubscription;
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _dataSubscription; // For listening to characteristic data

  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  fbp.BluetoothAdapterState get bluetoothState => _bluetoothState;
  bool get isScanning => _isScanning;
  List<fbp.ScanResult> get scanResults => _scanResults;

  BluetoothService() {
    _initBluetooth();
  }

  void _initBluetooth() async { // Made _initBluetooth async
    // Listen for Bluetooth adapter state changes
    _bluetoothStateSubscription = fbp.FlutterBluePlus.adapterState.listen((state) {
      _bluetoothState = state;
      notifyListeners();
      if (state == fbp.BluetoothAdapterState.off) { // Use fbp.BluetoothAdapterState
        _connectedDevice = null; // Disconnect if Bluetooth is turned off
        notifyListeners();
      }
    });

    // Restore existing connections (optional, but good practice)
    try {
      List<fbp.BluetoothDevice> devices = await fbp.FlutterBluePlus.connectedDevices;
      if (devices.isNotEmpty) {
        _connectedDevice = devices.first; // Or iterate to find your specific device
        notifyListeners();
      }
    } catch (e) {
      print("Error restoring connected devices: $e");
    }
  }

  // Start scanning for Bluetooth devices
  Future<void> startScan() async {
    if (_bluetoothState != fbp.BluetoothAdapterState.on) { // Use fbp.BluetoothAdapterState
      print("Bluetooth is not ON. Cannot start scan.");
      // Optionally request Bluetooth to be turned on
      await fbp.FlutterBluePlus.turnOn();
      return;
    }

    _scanResults = []; // Clear previous scan results
    _isScanning = true;
    notifyListeners();

    // Start scanning with a timeout
    _scanSubscription = fbp.FlutterBluePlus.scanResults.listen(
          (results) {
        _scanResults = results;
        notifyListeners();
      },
      onError: (e) {
        print("Scan error: $e");
        _isScanning = false;
        notifyListeners();
      },
      onDone: () {
        _isScanning = false;
        notifyListeners();
      },
    );

    await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    _isScanning = false; // Scan might stop before timeout if no devices found
    notifyListeners();
  }

  // Stop scanning for Bluetooth devices
  void stopScan() {
    fbp.FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  // Connect to a specific Bluetooth device
  Future<void> connectToDevice(fbp.BluetoothDevice device) async { // Use fbp.BluetoothDevice
    if (_connectedDevice != null) {
      await disconnect(); // Disconnect existing connection first
    }

    try {
      await device.connect(autoConnect: false); // Set autoConnect to true if you want it to reconnect
      _connectedDevice = device;
      notifyListeners();

      // Listen to the connection state of the newly connected device
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.disconnected) { // Use fbp.BluetoothConnectionState
          print("Device ${_connectedDevice?.localName} disconnected.");
          _connectedDevice = null;
          _dataSubscription?.cancel(); // Stop listening to data
          notifyListeners();
        }
      });

      // Discover services and characteristics after connection
      await _discoverServices(device);

    } catch (e) {
      print("Failed to connect to device: $e");
      _connectedDevice = null;
      notifyListeners();
    }
  }

  // Disconnect from the current Bluetooth device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _connectionStateSubscription?.cancel();
        _dataSubscription?.cancel(); // Cancel data subscription on disconnect
      } catch (e) {
        print("Error disconnecting: $e");
      } finally {
        notifyListeners();
      }
    }
  }

  // Discover services and characteristics of the connected device
  Future<void> _discoverServices(fbp.BluetoothDevice device) async { // Use fbp.BluetoothDevice
    try {
      List<fbp.BluetoothService> services = await device.discoverServices(); // Use fbp.BluetoothService
      for (fbp.BluetoothService service in services) { // Use fbp.BluetoothService
        print('Service UUID: ${service.uuid.str}');
        for (fbp.BluetoothCharacteristic characteristic in service.characteristics) { // Use fbp.BluetoothCharacteristic
          print('  Characteristic UUID: ${characteristic.uuid.str}');
          // Identify your specific characteristics here (e.g., for heart rate, temp, movement)
          // You'll need to know the UUIDs from your ESP32 firmware
          // Example: if (characteristic.uuid.str == "YOUR_HEART_RATE_CHARACTERISTIC_UUID") {
          //   _listenToCharacteristics(characteristic);
          // }
          // Or, if you want to read once:
          // List<int> value = await characteristic.read();
          // print('  Value: $value');

          // If the characteristic supports notifications, enable them
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _listenToCharacteristics(characteristic); // Start listening for real-time updates
          }
        }
      }
    } catch (e) {
      print("Error discovering services: $e");
    }
  }

  // Listen to characteristic value changes (real-time data)
  void _listenToCharacteristics(fbp.BluetoothCharacteristic characteristic) { // Use fbp.BluetoothCharacteristic
    _dataSubscription = characteristic.onValueReceived.listen((value) {
      // 'value' is List<int> (bytes) from the characteristic
      // You will need to parse these bytes into your BabyData model (heart rate, temp, movement)
      print('Received data from ${characteristic.uuid.str}: $value');

      // Example parsing (replace with your actual parsing logic based on ESP32 data format)
      if (value.length >= 3) {
        int heartRate = value[0]; // Assuming first byte is heart rate
        double temperature = value[1] / 10.0; // Assuming second byte is temp scaled by 10
        String movement = 'Unknown';
        if (value[2] == 0) movement = 'Inactive';
        if (value[2] == 1) movement = 'Moderate';
        if (value[2] == 2) movement = 'Active';

        // Now, you would typically pass this data to your DataService
        // For now, we'll just print it. In a real scenario, you'd update your DataService
        // Provider.of<DataService>(context, listen: false).addBabyData(BabyData(...));
        print('Parsed Data: HR=$heartRate, Temp=$temperature, Movement=$movement');
      }
    }, onError: (e) {
      print("Error listening to characteristic: $e");
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bluetoothStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _dataSubscription?.cancel();
    disconnect(); // Ensure disconnection on dispose
    super.dispose();
  }
}
