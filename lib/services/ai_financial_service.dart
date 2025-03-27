import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIFinancialService {
  static const String _baseUrl = 'YOUR_CRUXOR_API_BASE_URL';
  final GenerativeModel _model;
  final storage = FlutterSecureStorage();

  AIFinancialService({required String geminiApiKey})
      : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: geminiApiKey,
        );

  Future<Map<String, dynamic>> analyzePortfolio(List<Map<String, dynamic>> assets) async {
    try {
      final prompt = '''
Analyze the following portfolio and provide recommendations:
${json.encode(assets)}

Consider:
1. Risk assessment
2. Portfolio diversification
3. Market trends
4. Technical indicators
5. Fundamental analysis
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return json.decode(response.text ?? '{}');
    } catch (e) {
      print('Error analyzing portfolio: $e');
      throw Exception('Failed to analyze portfolio');
    }
  }

  Future<Map<String, dynamic>> getStockRecommendations({
    required String riskLevel,
    required double investmentAmount,
    required List<String> preferredSectors,
  }) async {
    try {
      final apiKey = await storage.read(key: 'cruxor_api_key');
      if (apiKey == null) throw Exception('API key not found');

      // Get market data from Cruxor
      final response = await http.get(
        Uri.parse('$_baseUrl/market/recommendations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch market data');
      }

      final marketData = json.decode(response.body);

      // Generate AI recommendations
      final prompt = '''
Based on the following parameters, provide stock recommendations:
Risk Level: $riskLevel
Investment Amount: $investmentAmount
Preferred Sectors: ${preferredSectors.join(', ')}

Market Data: ${json.encode(marketData)}

Provide:
1. Top 5 stock recommendations
2. Risk assessment for each
3. Technical analysis summary
4. Entry/exit points
5. Portfolio allocation suggestions
''';

      final aiResponse = await _model.generateContent([Content.text(prompt)]);
      return json.decode(aiResponse.text ?? '{}');
    } catch (e) {
      print('Error getting recommendations: $e');
      throw Exception('Failed to generate recommendations');
    }
  }

  Future<Map<String, dynamic>> analyzeMarketSentiment(String symbol) async {
    try {
      final apiKey = await storage.read(key: 'cruxor_api_key');
      if (apiKey == null) throw Exception('API key not found');

      // Get news and social media data
      final response = await http.get(
        Uri.parse('$_baseUrl/sentiment/$symbol'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch sentiment data');
      }

      final sentimentData = json.decode(response.body);

      // Generate AI analysis
      final prompt = '''
Analyze the following market sentiment data for $symbol:
${json.encode(sentimentData)}

Provide:
1. Overall sentiment analysis
2. Key factors affecting sentiment
3. Potential market impact
4. Risk assessment
5. Trading recommendations
''';

      final aiResponse = await _model.generateContent([Content.text(prompt)]);
      return json.decode(aiResponse.text ?? '{}');
    } catch (e) {
      print('Error analyzing sentiment: $e');
      throw Exception('Failed to analyze market sentiment');
    }
  }

  Future<Map<String, dynamic>> getTechnicalAnalysis(String symbol) async {
    try {
      final apiKey = await storage.read(key: 'cruxor_api_key');
      if (apiKey == null) throw Exception('API key not found');

      // Get technical indicators
      final response = await http.get(
        Uri.parse('$_baseUrl/technical/$symbol'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch technical data');
      }

      final technicalData = json.decode(response.body);

      // Generate AI analysis
      final prompt = '''
Analyze the following technical indicators for $symbol:
${json.encode(technicalData)}

Provide:
1. Trend analysis
2. Support/resistance levels
3. Technical signals (RSI, MACD, etc.)
4. Volume analysis
5. Trading recommendations
''';

      final aiResponse = await _model.generateContent([Content.text(prompt)]);
      return json.decode(aiResponse.text ?? '{}');
    } catch (e) {
      print('Error analyzing technical indicators: $e');
      throw Exception('Failed to analyze technical indicators');
    }
  }

  Future<Map<String, dynamic>> getFundamentalAnalysis(String symbol) async {
    try {
      final apiKey = await storage.read(key: 'cruxor_api_key');
      if (apiKey == null) throw Exception('API key not found');

      // Get fundamental data
      final response = await http.get(
        Uri.parse('$_baseUrl/fundamental/$symbol'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch fundamental data');
      }

      final fundamentalData = json.decode(response.body);

      // Generate AI analysis
      final prompt = '''
Analyze the following fundamental data for $symbol:
${json.encode(fundamentalData)}

Provide:
1. Financial health assessment
2. Growth potential
3. Valuation analysis
4. Competitive position
5. Investment recommendations
''';

      final aiResponse = await _model.generateContent([Content.text(prompt)]);
      return json.decode(aiResponse.text ?? '{}');
    } catch (e) {
      print('Error analyzing fundamentals: $e');
      throw Exception('Failed to analyze fundamentals');
    }
  }
} 