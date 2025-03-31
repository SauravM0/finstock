import 'package:flutter/material.dart';
import '../services/investment_agent_service.dart';

class InvestmentAgentProvider extends ChangeNotifier {
  final InvestmentAgentService service;
  
  // State variables
  String _currentAdvice = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _portfolioSuggestions = [];
  String _error = '';
  
  // Getters
  String get currentAdvice => _currentAdvice;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get portfolioSuggestions => _portfolioSuggestions;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;
  
  InvestmentAgentProvider({
    required this.service,
  });
  
  // Method to get investment advice
  Future<void> getInvestmentAdvice({
    required String userQuestion,
    required Map<String, dynamic> portfolioData,
    required List<Map<String, dynamic>> marketTrends,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await service.generateInvestmentAdvice(
        userQuestion: userQuestion,
        portfolioData: portfolioData,
        marketTrends: marketTrends,
      );
      
      // Check if the response contains an error message
      if (response.contains('An error occurred:') || 
          response.contains('Unable to initialize') ||
          response.contains('Invalid API key') ||
          response.contains('Network error')) {
        _setError(response);
        return;
      }
      
      _currentAdvice = response;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get investment advice: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Method to get portfolio suggestions
  Future<void> getPortfolioSuggestions({
    required Map<String, dynamic> currentPortfolio,
    required Map<String, dynamic> userPreferences,
    required List<Map<String, dynamic>> marketData,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final suggestions = await service.generatePortfolioSuggestions(
        currentPortfolio: currentPortfolio,
        userPreferences: userPreferences,
        marketData: marketData,
      );
      
      _portfolioSuggestions = suggestions;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get portfolio suggestions: $e');
    } finally {
      _setLoading(false);
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
  
  void resetState() {
    _currentAdvice = '';
    _portfolioSuggestions = [];
    _error = '';
    _isLoading = false;
    notifyListeners();
  }
} 