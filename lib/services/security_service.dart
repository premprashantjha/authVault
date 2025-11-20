import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

/// Security service for device integrity checks
/// Detects rooted/jailbroken devices, emulators, and debug mode
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  SecurityCheckResult? _cachedResult;

  /// Perform comprehensive security checks
  Future<SecurityCheckResult> performSecurityChecks() async {
    // Return cached result if available (checks are expensive)
    if (_cachedResult != null) {
      return _cachedResult!;
    }

    try {
      final results = await Future.wait([
        _checkJailbroken(),
        _checkRealDevice(),
        _checkDevelopmentMode(),
        _checkOnExternalStorage(),
      ]);

      final result = SecurityCheckResult(
        isJailbroken: results[0],
        isRealDevice: results[1],
        isDevelopmentMode: results[2],
        isOnExternalStorage: results[3],
      );

      _cachedResult = result;
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Security check error: $e');
      }
      // On error, assume device is secure (graceful degradation)
      return SecurityCheckResult(
        isJailbroken: false,
        isRealDevice: true,
        isDevelopmentMode: false,
        isOnExternalStorage: false,
      );
    }
  }

  Future<bool> _checkJailbroken() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkRealDevice() async {
    try {
      return await SafeDevice.isRealDevice;
    } catch (e) {
      return true;
    }
  }

  Future<bool> _checkDevelopmentMode() async {
    try {
      return await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkOnExternalStorage() async {
    try {
      return await SafeDevice.isOnExternalStorage;
    } catch (e) {
      return false;
    }
  }

  /// Check if device is secure enough to run the app
  Future<bool> isDeviceSecure() async {
    final result = await performSecurityChecks();
    
    // Device is secure if:
    // - Not jailbroken/rooted
    // - Real device (not emulator in production)
    // - Not installed on external storage
    final isSecure = !result.isJailbroken && 
                     result.isRealDevice && 
                     !result.isOnExternalStorage;
    
    // In debug mode, allow development mode
    if (kDebugMode) {
      return isSecure;
    }
    
    // In production, also check development mode
    return isSecure && !result.isDevelopmentMode;
  }

  /// Get detailed security warning message
  Future<String> getSecurityWarning() async {
    final result = await performSecurityChecks();
    final warnings = <String>[];

    if (result.isJailbroken) {
      warnings.add('Device is rooted/jailbroken');
    }
    if (!result.isRealDevice) {
      warnings.add('Running on emulator');
    }
    if (result.isDevelopmentMode && !kDebugMode) {
      warnings.add('Developer mode is enabled');
    }
    if (result.isOnExternalStorage) {
      warnings.add('App installed on external storage');
    }

    if (warnings.isEmpty) {
      return 'Device is secure';
    }

    return 'Security Warning:\n${warnings.join('\n')}';
  }

  /// Clear cached results (call when user dismisses warning)
  void clearCache() {
    _cachedResult = null;
  }
}

/// Result of security checks
class SecurityCheckResult {
  final bool isJailbroken;
  final bool isRealDevice;
  final bool isDevelopmentMode;
  final bool isOnExternalStorage;

  SecurityCheckResult({
    required this.isJailbroken,
    required this.isRealDevice,
    required this.isDevelopmentMode,
    required this.isOnExternalStorage,
  });

  bool get isSecure =>
      !isJailbroken && isRealDevice && !isOnExternalStorage;

  @override
  String toString() {
    return 'SecurityCheckResult(jailbroken: $isJailbroken, realDevice: $isRealDevice, '
        'devMode: $isDevelopmentMode, externalStorage: $isOnExternalStorage)';
  }
}
