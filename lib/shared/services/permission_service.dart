import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service to handle Bluetooth and location permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all necessary permissions for BLE scanning
  Future<bool> requestBluetoothPermissions() async {
    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        print('Bluetooth not supported on this device');
        return false;
      }

      // Request Bluetooth permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      // Check if all permissions are granted
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          print('Permission ${permission.toString()} not granted: $status');
          allGranted = false;
        }
      });

      if (allGranted) {
        print('All Bluetooth permissions granted');
        return true;
      } else {
        print('Some Bluetooth permissions were denied');
        return false;
      }
    } catch (e) {
      print('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  Future<bool> checkBluetoothPermissions() async {
    try {
      // Check Bluetooth permissions
      PermissionStatus bluetoothStatus = await Permission.bluetooth.status;
      PermissionStatus bluetoothScanStatus = await Permission.bluetoothScan.status;
      PermissionStatus bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      PermissionStatus locationStatus = await Permission.location.status;

      bool allGranted = bluetoothStatus.isGranted &&
          bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          locationStatus.isGranted;

      print('Bluetooth permissions status:');
      print('  Bluetooth: $bluetoothStatus');
      print('  Bluetooth Scan: $bluetoothScanStatus');
      print('  Bluetooth Connect: $bluetoothConnectStatus');
      print('  Location: $locationStatus');

      return allGranted;
    } catch (e) {
      print('Error checking Bluetooth permissions: $e');
      return false;
    }
  }

  /// Open app settings if permissions are permanently denied
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Get permission status for a specific permission
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    try {
      return await permission.status;
    } catch (e) {
      print('Error getting permission status: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request a specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      return await permission.request();
    } catch (e) {
      print('Error requesting permission: $e');
      return PermissionStatus.denied;
    }
  }
} 