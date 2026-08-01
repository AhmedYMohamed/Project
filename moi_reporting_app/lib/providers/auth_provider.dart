import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

import '../utils/web_helper.dart';

import '../services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  String? _token;
  String? _userId;
  String _selectedRole = 'citizen';
  bool _isLoading = false;
  bool _isInitialized = false;

  String? get token => _token;
  String? get userId => _userId;
  String get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _authService.getToken();
    _userId = await _authService.getUserId();
    final role = await _authService.getUserRole();
    if (role != null) {
      _selectedRole = role;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> hasBiometricCredentials() async {
    return await _biometricService.hasStoredCredentials();
  }

  Future<bool> loginWithBiometrics() async {
    final bool authenticated = await _biometricService.authenticate();
    if (!authenticated) return false;

    final creds = await _biometricService.getCredentials();
    if (creds != null) {
      await setSelectedRole(creds['role']!);
      await login(creds['nationalId']!, creds['password']!);
      return true;
    }
    return false;
  }

  Future<void> setSelectedRole(String role) async {
    _selectedRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    notifyListeners();
  }

  Future<void> register(String email, String nationalId, String password,
      {String? phoneNumber}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(
          email: email, nationalId: nationalId, password: password, phoneNumber: phoneNumber);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerLawyer({
    required String email,
    required String nationalId,
    required String password,
    required String syndicateId,
    String? phoneNumber,
    String? digitalSignatureUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.registerLawyer(
        email: email,
        nationalId: nationalId,
        password: password,
        syndicateId: syndicateId,
        phoneNumber: phoneNumber,
        digitalSignatureUrl: digitalSignatureUrl,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String nationalId, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.login(nationalId: nationalId, password: password);
      _token = result['token'];
      _userId = result['userId'];
      if (result['role'] != null) {
        _selectedRole = result['role']!;
      }
      // Save credentials for biometric login
      await _biometricService.saveCredentials(
        nationalId: nationalId,
        password: password,
        role: _selectedRole,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _biometricService.clearCredentials();
    _token = null;
    notifyListeners();
  }
}
