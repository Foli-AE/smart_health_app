import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vital_signs.dart';
import 'permission_service.dart';

/// BLE Service for ESP32 Wearable Device Communication
/// Handles device discovery, connection, and data streaming
class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  // ESP32 Device Configuration
  static const String _deviceName = 'MaternalGuardian'; // ESP32 device name
  static const String _serviceUuid = '180D'; // Heart Rate Service
  static const String _heartRateCharUuid = '2A37'; // Heart Rate Measurement
  static const String _customServiceUuid = 'CD00'; // Custom Vitals Service
  static const String _spo2CharUuid = 'CD01'; // SpO2 Measurement
  static const String _temperatureCharUuid = 'CD02'; // Temperature Measurement
  static const String _batteryCharUuid = '2A19'; // Battery Level

  // State management
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _heartRateCharacteristic;
  BluetoothCharacteristic? _spo2Characteristic;
  BluetoothCharacteristic? _temperatureCharacteristic;
  BluetoothCharacteristic? _batteryCharacteristic;

  // Stream controllers
  final StreamController<VitalSigns> _vitalSignsController = StreamController<VitalSigns>.broadcast();
  final StreamController<DeviceConnectionStatus> _connectionStatusController = 
      StreamController<DeviceConnectionStatus>.broadcast();
  final StreamController<double> _batteryLevelController = StreamController<double>.broadcast();
  final StreamController<String> _statusMessageController = StreamController<String>.broadcast();
  final StreamController<List<BluetoothDevice>> _discoveredDevicesController = 
      StreamController<List<BluetoothDevice>>.broadcast();

  // Connection state
  DeviceConnectionStatus _connectionStatus = DeviceConnectionStatus.disconnected;
  bool _isScanning = false;
  bool _isConnecting = false;
  List<BluetoothDevice> _discoveredDevices = [];

  // Getters
  Stream<VitalSigns> get vitalSignsStream => _vitalSignsController.stream;
  Stream<DeviceConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;
  Stream<double> get batteryLevelStream => _batteryLevelController.stream;
  Stream<String> get statusMessageStream => _statusMessageController.stream;
  Stream<List<BluetoothDevice>> get discoveredDevicesStream => _discoveredDevicesController.stream;
  
  DeviceConnectionStatus get connectionStatus => _connectionStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;

  /// Initialize BLE service
  Future<void> initialize() async {
    try {
      _statusMessageController.add('Checking Bluetooth support...');
      
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        _statusMessageController.add('❌ Bluetooth not supported on this device');
        throw Exception('Bluetooth not supported on this device');
      }

      _statusMessageController.add('✅ Bluetooth supported, requesting permissions...');

      // Request Bluetooth permissions
      final permissionService = PermissionService();
      bool permissionsGranted = await permissionService.requestBluetoothPermissions();
      
      if (!permissionsGranted) {
        _statusMessageController.add('❌ Bluetooth permissions not granted');
        throw Exception('Bluetooth permissions not granted');
      }

      _statusMessageController.add('✅ Permissions granted, checking Bluetooth state...');

      // Listen to Bluetooth state changes
      FlutterBluePlus.adapterState.listen((state) {
        switch (state) {
          case BluetoothAdapterState.on:
            _statusMessageController.add('✅ Bluetooth is ON and ready');
            _updateConnectionStatus(DeviceConnectionStatus.ready);
            break;
          case BluetoothAdapterState.off:
            _statusMessageController.add('❌ Bluetooth is OFF - please turn it on');
            _updateConnectionStatus(DeviceConnectionStatus.disconnected);
            break;
          case BluetoothAdapterState.turningOn:
            _statusMessageController.add('⏳ Bluetooth is turning ON...');
            _updateConnectionStatus(DeviceConnectionStatus.connecting);
            break;
          case BluetoothAdapterState.turningOff:
            _statusMessageController.add('⏳ Bluetooth is turning OFF...');
            _updateConnectionStatus(DeviceConnectionStatus.disconnected);
            break;
          case BluetoothAdapterState.unauthorized:
            _statusMessageController.add('❌ Bluetooth access unauthorized');
            _updateConnectionStatus(DeviceConnectionStatus.error);
            break;
          default:
            _statusMessageController.add('❌ Bluetooth state unknown');
            _updateConnectionStatus(DeviceConnectionStatus.error);
            break;
        }
      });

      // Monitor connection state changes
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_connectedDevice != null) {
          try {
            final devices = await FlutterBluePlus.connectedDevices;
            if (!devices.contains(_connectedDevice)) {
              _handleDeviceDisconnection();
              timer.cancel();
            }
          } catch (e) {
            print('Error checking device connection: $e');
          }
        }
      });

      _statusMessageController.add('✅ BLE service initialized successfully');
    } catch (e) {
      _statusMessageController.add('❌ Error initializing BLE: $e');
      _updateConnectionStatus(DeviceConnectionStatus.error);
      throw e;
    }
  }

  /// Start scanning for ESP32 device
  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _statusMessageController.add('🔍 Starting device scan...');
      
      // Check permissions before scanning
      final permissionService = PermissionService();
      bool permissionsGranted = await permissionService.checkBluetoothPermissions();
      
      if (!permissionsGranted) {
        _statusMessageController.add('❌ Bluetooth permissions required for scanning');
        throw Exception('Bluetooth permissions required for scanning');
      }

      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _statusMessageController.add('❌ Bluetooth must be turned ON to scan');
        throw Exception('Bluetooth must be turned on');
      }

      _isScanning = true;
      _updateConnectionStatus(DeviceConnectionStatus.scanning);
      _statusMessageController.add('🔍 Scanning for ESP32 devices...');

      // Start scanning with timeout
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        _discoveredDevices.clear();
        
        for (ScanResult result in results) {
          if (!_discoveredDevices.contains(result.device)) {
            _discoveredDevices.add(result.device);
            _statusMessageController.add('📱 Found device: ${result.device.name ?? "Unknown"} (${result.device.id})');
            
            // Check if this is our target device
            if (result.device.name == _deviceName || 
                result.device.name?.contains('ESP32') == true ||
                result.device.name?.contains('Maternal') == true) {
              _statusMessageController.add('🎯 Target ESP32 device found: ${result.device.name}');
              _stopScan();
              _connectToDevice(result.device);
              break;
            }
          }
        }
        
        // Update discovered devices list
        _discoveredDevicesController.add(List.from(_discoveredDevices));
      });

      _statusMessageController.add('✅ Scan started successfully');
    } catch (e) {
      _statusMessageController.add('❌ Scan error: $e');
      _isScanning = false;
      _updateConnectionStatus(DeviceConnectionStatus.error);
      throw e;
    }
  }

  /// Stop scanning
  Future<void> _stopScan() async {
    if (!_isScanning) return;

    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      _statusMessageController.add('⏹️ Scanning stopped');
      print('Stopped scanning');
    } catch (e) {
      print('Error stopping scan: $e');
      _statusMessageController.add('❌ Error stopping scan: $e');
    }
  }

  /// Connect to ESP32 device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;

    try {
      _isConnecting = true;
      _updateConnectionStatus(DeviceConnectionStatus.connecting);
      _statusMessageController.add('🔗 Connecting to ${device.name ?? "device"}...');

      print('Connecting to device: ${device.name}');
      
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      _statusMessageController.add('🔍 Discovering services...');
      // Discover services
      await _discoverServices(device);

      _isConnecting = false;
      _updateConnectionStatus(DeviceConnectionStatus.connected);
      _statusMessageController.add('✅ Successfully connected to ESP32 device');
      print('Successfully connected to ESP32 device');

    } catch (e) {
      print('Error connecting to device: $e');
      _statusMessageController.add('❌ Connection failed: $e');
      _isConnecting = false;
      _updateConnectionStatus(DeviceConnectionStatus.error);
    }
  }

  /// Discover services and characteristics
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        // Heart Rate Service
        if (service.uuid.toString().toUpperCase().contains(_serviceUuid)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase().contains(_heartRateCharUuid)) {
              _heartRateCharacteristic = characteristic;
              await _subscribeToCharacteristic(characteristic, 'Heart Rate');
            }
          }
        }

        // Custom Vitals Service
        if (service.uuid.toString().toUpperCase().contains(_customServiceUuid)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase().contains(_spo2CharUuid)) {
              _spo2Characteristic = characteristic;
              await _subscribeToCharacteristic(characteristic, 'SpO2');
            } else if (characteristic.uuid.toString().toUpperCase().contains(_temperatureCharUuid)) {
              _temperatureCharacteristic = characteristic;
              await _subscribeToCharacteristic(characteristic, 'Temperature');
            }
          }
        }

        // Battery Service
        if (service.uuid.toString().toUpperCase().contains('180F')) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase().contains(_batteryCharUuid)) {
              _batteryCharacteristic = characteristic;
              await _subscribeToCharacteristic(characteristic, 'Battery');
            }
          }
        }
      }

      print('Services discovered successfully');
    } catch (e) {
      print('Error discovering services: $e');
    }
  }

  /// Subscribe to characteristic notifications
  Future<void> _subscribeToCharacteristic(BluetoothCharacteristic characteristic, String type) async {
    try {
      await characteristic.setNotifyValue(true);
      characteristic.value.listen((value) {
        _processCharacteristicData(characteristic, value, type);
      });
      print('Subscribed to $type characteristic');
    } catch (e) {
      print('Error subscribing to $type characteristic: $e');
    }
  }

  /// Process incoming characteristic data
  void _processCharacteristicData(BluetoothCharacteristic characteristic, List<int> value, String type) {
    try {
      switch (type) {
        case 'Heart Rate':
          _processHeartRateData(value);
          break;
        case 'SpO2':
          _processSpO2Data(value);
          break;
        case 'Temperature':
          _processTemperatureData(value);
          break;
        case 'Battery':
          _processBatteryData(value);
          break;
      }
    } catch (e) {
      print('Error processing $type data: $e');
    }
  }

  /// Process heart rate data
  void _processHeartRateData(List<int> value) {
    if (value.length >= 2) {
      int heartRate = value[1]; // Standard BLE heart rate format
      _updateVitalSigns(heartRate: heartRate.toDouble());
    }
  }

  /// Process SpO2 data
  void _processSpO2Data(List<int> value) {
    if (value.isNotEmpty) {
      double spo2 = value[0].toDouble();
      _updateVitalSigns(oxygenSaturation: spo2);
    }
  }

  /// Process temperature data
  void _processTemperatureData(List<int> value) {
    if (value.length >= 2) {
      // Convert raw temperature data to Celsius
      int rawTemp = (value[1] << 8) | value[0];
      double temperature = rawTemp / 100.0; // Assuming 2 decimal places
      _updateVitalSigns(temperature: temperature);
    }
  }

  /// Process battery data
  void _processBatteryData(List<int> value) {
    if (value.isNotEmpty) {
      double batteryLevel = value[0].toDouble();
      _batteryLevelController.add(batteryLevel);
    }
  }

  /// Update vital signs with new data
  void _updateVitalSigns({
    double? heartRate,
    double? oxygenSaturation,
    double? temperature,
  }) {
    final vitalSigns = VitalSigns(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      heartRate: heartRate ?? 0.0,
      oxygenSaturation: oxygenSaturation ?? 0.0,
      temperature: temperature ?? 0.0,
      systolicBP: 0.0, // Will be updated separately
      diastolicBP: 0.0, // Will be updated separately
      glucose: 0.0, // Will be updated separately
      source: 'device',
      isSynced: false,
    );

    _vitalSignsController.add(vitalSigns);
  }

  /// Handle device disconnection
  void _handleDeviceDisconnection() {
    _connectedDevice = null;
    _heartRateCharacteristic = null;
    _spo2Characteristic = null;
    _temperatureCharacteristic = null;
    _batteryCharacteristic = null;
    
    _updateConnectionStatus(DeviceConnectionStatus.disconnected);
    print('ESP32 device disconnected');
  }

  /// Update connection status
  void _updateConnectionStatus(DeviceConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        _statusMessageController.add('🔌 Disconnecting from device...');
        await _connectedDevice!.disconnect();
        _handleDeviceDisconnection();
        _statusMessageController.add('✅ Device disconnected');
      } else {
        _statusMessageController.add('ℹ️ No device connected to disconnect');
      }
    } catch (e) {
      print('Error disconnecting: $e');
      _statusMessageController.add('❌ Error disconnecting: $e');
    }
  }

  /// Send command to ESP32
  Future<void> sendCommand(String command) async {
    try {
      if (_connectedDevice != null && _heartRateCharacteristic != null) {
        _statusMessageController.add('📤 Sending command: $command');
        await _heartRateCharacteristic!.write(command.codeUnits);
        _statusMessageController.add('✅ Command sent successfully');
        print('Sent command: $command');
      } else {
        _statusMessageController.add('❌ Cannot send command: Device not connected or characteristic not available');
      }
    } catch (e) {
      print('Error sending command: $e');
      _statusMessageController.add('❌ Error sending command: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _vitalSignsController.close();
    _connectionStatusController.close();
    _batteryLevelController.close();
    _statusMessageController.close();
    _discoveredDevicesController.close();
    disconnect();
  }
}

/// Device connection status enum
enum DeviceConnectionStatus {
  disconnected,
  ready,
  scanning,
  connecting,
  connected,
  error,
}

/// Riverpod provider for BLE service
final bleServiceProvider = Provider<BLEService>((ref) {
  return BLEService();
});

/// Riverpod provider for connection status
final connectionStatusProvider = StreamProvider<DeviceConnectionStatus>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.connectionStatusStream;
});

/// Riverpod provider for vital signs stream
final bleVitalSignsProvider = StreamProvider<VitalSigns>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.vitalSignsStream;
});

/// Riverpod provider for status messages
final bleStatusMessagesProvider = StreamProvider<String>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.statusMessageStream;
});

/// Riverpod provider for discovered devices
final bleDiscoveredDevicesProvider = StreamProvider<List<BluetoothDevice>>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.discoveredDevicesStream;
}); 