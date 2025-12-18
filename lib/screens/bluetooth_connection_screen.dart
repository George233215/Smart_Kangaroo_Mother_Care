// lib/screens/bluetooth_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/data_service.dart'; // Import DataService to stop mock data
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp; // Import for BluetoothDevice

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  @override
  void initState() {
    super.initState();
    // Initially, we might want to start scanning or check connection status.
    // For now, let's rely on user action to start scan.
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);
    final dataService = Provider.of<DataService>(context, listen: false); // Access DataService

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.pink[50]!, Colors.white],
        ),
      ),
      child: Padding(
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bluetooth, color: Colors.pink[400], size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Bluetooth Connection',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.1),
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
                    const Text(
                      'Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bluetoothService.isConnected ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: bluetoothService.isConnected ? Colors.green[200]! : Colors.red[200]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            bluetoothService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            color: bluetoothService.isConnected ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bluetoothService.isConnected ? 'Connected' : 'Disconnected',
                                  style: TextStyle(
                                    color: bluetoothService.isConnected ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                if (bluetoothService.isConnected)
                                  Text(
                                    bluetoothService.connectedDevice?.localName ?? 'Device',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Adapter: ${bluetoothService.bluetoothState.toString().split('.').last.toUpperCase()}',
                      style: TextStyle(
                        color: bluetoothService.bluetoothState == fbp.BluetoothAdapterState.on ? Colors.blue : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pairing Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '1. Turn on your Smart KMC device\n'
                            '2. Tap "Scan for Devices" below\n'
                            '3. Select your device to connect',
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (bluetoothService.isConnected) {
                            await bluetoothService.disconnect();
                            dataService.startMockDataGeneration();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Disconnected from device.')),
                            );
                          } else if (bluetoothService.isScanning) {
                            bluetoothService.stopScan();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Stopped scanning.')),
                            );
                          } else {
                            await bluetoothService.startScan();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Scanning for devices...')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bluetoothService.isScanning
                              ? Colors.orange
                              : (bluetoothService.isConnected ? Colors.red[400] : Colors.pink[400]),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              bluetoothService.isScanning
                                  ? Icons.stop_circle_outlined
                                  : (bluetoothService.isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              bluetoothService.isScanning
                                  ? 'Stop Scan'
                                  : (bluetoothService.isConnected ? 'Disconnect' : 'Scan for Devices'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Devices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: bluetoothService.scanResults.isEmpty && !bluetoothService.isScanning
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.devices_outlined, size: 70, color: Colors.pink[200]),
                    const SizedBox(height: 16),
                    Text(
                      bluetoothService.bluetoothState == fbp.BluetoothAdapterState.on
                          ? 'No devices found\nTap "Scan for Devices"'
                          : 'Bluetooth is off\nPlease turn it on',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: bluetoothService.scanResults.length,
                itemBuilder: (context, index) {
                  final result = bluetoothService.scanResults[index];
                  final isConnected = bluetoothService.connectedDevice?.remoteId == result.device.remoteId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isConnected ? Border.all(color: Colors.green, width: 2) : null,
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
                            colors: isConnected
                                ? [Colors.green[300]!, Colors.green[200]!]
                                : [Colors.blue[300]!, Colors.blue[200]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bluetooth, color: Colors.white, size: 24),
                      ),
                      title: Text(
                        result.device.localName.isNotEmpty
                            ? result.device.localName
                            : 'Unknown Device',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'RSSI: ${result.rssi} dBm\n${result.device.remoteId.str.substring(0, 17)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                      trailing: isConnected
                          ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      )
                          : Icon(Icons.arrow_forward_ios, color: Colors.pink[300], size: 18),
                      onTap: isConnected
                          ? null
                          : () async {
                        bluetoothService.stopScan();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Connecting to ${result.device.localName.isNotEmpty ? result.device.localName : "device"}...',
                            ),
                          ),
                        );
                        await bluetoothService.connectToDevice(result.device);
                        if (bluetoothService.isConnected) {
                          dataService.stopMockDataGeneration();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Connected to ${result.device.localName.isNotEmpty ? result.device.localName : "device"}!',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to connect.')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
