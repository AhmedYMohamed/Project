import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
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
    // In a real app we might load the last selected role here as well
    _isInitialized = true;
    notifyListeners();
  }

  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<void> register(String email, String password, {String? phoneNumber}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(email: email, password: password, phoneNumber: phoneNumber);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.login(email: email, password: password);
      _token = result['token'];
      _userId = result['userId'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    notifyListeners();
  }
}
