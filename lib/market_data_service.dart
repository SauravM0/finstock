import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class MarketDataService {
  WebSocketChannel? _channel;
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  String _currentSymbol = 'btcusdt';
  Timer? _reconnectTimer;
  
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;

  Future<void> initialize() async {
    try {
      await _connectWebSocket();
      
      // Initialize with some mock data while waiting for real data
      _dataController.add({
        'isMock': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'lastPrice': 29500.0,
        'symbol': 'BTCUSDT',
      });
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
      // Add mock data when connection fails
      _addMockMarketData();
      rethrow;
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://stream.binance.com:9443/ws/${_currentSymbol}@trade'),
      );
      
      _channel?.stream.listen(
        (data) {
          try {
            final jsonData = json.decode(data.toString());
            final processedData = {
              'isMock': false,
              'timestamp': jsonData['T'] ?? DateTime.now().millisecondsSinceEpoch,
              'lastPrice': double.tryParse(jsonData['p'] ?? '0') ?? 0.0,
              'symbol': jsonData['s'] ?? _currentSymbol.toUpperCase(),
              'quantity': double.tryParse(jsonData['q'] ?? '0') ?? 0.0,
            };
            
            _dataController.add(processedData);
            _isConnected = true;
          } catch (e) {
            print('Error processing WebSocket data: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
      rethrow;
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () async {
      if (!_isConnected) {
        print('Attempting to reconnect WebSocket...');
        try {
          await _connectWebSocket();
        } catch (e) {
          print('Reconnection failed: $e');
          _addMockMarketData();
        }
      }
    });
  }

  void _addMockMarketData() {
    final mockData = {
      'isMock': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'lastPrice': _currentSymbol.contains('btc') ? 29500.0 : 
                  _currentSymbol.contains('eth') ? 1850.0 : 100.0,
      'symbol': _currentSymbol.toUpperCase(),
    };
    
    _dataController.add(mockData);
  }

  Future<void> subscribeToSymbol(String symbol) async {
    if (_channel == null) {
      throw Exception('WebSocket not initialized');
    }

    final normalizedSymbol = symbol.toLowerCase();
    
    // Only change subscription if it's a different symbol
    if (normalizedSymbol != _currentSymbol) {
      _currentSymbol = normalizedSymbol;
      
      // Close existing connection
      _channel?.sink.close();
      
      // Create new connection with the updated symbol
      try {
        await _connectWebSocket();
      } catch (e) {
        print('Failed to subscribe to new symbol: $e');
        _addMockMarketData();
      }
    }
  }

  Future<List<Map<String, dynamic>>> getMarketNews() async {
    try {
      // In a real app, this would call a news API
      // For demo purposes, we'll return mock news
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      
      return [
        {
          'title': 'Market Rally Continues as Tech Stocks Surge',
          'description': 'Technology stocks led a broad market rally today as investors responded positively to better-than-expected earnings reports.',
          'timestamp': DateTime.now().subtract(Duration(hours: 2)).toString(),
          'source': 'Financial Times',
          'url': 'https://www.ft.com',
        },
        {
          'title': 'Bitcoin Breaks $30,000 Barrier Again',
          'description': 'Bitcoin surged past $30,000 today, reaching its highest level in months amid growing institutional adoption.',
          'timestamp': DateTime.now().subtract(Duration(hours: 5)).toString(),
          'source': 'CryptoNews',
          'url': 'https://www.cryptonews.com',
        },
        {
          'title': 'Federal Reserve Signals Potential Rate Cut',
          'description': 'The Federal Reserve has indicated it may consider cutting interest rates in the coming months if inflation continues to cool.',
          'timestamp': DateTime.now().subtract(Duration(hours: 8)).toString(),
          'source': 'Wall Street Journal',
          'url': 'https://www.wsj.com',
        },
      ];
    } catch (e) {
      print('Error fetching market news: $e');
      rethrow;
    }
  }

  void listenForUpdates(Function(Map<String, dynamic>) callback) {
    dataStream.listen(callback);
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _dataController.close();
  }
}