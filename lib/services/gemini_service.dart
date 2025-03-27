import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GeminiService {
  static const String _basePrompt = '''
You are a specialized financial advisor AI assistant. Your responses should be:
1. Professional and clear
2. Based on factual financial knowledge
3. Include specific examples and numbers when relevant
4. Always consider risk factors
5. Mention that this is AI-generated advice and recommend consulting with financial professionals for major decisions

Key areas of expertise:
- Stock market analysis and investment strategies
- Cryptocurrency trends and blockchain technology
- Portfolio optimization and risk management
- Personal finance and budgeting
- Market trend analysis
- Tax implications of investments

When giving advice:
1. Start with a brief, direct answer
2. Provide supporting details and explanation
3. Include relevant market data or statistics if applicable
4. Discuss potential risks and alternatives
5. End with actionable steps or recommendations
''';

  final GenerativeModel _model;
  final Connectivity _connectivity = Connectivity();

  GeminiService({required String apiKey}) 
      : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
        );

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<String> startChat() async {
    try {
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        return "No internet connection. Please check your network settings and try again.";
      }

      final response = await _model.generateContent([
        Content.text(_basePrompt),
        Content.text('Hello, I need financial advice.'),
      ]);
      
      if (response.text == null || response.text!.isEmpty) {
        return "Hello! I'm your AI Financial Advisor. I can help you with investment strategies, market analysis, and personal finance decisions. What would you like to know?";
      }
      
      return response.text!;
    } catch (e) {
      print('Error initializing chat: $e');
      if (e.toString().contains('No address associated with hostname')) {
        return "Unable to connect to the AI service. Please check your internet connection and try again.";
      } else if (e.toString().contains('Invalid API key')) {
        return "Invalid API key. Please check your configuration and try again.";
      }
      return "Hello! I'm your AI Financial Advisor. How can I help you with your financial decisions today?";
    }
  }

  Future<String> sendMessage(String message) async {
    try {
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        return "No internet connection. Please check your network settings and try again.";
      }

      final response = await _model.generateContent([
        Content.text(_basePrompt),
        Content.text(message),
      ]);
      
      if (response.text == null || response.text!.isEmpty) {
        return "I apologize, but I couldn't generate a response. Please try rephrasing your question.";
      }

      return response.text!;
    } catch (e) {
      print('Error processing message: $e');
      if (e.toString().contains('No address associated with hostname')) {
        return "Unable to connect to the AI service. Please check your internet connection and try again.";
      } else if (e.toString().contains('Invalid API key')) {
        return "Invalid API key. Please check your configuration and try again.";
      }
      return "I apologize, but I encountered an error processing your request. Please try again.";
    }
  }

  void dispose() {}
} 