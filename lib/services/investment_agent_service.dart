import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class InvestmentAgentService {
  final String apiKey;
  late final GenerativeModel? _model;
  bool _isModelInitialized = false;
  
  InvestmentAgentService({required this.apiKey}) {
    _initializeModel();
  }
  
  void _initializeModel() {
    try {
      if (apiKey.isEmpty) {
        debugPrint('Error: API key is empty');
        _model = null;
        return;
      }
      
      _model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: apiKey,
        safetySettings: [
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );
      _isModelInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Gemini model: $e');
      _model = null;
    }
  }
  
  Future<String> generateInvestmentAdvice({
    required String userQuestion,
    required Map<String, dynamic> portfolioData,
    required List<Map<String, dynamic>> marketTrends,
  }) async {
    try {
      if (!_isModelInitialized || _model == null) {
        // Display a user-friendly message when no API key is set
        if (apiKey.isEmpty) {
          return 'To use the AI investment agent, please set up your Gemini API key in Settings. '
                 'You can get a free API key from https://ai.google.dev/';
        }
        
        // Try to initialize again
        _initializeModel();
        if (!_isModelInitialized || _model == null) {
          return 'Unable to initialize AI model. Please check your API key in Settings.';
        }
      }
      
      // Prepare context for the model with a specific prompt
      final context = '''
As an investment advisor, analyze the following information and provide advice:

User portfolio: ${portfolioData.toString()}
Market trends: ${marketTrends.toString()}
User question: $userQuestion

Provide a concise, informed response focused on answering the user's question based on their portfolio and current market trends.
''';
      
      // Generate content using Gemini
      final content = [Content.text(context)];
      final response = await _model!.generateContent(content);
      
      // Extract and return the response text
      if (response.text == null || response.text!.isEmpty) {
        return 'Sorry, I couldn\'t generate a response. Please try again with a different question.';
      }
      
      return response.text!;
    } catch (e) {
      debugPrint('Error generating investment advice: $e');
      
      // Return a more specific error message based on the error type
      if (e.toString().contains('API key')) {
        return 'Invalid API key. Please update your API key in Settings.';
      } else if (e.toString().contains('network')) {
        return 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        return 'Request timed out. Please try again later.';
      }
      
      return 'An error occurred: ${e.toString()}. Please try again later.';
    }
  }
  
  Future<List<Map<String, dynamic>>> generatePortfolioSuggestions({
    required Map<String, dynamic> currentPortfolio,
    required Map<String, dynamic> userPreferences,
    required List<Map<String, dynamic>> marketData,
  }) async {
    try {
      if (!_isModelInitialized || _model == null) {
        // Display a user-friendly message when no API key is set
        if (apiKey.isEmpty) {
          // Return an empty list but caller should check isModelInitialized
          return [];
        }
        
        // Try to initialize again
        _initializeModel();
        if (!_isModelInitialized || _model == null) {
          return [];
        }
      }
      
      // Prepare context for the model
      final context = '''
Current Portfolio: ${currentPortfolio.toString()}
User Preferences: ${userPreferences.toString()}
Market Data: ${marketData.toString()}
Generate portfolio optimization suggestions in JSON format.
''';
      
      // Generate content using Gemini
      final content = [Content.text(context)];
      final response = await _model!.generateContent(content);
      
      // Process and parse the response
      if (response.text != null) {
        try {
          // This is a simplified version. In practice, you would need a more robust parser
          // to extract and validate the JSON structure from the AI response
          final suggestions = [
            {'asset': 'Example Asset', 'action': 'Buy', 'reason': 'Based on market trends'},
            {'asset': 'Example Asset 2', 'action': 'Sell', 'reason': 'Overvalued based on metrics'}
          ];
          return suggestions;
        } catch (e) {
          debugPrint('Error parsing portfolio suggestions: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error generating portfolio suggestions: $e');
      return [];
    }
  }
  
  bool get isModelInitialized => _isModelInitialized && _model != null;
} 