import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MarketDataService {
  static const String _baseUrl = 'YOUR_CRUXOR_API_BASE_URL';
  final storage = FlutterSecureStorage();
  Timer? _refreshTimer;
  final StreamController<Map<String, dynamic>> _dataStreamController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  Future<void> initialize() async {
    // Load API key from secure storage
    final apiKey = await storage.read(key: 'cruxor_api_key');
    if (apiKey == null) {
      throw Exception('API key not found');
    }

    // Start periodic data refresh
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _refreshMarketData(apiKey);
    });

    // Initial data fetch
    await _refreshMarketData(apiKey);
  }

  Future<void> _refreshMarketData(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/market/data'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _dataStreamController.add(data);
      } else {
        throw Exception('Failed to fetch market data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching market data: $e');
      _dataStreamController.addError(e);
    }
  }

  Future<Map<String, dynamic>> getStockDetails(String symbol) async {
    final apiKey = await storage.read(key: 'cruxor_api_key');
    if (apiKey == null) {
      throw Exception('API key not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/stock/$symbol'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch stock details');
    }
  }

  Future<Map<String, dynamic>> getCryptoDetails(String symbol) async {
    final apiKey = await storage.read(key: 'cruxor_api_key');
    if (apiKey == null) {
      throw Exception('API key not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/crypto/$symbol'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch crypto details');
    }
  }

  Future<List<Map<String, dynamic>>> getMarketNews() async {
    final apiKey = await storage.read(key: 'cruxor_api_key');
    if (apiKey == null) {
      throw Exception('API key not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/news'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> news = json.decode(response.body);
      return news.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch market news');
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _dataStreamController.close();
  }
} 