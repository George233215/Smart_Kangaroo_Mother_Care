// lib/screens/bluetooth_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/data_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<BluetoothService>(context);
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[400]!, Colors.cyan[300]!],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Device Connection',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Connection Status Card
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: bluetoothService.isConnected ? Colors.green[200]! : Colors.grey[200]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: bluetoothService.isConnected
                        ? Colors.green.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Status Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: bluetoothService.isConnected
                            ? [Colors.green[50]!, Colors.white]
                            : [Colors.grey[50]!, Colors.white],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: bluetoothService.isConnected
                                  ? [Colors.green[400]!, Colors.green[300]!]
                                  : [Colors.grey[400]!, Colors.grey[300]!],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            bluetoothService.isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bluetoothService.isConnected ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: bluetoothService.isConnected ? Colors.green : Colors.grey[700],
                                ),
                              ),
                              if (bluetoothService.isConnected) ...[
                                const SizedBox(height: 4),
                                Text(
                                  bluetoothService.connectedDevice?.localName ?? 'Device',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (bluetoothService.isConnected)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Bluetooth Adapter',
                          bluetoothService.bluetoothState.toString().split('.').last.toUpperCase(),
                          bluetoothService.bluetoothState == fbp.BluetoothAdapterState.on
                              ? Colors.blue
                              : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionsCard(),
                        const SizedBox(height: 20),
                        _buildActionButton(context, bluetoothService, dataService),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Devices Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Available Devices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (bluetoothService.isScanning)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Device List (wrapped in Expanded with SingleChildScrollView)
            Expanded(
              child: bluetoothService.scanResults.isEmpty
                  ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: _buildEmptyState(bluetoothService),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: bluetoothService.scanResults.length,
                itemBuilder: (context, index) {
                  final result = bluetoothService.scanResults[index];
                  final isConnected = bluetoothService.isConnected &&
                      bluetoothService.connectedDevice?.remoteId == result.device.remoteId;

                  return _buildDeviceCard(
                    context,
                    result,
                    isConnected,
                    bluetoothService,
                    dataService,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ensure your Smart KMC device is powered on and nearby',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, BluetoothService bluetoothService, DataService dataService) {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;

    if (bluetoothService.isConnected) {
      buttonText = 'Disconnect Device';
      buttonIcon = Icons.bluetooth_disabled;
      buttonColor = Colors.red;
    } else if (bluetoothService.isScanning) {
      buttonText = 'Stop Scanning';
      buttonIcon = Icons.stop;
      buttonColor = Colors.orange;
    } else {
      buttonText = 'Scan for Devices';
      buttonIcon = Icons.search;
      buttonColor = Colors.blue;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (bluetoothService.isConnected) {
            await bluetoothService.disconnect();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildModernSnackBar('Disconnected', Colors.orange),
              );
            }
          } else if (bluetoothService.isScanning) {
            bluetoothService.stopScan();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildModernSnackBar('Scan stopped', Colors.orange),
              );
            }
          } else {
            await bluetoothService.startScan();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildModernSnackBar('Scanning for devices...', Colors.blue),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(buttonIcon, size: 24),
            const SizedBox(width: 12),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BluetoothService bluetoothService) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.devices_outlined,
                size: 64,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              bluetoothService.bluetoothState == fbp.BluetoothAdapterState.on
                  ? 'No Devices Found'
                  : 'Bluetooth is Off',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                bluetoothService.bluetoothState == fbp.BluetoothAdapterState.on
                    ? 'Tap "Scan for Devices" to search\nfor nearby Smart KMC devices'
                    : 'Please turn on Bluetooth\nin your device settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, dynamic result, bool isConnected, BluetoothService bluetoothService, DataService dataService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isConnected
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: isConnected ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
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
                  ? [Colors.green[400]!, Colors.green[300]!]
                  : [Colors.blue[400]!, Colors.blue[300]!],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bluetooth, color: Colors.white, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                result.device.localName.isNotEmpty ? result.device.localName : 'Unknown Device',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (isConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CONNECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Signal: ${result.rssi} dBm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
            : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: isConnected
            ? null
            : () async {
          bluetoothService.stopScan();
          ScaffoldMessenger.of(context).showSnackBar(
            _buildModernSnackBar(
              'Connecting to ${result.device.localName.isNotEmpty ? result.device.localName : "device"}...',
              Colors.blue,
            ),
          );
          await bluetoothService.connectToDevice(result.device);
          if (bluetoothService.isConnected) {
            dataService.stopMockDataGeneration();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildModernSnackBar(
                  'Connected successfully!',
                  Colors.green,
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildModernSnackBar('Connection failed', Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  SnackBar _buildModernSnackBar(String message, Color color) {
    return SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    );
  }
}