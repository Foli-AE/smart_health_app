import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../shared/services/ble_service.dart';
import '../../shared/models/vital_signs.dart' as vitals;
import '../../shared/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// Provider for status messages
final statusMessagesProvider = StreamProvider<String>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.statusMessageStream;
});

// Provider for discovered devices
final discoveredDevicesProvider = StreamProvider<List<BluetoothDevice>>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.discoveredDevicesStream;
});

class BLETestScreen extends ConsumerStatefulWidget {
  const BLETestScreen({super.key});

  @override
  ConsumerState<BLETestScreen> createState() => _BLETestScreenState();
}

class _BLETestScreenState extends ConsumerState<BLETestScreen> {
  @override
  void initState() {
    super.initState();
    _initializeBLE();
  }

  Future<void> _initializeBLE() async {
    try {
      final bleService = ref.read(bleServiceProvider);
      await bleService.initialize();
    } catch (e) {
      print('Error initializing BLE: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BLE Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }



  Widget _buildStatusMessage(String message) {
    Color messageColor = AppColors.textPrimary;
    IconData messageIcon = Icons.info;
    
    if (message.contains('❌')) {
      messageColor = AppColors.error;
      messageIcon = Icons.error;
    } else if (message.contains('✅')) {
      messageColor = AppColors.success;
      messageIcon = Icons.check_circle;
    } else if (message.contains('⏳')) {
      messageColor = AppColors.warning;
      messageIcon = Icons.hourglass_empty;
    } else if (message.contains('🔍')) {
      messageColor = AppColors.primary;
      messageIcon = Icons.search;
    } else if (message.contains('📱')) {
      messageColor = AppColors.secondary;
      messageIcon = Icons.devices;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: messageColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: messageColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(messageIcon, color: messageColor, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: messageColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredDevices(List<BluetoothDevice> devices) {
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Devices (${devices.length}):',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...devices.take(3).map((device) => _buildDeviceCard(device)),
          if (devices.length > 3)
            Text(
              '... and ${devices.length - 3} more',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BluetoothDevice device) {
    bool isTargetDevice = device.name.contains('ESP32') == true || 
                         device.name.contains('Maternal') == true ||
                         device.name == 'MaternalGuardian';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isTargetDevice ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTargetDevice ? AppColors.primary : AppColors.border,
          width: isTargetDevice ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTargetDevice ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isTargetDevice ? AppColors.primary : AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              device.name ?? 'Unknown',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isTargetDevice ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isTargetDevice)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'ESP32',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final statusMessages = ref.watch(statusMessagesProvider);
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final bleService = ref.read(bleServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('BLE Device Test', style: AppTypography.headlineSmall),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            connectionStatus.when(
              data: (status) => _buildConnectionStatus(status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
            
            const SizedBox(height: 16),
            
            // Control Buttons
            _buildControlButtons(bleService),
            
            const SizedBox(height: 16),
            
            // Status Messages
            statusMessages.when(
              data: (message) => _buildStatusMessage(message),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 16),
            
            // Discovered Devices
            discoveredDevices.when(
              data: (devices) => _buildDiscoveredDevices(devices),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(DeviceConnectionStatus status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case DeviceConnectionStatus.disconnected:
        statusColor = AppColors.error;
        statusText = 'Disconnected';
        statusIcon = Icons.bluetooth_disabled;
        break;
      case DeviceConnectionStatus.ready:
        statusColor = AppColors.warning;
        statusText = 'Ready to Connect';
        statusIcon = Icons.bluetooth_searching;
        break;
      case DeviceConnectionStatus.scanning:
        statusColor = AppColors.warning;
        statusText = 'Scanning for Device...';
        statusIcon = Icons.bluetooth_searching;
        break;
      case DeviceConnectionStatus.connecting:
        statusColor = AppColors.warning;
        statusText = 'Connecting...';
        statusIcon = Icons.bluetooth_searching;
        break;
      case DeviceConnectionStatus.connected:
        statusColor = AppColors.success;
        statusText = 'Connected to ESP32';
        statusIcon = Icons.bluetooth_connected;
        break;
      case DeviceConnectionStatus.error:
        statusColor = AppColors.error;
        statusText = 'Connection Error';
        statusIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: AppTypography.titleMedium.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BLEService bleService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await bleService.startScan();
              } catch (e) {
                if (e.toString().contains('permissions')) {
                  _showPermissionDialog();
                } else if (e.toString().contains('Bluetooth must be turned on')) {
                  _showBluetoothDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => bleService.disconnect(),
            icon: const Icon(Icons.bluetooth_disabled),
            label: const Text('Disconnect'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => bleService.sendCommand('TEST'),
            icon: const Icon(Icons.send),
            label: const Text('Test'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text(
            'BLE Error',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Show permission dialog when permissions are denied
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Bluetooth Permissions Required',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'This app needs Bluetooth and Location permissions to scan for and connect to your ESP32 wearable device. Please grant these permissions in the app settings.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final permissionService = PermissionService();
                await permissionService.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
              ),
              child: Text(
                'Open Settings',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show Bluetooth dialog when Bluetooth is off
  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Bluetooth is Turned Off',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Bluetooth must be turned ON to scan for and connect to your ESP32 wearable device. Please turn on Bluetooth in your device settings.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Try to turn on Bluetooth
                try {
                  await FlutterBluePlus.turnOn();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please turn on Bluetooth manually in settings'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
              ),
              child: Text(
                'Turn On Bluetooth',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 