import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MarketDataService {
  final storage = FlutterSecureStorage();
  Timer? _refreshTimer;
  final StreamController<Map<String, dynamic>> _dataStreamController = StreamController.broadcast();
  WebSocketChannel? _webSocketChannel;
  bool _hasError = false;
  Map<String, dynamic> _lastSuccessfulData = {};

  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  Future<void> initialize() async {
    try {
      // Start periodic data refresh - every 30 seconds
      _refreshTimer?.cancel(); // Cancel existing timer if any
      _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) async {
        _refreshMarketData();
      });

      // Initial data fetch
      await _refreshMarketData();

      // Subscribe to market data updates
      await subscribeToSymbol('btcusdt');
      
      // Reset error flag if we get here
      _hasError = false;
    } catch (e) {
      _hasError = true;
      print('Failed to initialize market data service: $e');
      rethrow;
    }
  }

  Future<void> _refreshMarketData() async {
    try {
      // Generate mock data for display purposes
      final mockData = _createMockMarketData();
      
      _dataStreamController.add(mockData);
      _lastSuccessfulData = mockData;
      print('Market data refreshed: ${mockData.keys.toList()}');
    } catch (e) {
      print('Error fetching market data: $e');
      
      // If we have last successful data, use it as fallback
      if (_lastSuccessfulData.isNotEmpty) {
        // Add a flag to indicate this is cached data
        _lastSuccessfulData['isCached'] = true;
        _lastSuccessfulData['cacheTime'] = DateTime.now().millisecondsSinceEpoch;
        _dataStreamController.add(_lastSuccessfulData);
        print('Using cached market data');
      } else {
        // Create mock data as a last resort
        final mockData = _createMockMarketData();
        mockData['isMock'] = true;
        _dataStreamController.add(mockData);
        print('Using mock market data');
      }
    }
  }

  Map<String, dynamic> _createMockMarketData() {
    // Create mock data to show something while TradingView loads
    return {
      'stocks': {
        'c': 147.56, // current price
        'h': 148.21, // high price
        'l': 146.08, // low price
        'o': 146.35, // open price
        'pc': 146.18, // previous close
        'dp': 0.95, // percent change
      },
      'time': DateTime.now().millisecondsSinceEpoch,
      'isCached': false,
      'isMock': true
    };
  }

  Future<Map<String, dynamic>> getStockDetails(String symbol) async {
    // Return mock data - TradingView will handle actual data display
    return {
      'c': 158.4, // current price
      'h': 159.1, // high price
      'l': 157.3, // low price
      'o': 157.5, // open price
      'pc': 158.1, // previous close
      'dp': 0.32, // percent change
      'symbol': symbol,
      'isMock': true
    };
  }

  Future<Map<String, dynamic>> getCryptoDetails(String symbol) async {
    // Return mock data - TradingView will handle actual data display
    return {
      'c': [19823.45], // close prices
      'h': [20145.67], // high prices
      'l': [19712.33], // low prices
      'o': [19755.88], // open prices
      'v': [1256.78], // volumes
      't': [DateTime.now().millisecondsSinceEpoch ~/ 1000], // timestamps
      's': 'ok', // status
      'symbol': symbol,
      'isMock': true
    };
  }

  // Get market data for a specific symbol and timeframe
  Future<Map<String, dynamic>> getMarketData(String symbol, String timeframe, {bool useMockData = false}) async {
    // Always return mock data - actual data will be displayed by TradingView widget
    return _getMockDataForTimeframe(symbol, timeframe);
  }
  
  // Format candle data into a consistent format
  Map<String, dynamic> _formatCandleData(Map<String, dynamic> data) {
    return {
      'time': data['t'] != null ? (data['t'] as List).map((t) => t * 1000).toList() : [],
      'open': data['o'] ?? [],
      'high': data['h'] ?? [],
      'low': data['l'] ?? [],
      'close': data['c'] ?? [],
      'volume': data['v'] ?? [],
    };
  }
  
  // Check for network connectivity
  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Generate mock data for different timeframes
  Map<String, dynamic> _getMockDataForTimeframe(String symbol, String timeframe) {
    final now = DateTime.now();
    
    // Base price values for different symbols
    double basePrice;
    switch (symbol) {
      case 'AAPL':
        basePrice = 175.0;
        break;
      case 'MSFT':
        basePrice = 380.0;
        break;
      case 'GOOGL':
        basePrice = 140.0;
        break;
      case 'AMZN':
        basePrice = 180.0;
        break;
      default:
        basePrice = 100.0;
    }
    
    // Number of data points based on timeframe
    int dataPoints;
    switch (timeframe) {
      case '1D':
        dataPoints = 24 * 4;    // Every 15 minutes
        break;
      case '1W':
        dataPoints = 7 * 8;     // Every 3 hours
        break;
      case '1M':
        dataPoints = 30;        // Daily
        break;
      case '3M':
        dataPoints = 90;        // Daily
        break;
      case '1Y':
        dataPoints = 52;        // Weekly
        break;
      case '5Y':
        dataPoints = 60;        // Monthly
        break;
      default:
        dataPoints = 30;        // Default to daily
    }
    
    // Volatility factor based on timeframe
    double volatility;
    switch (timeframe) {
      case '1D':
        volatility = 0.003;
        break;
      case '1W':
        volatility = 0.007;
        break;
      case '1M':
        volatility = 0.02;
        break;
      case '3M':
        volatility = 0.05;
        break;
      case '1Y':
        volatility = 0.1;
        break;
      case '5Y':
        volatility = 0.3;
        break;
      default:
        volatility = 0.02;
    }
    
    // Time interval in milliseconds
    int timeInterval;
    switch (timeframe) {
      case '1D':
        timeInterval = Duration(minutes: 15).inMilliseconds;
        break;
      case '1W':
        timeInterval = Duration(hours: 3).inMilliseconds;
        break;
      case '1M':
        timeInterval = Duration(days: 1).inMilliseconds;
        break;
      case '3M':
        timeInterval = Duration(days: 1).inMilliseconds;
        break;
      case '1Y':
        timeInterval = Duration(days: 7).inMilliseconds;
        break;
      case '5Y':
        timeInterval = Duration(days: 30).inMilliseconds;
        break;
      default:
        timeInterval = Duration(days: 1).inMilliseconds;
    }
    
    // Generate time points
    final times = List<int>.generate(
      dataPoints,
      (i) => now.subtract(Duration(milliseconds: (dataPoints - 1 - i) * timeInterval)).millisecondsSinceEpoch
    );
    
    // Generate price data with some randomness and trending
    double currentPrice = basePrice;
    final trend = (now.millisecondsSinceEpoch % 2 == 0) ? 1.0 : -1.0;
    final trendStrength = volatility * 10;
    
    final opens = <double>[];
    final highs = <double>[];
    final lows = <double>[];
    final closes = <double>[];
    final volumes = <double>[];
    
    for (int i = 0; i < dataPoints; i++) {
      // Generate random changes with trend
      final randomFactor = (i * 17 % 100) / 100.0 - 0.5;
      final trendFactor = trend * trendStrength * (i / dataPoints);
      final dayChange = currentPrice * volatility * randomFactor + currentPrice * trendFactor;
      
      final open = currentPrice;
      final close = currentPrice + dayChange;
      final high = math.max(open, close) + currentPrice * volatility * 0.5 * ((i * 31) % 100) / 100.0;
      final low = math.min(open, close) - currentPrice * volatility * 0.5 * ((i * 23) % 100) / 100.0;
      final volume = basePrice * 100000 * (0.5 + ((i * 13) % 100) / 50.0);
      
      opens.add(open);
      highs.add(high);
      lows.add(low);
      closes.add(close);
      volumes.add(volume);
      
      currentPrice = close;
    }
    
    return {
      'time': times,
      'open': opens,
      'high': highs,
      'low': lows,
      'close': closes,
      'volume': volumes,
      'isMock': true,
    };
  }

  Future<List<Map<String, dynamic>>> getMarketNews() async {
    // Return mock news items - no more API calls
    return [
      {
        'title': 'Apple Announces New iPhone',
        'summary': 'Apple has unveiled the latest iPhone with improved camera features and longer battery life.',
        'date': DateTime.now().toString(),
        'url': '',
        'source': 'Market News',
      },
      {
        'title': 'Bitcoin Reaches New High',
        'summary': 'Bitcoin surged to a new all-time high today as institutional investors continue to show interest.',
        'date': DateTime.now().toString(),
        'url': '',
        'source': 'Crypto News',
      },
      {
        'title': 'Federal Reserve Holds Interest Rates',
        'summary': 'The Federal Reserve has decided to maintain current interest rates amid economic uncertainty.',
        'date': DateTime.now().toString(),
        'url': '',
        'source': 'Economic News',
      }
    ];
  }

  Future<void> subscribeToSymbol(String symbol) async {
    try {
      // Close existing connection if any
      _webSocketChannel?.sink.close();
      
      // Only connect to Binance WebSocket for crypto symbols
      if (symbol.toLowerCase().contains('btc') || symbol.toLowerCase().contains('eth')) {
        final wsUrl = 'wss://stream.binance.com:9443/ws/${symbol.toLowerCase()}@trade';
        print('Connecting to WebSocket: $wsUrl');
        
        _webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
        
        _webSocketChannel!.stream.listen(
          (dynamic data) {
            try {
              // Parse the data
              Map<String, dynamic> tradeData;
              if (data is String) {
                tradeData = json.decode(data);
              } else if (data is Map) {
                tradeData = Map<String, dynamic>.from(data);
              } else {
                throw Exception('Unexpected data type: ${data.runtimeType}');
              }
              
              // Add to the data stream
              _dataStreamController.add(tradeData);
              print('Received WebSocket data for $symbol');
            } catch (e) {
              print('Error parsing WebSocket data: $e');
            }
          },
          onError: (error) {
            print('WebSocket error: $error');
          },
          onDone: () {
            print('WebSocket connection closed');
          },
        );
        
        print('Successfully subscribed to $symbol');
      } else {
        // For stock symbols, just update with mock data
        final mockData = _createMockMarketData();
        _dataStreamController.add(mockData);
      }
    } catch (e) {
      print('Error subscribing to symbol: $e');
      
      // Use mock data on error
      final mockData = _createMockMarketData();
      mockData['isMock'] = true;
      _dataStreamController.add(mockData);
    }
  }

  bool get hasError => _hasError;

  void dispose() {
    _refreshTimer?.cancel();
    _webSocketChannel?.sink.close();
    _dataStreamController.close();
  }
} 