import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Fixed API key - never ask users to enter this
  static const String _fixedApiKey = 'AIzaSyDm8A18yURmiRECFiI47Bn9zcTDGwNF2n0';

  // Backup API key if the first one fails
  static const String _backupApiKey = 'AIzaSyDm8A18yURmiRECFiI47Bn9zcTDGwNF2n0';

  late GenerativeModel _model;
  final Connectivity _connectivity = Connectivity();
  int _errorCount = 0;
  static const int _maxErrorCount = 3;
  String _currentApiKey;
  bool _usingBackupKey = false;

  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();
  
  factory GeminiService() {
    return _instance;
  }
  
  GeminiService._internal() 
      : _currentApiKey = _fixedApiKey {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _fixedApiKey,
    );
  }

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Try to switch to backup API key if primary fails
  Future<bool> _switchToBackupKey() async {
    if (_usingBackupKey) return false; // Already using backup
    
    try {
      _currentApiKey = _backupApiKey;
      
      // Recreate the model with the backup key
      final newModel = GenerativeModel(
        model: 'gemini-2.0',
        apiKey: _backupApiKey,
      );
      
      // Test the new key with a simple request
      final testResponse = await newModel.generateContent([
        Content.text('Hello'),
      ]);
      
      if (testResponse.text != null && testResponse.text!.isNotEmpty) {
        // Update the model reference if successful
        _model = newModel;
        _usingBackupKey = true;
        print('Successfully switched to backup API key');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Failed to switch to backup key: $e');
      return false;
    }
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
      
      // Reset error count on successful request
      _errorCount = 0;
      return response.text!;
    } catch (e) {
      print('Error initializing chat: $e');
      _errorCount++;
      
      // Try switching to backup key if API key is invalid
      if (e.toString().contains('Invalid API key')) {
        bool switched = await _switchToBackupKey();
        if (switched) {
          return startChat(); // Retry with new key
        }
      }
      
      if (e.toString().contains('No address associated with hostname')) {
        return "Unable to connect to the AI service. Please check your internet connection and try again.";
      } else if (e.toString().contains('Invalid API key')) {
        return "There was a problem with the AI service. Using backup service.";
      }
      
      // Return a friendly message regardless of error
      return "Hello! I'm your AI Financial Advisor. How can I help you with your financial decisions today?";
    }
  }

  Future<String> sendMessage(String message) async {
    if (_errorCount >= _maxErrorCount) {
      // After too many errors, use mock responses to avoid API quota issues
      return _getMockResponse(message);
    }
    
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

      // Reset error count on successful request
      _errorCount = 0;
      return response.text!;
    } catch (e) {
      print('Error processing message: $e');
      _errorCount++;
      
      // Try switching to backup key if API key is invalid
      if (e.toString().contains('Invalid API key') && !_usingBackupKey) {
        bool switched = await _switchToBackupKey();
        if (switched) {
          return sendMessage(message); // Retry with new key
        }
      }
      
      if (_errorCount >= _maxErrorCount) {
        return _getMockResponse(message);
      }
      
      if (e.toString().contains('No address associated with hostname')) {
        return "Unable to connect to the AI service. Please check your internet connection and try again.";
      } else if (e.toString().contains('Invalid API key')) {
        return "I'm having trouble accessing my knowledge. Let me try a different approach.";
      }
      return "I apologize, but I encountered an error processing your request. Please try again.";
    }
  }
  
  // Get stock recommendations using Gemini
  Future<List<Map<String, dynamic>>> getStockRecommendations() async {
    try {
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        return _getMockStockRecommendations();
      }

      final prompt = '''
Based on current market conditions, provide 5 stock recommendations in the following JSON format:
[
  {
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "recommendation": "Buy",
    "confidence": 85,
    "reason": "Strong product pipeline and services growth"
  },
  ...
]
Only respond with the JSON. No explanations or other text.
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      
      if (response.text == null || response.text!.isEmpty) {
        return _getMockStockRecommendations();
      }
      
      // Try to parse the JSON from the response
      try {
        // Extract JSON from response (removing any markdown code block syntax)
        String jsonText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final List<dynamic> parsed = jsonDecode(jsonText);
        return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        print('Error parsing recommendation JSON: $e');
        return _getMockStockRecommendations();
      }
    } catch (e) {
      print('Error getting stock recommendations: $e');
      return _getMockStockRecommendations();
    }
  }
  
  // Get financial tips using Gemini
  Future<List<Map<String, dynamic>>> getFinancialTips() async {
    try {
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        return _getMockFinancialTips();
      }

      final prompt = '''
Provide 5 actionable financial tips in the following JSON format:
[
  {
    "title": "Emergency Fund First",
    "description": "Build an emergency fund covering 3-6 months of expenses before investing",
    "category": "Savings"
  },
  ...
]
Only respond with the JSON. No explanations or other text.
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      
      if (response.text == null || response.text!.isEmpty) {
        return _getMockFinancialTips();
      }
      
      // Try to parse the JSON from the response
      try {
        // Extract JSON from response (removing any markdown code block syntax)
        String jsonText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final List<dynamic> parsed = jsonDecode(jsonText);
        return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        print('Error parsing tips JSON: $e');
        return _getMockFinancialTips();
      }
    } catch (e) {
      print('Error getting financial tips: $e');
      return _getMockFinancialTips();
    }
  }
  
  // Get market alerts using Gemini
  Future<List<Map<String, dynamic>>> getMarketAlerts() async {
    try {
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        return _getMockMarketAlerts();
      }

      final prompt = '''
Create 3 market alerts based on current market conditions in the following JSON format:
[
  {
    "title": "Tech Sector Correction",
    "description": "Technology stocks showing signs of a 5-7% correction in the coming weeks",
    "severity": "moderate",
    "impactedSectors": ["Technology", "Semiconductors"]
  },
  ...
]
Only respond with the JSON. No explanations or other text.
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      
      if (response.text == null || response.text!.isEmpty) {
        return _getMockMarketAlerts();
      }
      
      // Try to parse the JSON from the response
      try {
        // Extract JSON from response (removing any markdown code block syntax)
        String jsonText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final List<dynamic> parsed = jsonDecode(jsonText);
        return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        print('Error parsing alerts JSON: $e');
        return _getMockMarketAlerts();
      }
    } catch (e) {
      print('Error getting market alerts: $e');
      return _getMockMarketAlerts();
    }
  }
  
  // For calculating portfolio health score (0-100)
  Future<int> getPortfolioHealthScore(List<String> holdings) async {
    try {
      // In a real app, you would send the holdings to Gemini for analysis
      // For demo, we'll generate a random score between 60-95
      await Future.delayed(Duration(milliseconds: 800));
      return 60 + math.Random().nextInt(36);
    } catch (e) {
      return 75; // Default score on error
    }
  }
  
  String _getMockResponse(String message) {
    message = message.toLowerCase();
    
    if (message.contains('stock') || message.contains('invest') || message.contains('market')) {
      return "Based on current market conditions, diversification across multiple sectors is recommended. Consider allocating 60% to stocks, 30% to bonds, and 10% to alternative investments based on your risk tolerance.\n\nPlease note this is general advice - consult with a financial professional before making investment decisions.";
    } else if (message.contains('crypto') || message.contains('bitcoin') || message.contains('blockchain')) {
      return "Cryptocurrency remains a highly volatile asset class with significant risk. If considering crypto investments, limit exposure to 5-10% of your portfolio and focus on established cryptocurrencies.\n\nThis is simplified advice - please consult with a crypto specialist for personalized guidance.";
    } else if (message.contains('budget') || message.contains('save') || message.contains('spending')) {
      return "A useful budgeting approach is the 50/30/20 rule: 50% for necessities, 30% for wants, and 20% for savings and debt repayment. Track your expenses for 30 days to identify areas for potential savings.\n\nThis general advice may need adjustment based on your specific financial situation.";
    } else {
      return "Thank you for your question. For personalized financial advice, I recommend considering these principles:\n\n1. Diversify investments across different asset classes\n2. Maintain an emergency fund of 3-6 months of expenses\n3. Prioritize high-interest debt repayment\n4. Maximize tax-advantaged retirement accounts\n\nThis is general guidance - consider consulting with a financial advisor for advice tailored to your situation.";
    }
  }
  
  List<Map<String, dynamic>> _getMockStockRecommendations() {
    return [
      {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "recommendation": "Buy",
        "confidence": 85,
        "reason": "Strong product pipeline and services growth"
      },
      {
        "symbol": "MSFT",
        "name": "Microsoft Corporation",
        "recommendation": "Strong Buy",
        "confidence": 90,
        "reason": "Cloud business expansion and AI integration"
      },
      {
        "symbol": "GOOGL",
        "name": "Alphabet Inc.",
        "recommendation": "Buy",
        "confidence": 82,
        "reason": "Digital ad market recovery and AI advancements"
      },
      {
        "symbol": "AMZN",
        "name": "Amazon.com Inc.",
        "recommendation": "Buy",
        "confidence": 84,
        "reason": "AWS growth and retail margin improvements"
      },
      {
        "symbol": "NVDA",
        "name": "NVIDIA Corporation",
        "recommendation": "Hold",
        "confidence": 70,
        "reason": "AI demand strong but valuation concerns"
      }
    ];
  }
  
  List<Map<String, dynamic>> _getMockFinancialTips() {
    return [
      {
        "title": "Emergency Fund First",
        "description": "Build an emergency fund covering 3-6 months of expenses before investing heavily",
        "category": "Savings"
      },
      {
        "title": "Tax-Advantaged Accounts",
        "description": "Maximize contributions to 401(k)s and IRAs before using taxable accounts",
        "category": "Investing"
      },
      {
        "title": "Debt Snowball",
        "description": "Pay off smaller debts first to build momentum and motivation",
        "category": "Debt Management"
      },
      {
        "title": "Dollar-Cost Averaging",
        "description": "Invest a fixed amount regularly regardless of market conditions to reduce timing risk",
        "category": "Investing"
      },
      {
        "title": "Expense Tracking",
        "description": "Track all expenses for 30 days to identify spending patterns and potential savings",
        "category": "Budgeting"
      }
    ];
  }
  
  List<Map<String, dynamic>> _getMockMarketAlerts() {
    return [
      {
        "title": "Tech Sector Volatility",
        "description": "Technology stocks showing increased volatility due to interest rate uncertainty",
        "severity": "moderate",
        "impactedSectors": ["Technology", "Semiconductors"]
      },
      {
        "title": "Energy Sector Opportunity",
        "description": "Energy stocks undervalued relative to current commodity prices and demand forecasts",
        "severity": "low",
        "impactedSectors": ["Energy", "Utilities"]
      },
      {
        "title": "Inflation Concerns",
        "description": "Recent data suggests inflation may remain elevated, potentially impacting growth stocks",
        "severity": "high",
        "impactedSectors": ["Consumer Discretionary", "Technology", "Real Estate"]
      }
    ];
  }

  void dispose() {
    // Nothing to dispose
  }
} 