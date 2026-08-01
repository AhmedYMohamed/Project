import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyNationalId = 'biometric_national_id';
  static const String _keyPassword = 'biometric_password';
  static const String _keyRole = 'biometric_role';

  /// Check if device supports biometric or PIN hardware authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompt user for Biometric / Device PIN authentication
  Future<bool> authenticate() async {
    try {
      final bool available = await isBiometricAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate using fingerprint, Face ID, or PIN to log in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows device PIN fallback
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Securely save credentials for biometric auto-login
  Future<void> saveCredentials({
    required String nationalId,
    required String password,
    required String role,
  }) async {
    await _secureStorage.write(key: _keyNationalId, value: nationalId);
    await _secureStorage.write(key: _keyPassword, value: password);
    await _secureStorage.write(key: _keyRole, value: role);
  }

  /// Read stored credentials
  Future<Map<String, String>?> getCredentials() async {
    final nationalId = await _secureStorage.read(key: _keyNationalId);
    final password = await _secureStorage.read(key: _keyPassword);
    final role = await _secureStorage.read(key: _keyRole);

    if (nationalId != null && password != null) {
      return {
        'nationalId': nationalId,
        'password': password,
        'role': role ?? 'citizen',
      };
    }
    return null;
  }

  /// Check if credentials exist in secure storage
  Future<bool> hasStoredCredentials() async {
    final nationalId = await _secureStorage.read(key: _keyNationalId);
    final password = await _secureStorage.read(key: _keyPassword);
    return nationalId != null && password != null;
  }

  /// Clear credentials on explicit logout
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _keyNationalId);
    await _secureStorage.delete(key: _keyPassword);
    await _secureStorage.delete(key: _keyRole);
  }
}
