import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesProvider extends ChangeNotifier {
  // State variables
  String _riskTolerance = 'Moderate'; // Default value
  bool _isDarkMode = false;
  bool _isLoading = true;
  String _error = '';
  
  // Getters
  String get riskTolerance => _riskTolerance;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;
  
  // Constants for SharedPreferences keys
  static const String _riskToleranceKey = 'risk_tolerance';
  static const String _darkModeKey = 'dark_mode';
  
  // Risk tolerance options
  static const List<String> riskToleranceOptions = [
    'Conservative',
    'Moderately Conservative',
    'Moderate',
    'Moderately Aggressive',
    'Aggressive'
  ];
  
  // Constructor
  UserPreferencesProvider() {
    _loadPreferences();
  }
  
  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      _setLoading(true);
      _clearError();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load risk tolerance
      final riskTolerance = prefs.getString(_riskToleranceKey);
      if (riskTolerance != null && riskToleranceOptions.contains(riskTolerance)) {
        _riskTolerance = riskTolerance;
      }
      
      // Load dark mode setting
      final isDarkMode = prefs.getBool(_darkModeKey);
      if (isDarkMode != null) {
        _isDarkMode = isDarkMode;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load preferences: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Save preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save risk tolerance
      await prefs.setString(_riskToleranceKey, _riskTolerance);
      
      // Save dark mode setting
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      print('Error saving preferences: $e');
      // Don't set error state here as it might disrupt the UI
    }
  }
  
  // Set risk tolerance
  Future<void> setRiskTolerance(String riskTolerance) async {
    // Validate risk tolerance
    if (!riskToleranceOptions.contains(riskTolerance)) {
      _setError('Invalid risk tolerance value');
      return;
    }
    
    try {
      _riskTolerance = riskTolerance;
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      _setError('Failed to set risk tolerance: $e');
    }
  }
  
  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    try {
      _isDarkMode = !_isDarkMode;
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      _setError('Failed to toggle dark mode: $e');
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void _clearError() {
    _error = '';
    notifyListeners();
  }
} 