import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:developer' as developer;
import 'secure_storage_service.dart';

/// Service for handling app-level authentication (PIN/Biometric)
/// 
/// SECURITY FEATURES:
/// - Rate limiting (5 attempts, then 5-minute lockout)
/// - App timeout (re-lock when app goes to background)
/// - PIN hash stored in secure storage (hardware-backed)
/// - Bcrypt hashing for PIN
class AuthService {
  static const String _pinKey = 'authenticator_pin_hash';
  static const String _authEnabledKey = 'authenticator_auth_enabled';
  static const String _biometricEnabledKey = 'authenticator_biometric_enabled';
  static const String _failedAttemptsKey = 'authenticator_failed_attempts';
  static const String _lockUntilKey = 'authenticator_lock_until';
  static const String _lastUnlockTimeKey = 'authenticator_last_unlock_time';
  
  // Security constants
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationMinutes = 5;
  static const int _timeoutMinutes = 5; // Re-lock after 5 minutes of inactivity
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage;
  SharedPreferences? _prefs;

  AuthService({
    SharedPreferences? prefs,
    SecureStorageService? secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Check if authentication is enabled
  Future<bool> isAuthEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_authEnabledKey) ?? false;
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      developer.log('Error checking biometric availability', error: e, level: 1000);
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      developer.log('Error getting biometrics', error: e, level: 1000);
      return [];
    }
  }

  /// Enable authentication with PIN
  /// PIN is hashed using bcrypt and stored in secure storage
  Future<bool> enablePinAuth(String pin) async {
    try {
      final prefs = await _preferences;
      // Hash PIN using bcrypt with salt (secure one-way hashing)
      final salt = BCrypt.gensalt();
      final pinHash = BCrypt.hashpw(pin, salt);
      
      // Store PIN hash in secure storage (hardware-backed)
      await _secureStorage.saveSecret(_pinKey, pinHash);
      await prefs.setBool(_authEnabledKey, true);
      
      // Reset failed attempts
      await prefs.setInt(_failedAttemptsKey, 0);
      await prefs.remove(_lockUntilKey);
      
      return true;
    } catch (e) {
      developer.log('Error enabling PIN auth', error: e, level: 1000);
      return false;
    }
  }

  /// Enable biometric authentication
  /// SECURITY: Requires PIN as fallback to prevent lockout
  Future<bool> enableBiometricAuth() async {
    try {
      final prefs = await _preferences;
      final available = await isBiometricAvailable();
      if (!available) {
        throw Exception('Biometric authentication is not available on this device');
      }
      
      // SECURITY: Require PIN as fallback to prevent lockout if biometric fails
      final hasPin = await this.hasPin();
      if (!hasPin) {
        throw Exception('PIN is required as a fallback. Please set up a PIN first.');
      }
      // Prompt the user to verify biometrics now (ensures enrollment & consent)
      final verified = await _localAuth.authenticate(
        localizedReason: 'Confirm biometric to enable it for Authenticator',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );

      if (!verified) {
        // User cancelled or verification failed
        throw Exception('Biometric verification failed or was cancelled');
      }

      // Persist preferences only after successful verification
      await prefs.setBool(_biometricEnabledKey, true);
      await prefs.setBool(_authEnabledKey, true);
      return true;
    } catch (e) {
      developer.log('Error enabling biometric auth', error: e, level: 1000);
      rethrow;
    }
  }
  
  /// Check if biometric is still available (for runtime checks)
  /// Returns false if biometric was enabled but is no longer available
  Future<bool> isBiometricStillAvailable() async {
    try {
      final prefs = await _preferences;
      final biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      
      if (!biometricEnabled) return true; // Not enabled, so availability doesn't matter
      
      // If enabled, check if still available
      final available = await isBiometricAvailable();
      
      // If no longer available, disable it automatically
      if (!available) {
        await prefs.setBool(_biometricEnabledKey, false);
        developer.log('Biometric no longer available, automatically disabled', name: 'AuthService');
      }
      
      return available;
    } catch (e) {
      developer.log('Error checking biometric availability', error: e, level: 1000);
      return false;
    }
  }
  
  /// Validate authentication state - ensure at least one method is enabled
  /// Returns true if valid, false if invalid (auth enabled but no methods)
  Future<bool> validateAuthState() async {
    try {
      final prefs = await _preferences;
      final authEnabled = prefs.getBool(_authEnabledKey) ?? false;
      
      if (!authEnabled) return true; // Auth disabled is valid
      
      // Check if at least one method exists
      final hasPin = await this.hasPin();
      final biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      final biometricAvailable = await isBiometricAvailable();
      
      // If auth is enabled but no methods available, disable auth
      if (!hasPin && (!biometricEnabled || !biometricAvailable)) {
        developer.log('Auth enabled but no valid methods, disabling auth', name: 'AuthService');
        await disableAuth();
        return false;
      }
      
      return true;
    } catch (e) {
      developer.log('Error validating auth state', error: e, level: 1000);
      return false;
    }
  }

  /// Authenticate with PIN
  /// Verifies PIN against bcrypt hash with rate limiting
  Future<bool> authenticateWithPin(String pin) async {
    try {
      final prefs = await _preferences;
      
      // Check if account is locked due to too many failed attempts
      final lockUntilString = prefs.getString(_lockUntilKey);
      if (lockUntilString != null) {
        final lockUntil = DateTime.parse(lockUntilString);
        if (DateTime.now().isBefore(lockUntil)) {
          final remainingMinutes = lockUntil.difference(DateTime.now()).inMinutes;
          throw Exception('Account locked. Try again in $remainingMinutes minutes.');
        } else {
          // Lockout period expired, reset
          await prefs.remove(_lockUntilKey);
          await prefs.setInt(_failedAttemptsKey, 0);
        }
      }
      
      // Get PIN hash from secure storage
      final storedHash = await _secureStorage.getSecret(_pinKey);
      if (storedHash == null) return false;
      
      // Verify PIN against bcrypt hash
      final isValid = BCrypt.checkpw(pin, storedHash);
      
      if (isValid) {
        // Success - reset failed attempts and update unlock time
        await prefs.setInt(_failedAttemptsKey, 0);
        await prefs.remove(_lockUntilKey);
        await prefs.setString(_lastUnlockTimeKey, DateTime.now().toIso8601String());
        return true;
      } else {
        // Failed attempt - increment counter
        final failedAttempts = (prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
        await prefs.setInt(_failedAttemptsKey, failedAttempts);
        
        if (failedAttempts >= _maxFailedAttempts) {
          // Lock account for specified duration
          final lockUntil = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes));
          await prefs.setString(_lockUntilKey, lockUntil.toIso8601String());
          throw Exception('Too many failed attempts. Account locked for $_lockoutDurationMinutes minutes.');
        }
        
        return false;
      }
    } catch (e) {
      if (e is Exception) rethrow;
      developer.log('Error authenticating with PIN', error: e, level: 1000);
      return false;
    }
  }
  
  /// Get remaining lockout time in minutes
  Future<int?> getRemainingLockoutMinutes() async {
    try {
      final prefs = await _preferences;
      final lockUntilString = prefs.getString(_lockUntilKey);
      if (lockUntilString == null) return null;
      
      final lockUntil = DateTime.parse(lockUntilString);
      if (DateTime.now().isBefore(lockUntil)) {
        return lockUntil.difference(DateTime.now()).inMinutes + 1;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Get number of failed attempts
  Future<int> getFailedAttempts() async {
    try {
      final prefs = await _preferences;
      return prefs.getInt(_failedAttemptsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      final prefs = await _preferences;
      final isEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      if (!isEnabled) return false;

      // Check if still available (handles system-level disabling)
      final available = await isBiometricStillAvailable();
      if (!available) {
        // Biometric was disabled automatically, return false
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Authenticator',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
      
      if (result) {
        // Success - update unlock time
        await prefs.setString(_lastUnlockTimeKey, DateTime.now().toIso8601String());
        // Reset failed attempts on successful biometric auth
        await prefs.setInt(_failedAttemptsKey, 0);
        await prefs.remove(_lockUntilKey);
      }
      
      return result;
    } on PlatformException catch (e) {
      developer.log('Biometric authentication error', error: e, level: 1000);
      return false;
    } catch (e) {
      developer.log('Error authenticating with biometric', error: e, level: 1000);
      return false;
    }
  }

  /// Authenticate (tries biometric first, then PIN if needed)
  /// Authenticate the user. By default, this will attempt biometric authentication
  /// first if enabled. If [skipBiometric] is true, the method will directly
  /// validate the provided [pin] (if any) and will not trigger biometric UI.
  Future<bool> authenticate({String? pin, bool skipBiometric = false}) async {
    try {
      final prefs = await _preferences;
      // Try biometric first if enabled and not explicitly skipped
      final biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      if (!skipBiometric && biometricEnabled) {
        final biometricResult = await authenticateWithBiometric();
        if (biometricResult) return true;
      }

      // Fall back to PIN if provided
      if (pin != null) {
        return await authenticateWithPin(pin);
      }

      return false;
    } catch (e) {
      developer.log('Error during authentication', error: e, level: 1000);
      return false;
    }
  }

  /// Disable authentication (removes both PIN and biometric)
  Future<void> disableAuth() async {
    final prefs = await _preferences;
    await _secureStorage.deleteSecret(_pinKey);
    await prefs.setBool(_authEnabledKey, false);
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.setInt(_failedAttemptsKey, 0);
    await prefs.remove(_lockUntilKey);
    await prefs.remove(_lastUnlockTimeKey);
  }
  
  /// Remove PIN (also disables biometric + auth for safety)
  /// Returns true if PIN was removed, false if no PIN exists
  Future<bool> removePin() async {
    try {
      final hasPin = await this.hasPin();
      if (!hasPin) return false;
      
      final prefs = await _preferences;
      // Remove PIN and disable biometric (biometric requires PIN fallback)
      await _secureStorage.deleteSecret(_pinKey);
      await prefs.setBool(_biometricEnabledKey, false);
      await prefs.setBool(_authEnabledKey, false);
      await prefs.setInt(_failedAttemptsKey, 0);
      await prefs.remove(_lockUntilKey);
      await prefs.remove(_lastUnlockTimeKey);
      
      return true;
    } catch (e) {
      developer.log('Error removing PIN', error: e, level: 1000);
      rethrow;
    }
  }

  /// Check if PIN is set
  Future<bool> hasPin() async {
    try {
      final pinHash = await _secureStorage.getSecret(_pinKey);
      return pinHash != null && pinHash.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if app should be locked (timeout check)
  /// Returns true if app should be re-locked due to timeout
  Future<bool> shouldRelock() async {
    try {
      final prefs = await _preferences;
      final lastUnlockString = prefs.getString(_lastUnlockTimeKey);
      if (lastUnlockString == null) return true; // Never unlocked, should lock
      
      final lastUnlockTime = DateTime.parse(lastUnlockString);
      final timeSinceUnlock = DateTime.now().difference(lastUnlockTime);
      
      // Re-lock if more than timeout minutes have passed
      return timeSinceUnlock.inMinutes >= _timeoutMinutes;
    } catch (e) {
      return true; // On error, lock for security
    }
  }
  
  /// Update last unlock time (call when app comes to foreground)
  Future<void> updateLastUnlockTime() async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_lastUnlockTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      developer.log('Error updating unlock time', error: e, level: 1000);
    }
  }
  
  /// Get timeout duration in minutes
  int get timeoutMinutes => _timeoutMinutes;
}

