import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState with ChangeNotifier {
  bool _isDarkMode = false;
  String _currency = 'USD';
  bool _isBiometricEnabled = false;
  String _userName = '';
  String _userEmail = '';

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  bool get isBiometricEnabled => _isBiometricEnabled;
  String get userName => _userName;
  String get userEmail => _userEmail;

  AppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _currency = prefs.getString('currency') ?? 'USD';
    _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    _userName = prefs.getString('userName') ?? '';
    _userEmail = prefs.getString('userEmail') ?? '';
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    notifyListeners();
  }

  Future<void> toggleBiometric() async {
    _isBiometricEnabled = !_isBiometricEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricEnabled', _isBiometricEnabled);
    notifyListeners();
  }

  Future<void> updateUserInfo(String name, String email) async {
    _userName = name;
    _userEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    notifyListeners();
  }
} 