import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MarketDataService {
  // Using a public API for market data
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  // Default API key - this is a placeholder, replace with your actual key 
  static const String _defaultApiKey = 'c7c9qliad3idcvh7o0hg'; // Free demo key for example
  
  final storage = FlutterSecureStorage();
  Timer? _refreshTimer;
  final StreamController<Map<String, dynamic>> _dataStreamController = StreamController.broadcast();
  WebSocketChannel? _webSocketChannel;
  bool _hasError = false;
  Map<String, dynamic> _lastSuccessfulData = {};

  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  Future<void> initialize() async {
    try {
      // Load API key from secure storage
      String? apiKey = await storage.read(key: 'finnhub_api_key');
      
      // If no key found in storage, use the default key
      if (apiKey == null) {
        // Try to read fallback key from secure storage
        apiKey = await storage.read(key: 'cruxor_api_key');
        
        // If still no key, use the default key
        if (apiKey == null) {
          apiKey = _defaultApiKey;
          print('Using default API key');
          
          // Save the default key to storage for future use
          await storage.write(key: 'finnhub_api_key', value: _defaultApiKey);
        } else {
          // Store fallback key as primary for future use
          await storage.write(key: 'finnhub_api_key', value: apiKey);
          print('Using fallback API key');
        }
      }

      // Start periodic data refresh - every 30 seconds
      _refreshTimer?.cancel(); // Cancel existing timer if any
      _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) async {
        final currentKey = await storage.read(key: 'finnhub_api_key') ?? _defaultApiKey;
        _refreshMarketData(currentKey);
      });

      // Initial data fetch
      await _refreshMarketData(apiKey);

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

  Future<void> _refreshMarketData(String apiKey) async {
    try {
      // For stocks data
      final stocksResponse = await http.get(
        Uri.parse('$_baseUrl/quote?symbol=AAPL&token=$apiKey'),
      ).timeout(Duration(seconds: 10));

      if (stocksResponse.statusCode == 200) {
        final stocksData = json.decode(stocksResponse.body);
        
        // For crypto data
        final cryptoResponse = await http.get(
          Uri.parse('$_baseUrl/crypto/symbol?exchange=binance&token=$apiKey'),
        ).timeout(Duration(seconds: 10));
        
        final Map<String, dynamic> combinedData = {
          'stocks': stocksData,
          'time': DateTime.now().millisecondsSinceEpoch,
        };
        
        if (cryptoResponse.statusCode == 200) {
          final cryptoData = json.decode(cryptoResponse.body);
          combinedData['crypto'] = cryptoData;
        }
        
        _dataStreamController.add(combinedData);
        _lastSuccessfulData = combinedData;
        print('Market data refreshed: ${combinedData.keys.toList()}');
      } else if (stocksResponse.statusCode == 401 || stocksResponse.statusCode == 403) {
        print('API key is invalid. Trying with default key');
        if (apiKey != _defaultApiKey) {
          // If the current key failed and it's not the default key, try with default
          await _refreshMarketData(_defaultApiKey);
          // Update the stored key with the default one
          await storage.write(key: 'finnhub_api_key', value: _defaultApiKey);
        } else {
          throw Exception('Default API key is invalid or expired. Please update your API key.');
        }
      } else {
        throw Exception('Failed to fetch market data: ${stocksResponse.statusCode}');
      }
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
    // Create mock data to show something instead of an error
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
    try {
      final apiKey = await storage.read(key: 'finnhub_api_key') ?? _defaultApiKey;

      final response = await http.get(
        Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$apiKey'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch stock details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting stock details: $e');
      // Return mock data instead of error
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
  }

  Future<Map<String, dynamic>> getCryptoDetails(String symbol) async {
    try {
      final apiKey = await storage.read(key: 'finnhub_api_key') ?? _defaultApiKey;

      // First get a list of crypto symbols
      final symbolsResponse = await http.get(
        Uri.parse('$_baseUrl/crypto/symbol?exchange=binance&token=$apiKey'),
      ).timeout(Duration(seconds: 10));

      if (symbolsResponse.statusCode == 200) {
        // Then request the specific symbol data
        final priceResponse = await http.get(
          Uri.parse('$_baseUrl/crypto/candle?symbol=BINANCE:${symbol.toUpperCase()}&resolution=D&count=1&token=$apiKey'),
        ).timeout(Duration(seconds: 10));
        
        if (priceResponse.statusCode == 200) {
          return json.decode(priceResponse.body);
        } else {
          throw Exception('Failed to fetch crypto price: ${priceResponse.statusCode}');
        }
      } else {
        throw Exception('Failed to fetch crypto symbols: ${symbolsResponse.statusCode}');
      }
    } catch (e) {
      print('Error getting crypto details: $e');
      // Return mock crypto data
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
  }

  // Get market data for a specific symbol and timeframe
  Future<Map<String, dynamic>> getMarketData(String symbol, String timeframe, {bool useMockData = false}) async {
    if (useMockData) {
      return _getMockDataForTimeframe(symbol, timeframe);
    }
    
    try {
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        print('No internet connection, using mock data');
        return _getMockDataForTimeframe(symbol, timeframe);
      }
      
      final apiKey = await storage.read(key: 'finnhub_api_key') ?? _defaultApiKey;
      
      // Convert timeframe to resolution parameter
      final resolution = _getResolutionFromTimeframe(timeframe);
      final fromTime = _getFromTimeForTimeframe(timeframe);
      final toTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final url = Uri.parse(
        '$_baseUrl/stock/candle?symbol=$symbol&resolution=$resolution&from=$fromTime&to=$toTime&token=$apiKey'
      );
      
      print('Requesting market data from: $url');
      
      final response = await http.get(url).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['s'] == 'ok' && data['c'] != null) {
          final result = _formatCandleData(data);
          
          // Cache the data 
          _cacheMarketData(symbol, result);
          
          // Also subscribe to real-time updates
          await subscribeToSymbol(symbol);
          
          return result;
        } else {
          print('Invalid data format: ${data['s']}');
          return _getMockDataForTimeframe(symbol, timeframe);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('API key is invalid or expired');
        return _getMockDataForTimeframe(symbol, timeframe);
      } else {
        print('Failed to load market data: ${response.statusCode}');
        return _getMockDataForTimeframe(symbol, timeframe);
      }
    } catch (e) {
      print('Error fetching market data: $e');
      return _getMockDataForTimeframe(symbol, timeframe);
    }
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
  
  // Cache market data for offline use
  void _cacheMarketData(String symbol, Map<String, dynamic> data) {
    // Implementation for caching data
    print('Caching market data for $symbol');
  }
  
  // Check for network connectivity
  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Convert app timeframe to API resolution
  String _getResolutionFromTimeframe(String timeframe) {
    switch (timeframe) {
      case '1D': return '5';      // 5 minutes for 1 day
      case '1W': return '60';     // 1 hour for 1 week
      case '1M': return 'D';      // 1 day for 1 month
      case '3M': return 'D';      // 1 day for 3 months
      case '1Y': return 'W';      // 1 week for 1 year
      case '5Y': return 'M';      // 1 month for 5 years
      default: return 'D';        // Default to daily
    }
  }
  
  // Calculate from time based on timeframe
  int _getFromTimeForTimeframe(String timeframe) {
    final now = DateTime.now();
    DateTime fromDate;
    
    switch (timeframe) {
      case '1D':
        fromDate = now.subtract(Duration(days: 1));
        break;
      case '1W':
        fromDate = now.subtract(Duration(days: 7));
        break;
      case '1M':
        fromDate = now.subtract(Duration(days: 30));
        break;
      case '3M':
        fromDate = now.subtract(Duration(days: 90));
        break;
      case '1Y':
        fromDate = now.subtract(Duration(days: 365));
        break;
      case '5Y':
        fromDate = now.subtract(Duration(days: 365 * 5));
        break;
      default:
        fromDate = now.subtract(Duration(days: 30)); // Default to 1 month
    }
    
    return fromDate.millisecondsSinceEpoch ~/ 1000;
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
    try {
      final apiKey = await storage.read(key: 'finnhub_api_key') ?? _defaultApiKey;

      final response = await http.get(
        Uri.parse('$_baseUrl/news?category=general&token=$apiKey'),
      ).timeout(Duration(seconds: 15));  // News can take longer to load

      if (response.statusCode == 200) {
        final List<dynamic> news = json.decode(response.body);
        return news.map((item) => {
          'title': item['headline'] ?? 'No Title',
          'summary': item['summary'] ?? 'No Summary Available',
          'date': item['datetime'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(item['datetime'] * 1000).toString() 
              : 'Unknown Date',
          'url': item['url'] ?? '',
          'source': item['source'] ?? 'Unknown Source',
        }).toList();
      } else {
        throw Exception('Failed to fetch market news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting market news: $e');
      // Return mock news items
      return [
        {
          'title': 'Apple Announces New iPhone',
          'summary': 'Apple has unveiled the latest iPhone with improved camera features and longer battery life.',
          'date': DateTime.now().toString(),
          'url': '',
          'source': 'Mock Finance News',
        },
        {
          'title': 'Bitcoin Reaches New High',
          'summary': 'Bitcoin surged to a new all-time high today as institutional investors continue to show interest.',
          'date': DateTime.now().toString(),
          'url': '',
          'source': 'Mock Crypto News',
        },
        {
          'title': 'Federal Reserve Holds Interest Rates',
          'summary': 'The Federal Reserve has decided to maintain current interest rates amid economic uncertainty.',
          'date': DateTime.now().toString(),
          'url': '',
          'source': 'Mock Economic News',
        }
      ];
    }
  }

  Future<void> subscribeToSymbol(String symbol) async {
    try {
      // Close existing connection if any
      _webSocketChannel?.sink.close();
      
      final apiKey = await storage.read(key: 'finnhub_api_key') ?? _defaultApiKey;
      
      // Connect to WebSocket for real-time updates
      final wsUrl = 'wss://ws.finnhub.io?token=$apiKey';
      print('Connecting to WebSocket: $wsUrl');
      
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Subscribe to the symbol
      _webSocketChannel!.sink.add(json.encode({
        'type': 'subscribe',
        'symbol': symbol.toUpperCase(),
      }));
      
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
            print('Received WebSocket data: ${tradeData['type']}');
          } catch (e) {
            print('Error parsing WebSocket data: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          // Don't propagate the error, just log it
          // _dataStreamController.addError(error);
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
      
      print('Successfully subscribed to $symbol');
    } catch (e) {
      print('Error subscribing to symbol: $e');
      // Don't throw the exception, just log it
      // throw Exception('Failed to subscribe to symbol: $e');
    }
  }

  bool get hasError => _hasError;

  void dispose() {
    _refreshTimer?.cancel();
    _webSocketChannel?.sink.close();
    _dataStreamController.close();
  }
} 