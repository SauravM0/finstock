import 'package:web_socket_channel/web_socket_channel.dart';

class MarketDataService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? _onDataCallback;

  Future<void> initialize() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://stream.binance.com:9443/ws/btcusdt@trade'),
      );
      
      _channel?.stream.listen(
        (data) {
          if (_onDataCallback != null) {
            _onDataCallback!(data as Map<String, dynamic>);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
      rethrow;
    }
  }

  Future<void> subscribeToSymbol(String symbol) async {
    if (_channel == null) {
      throw Exception('WebSocket not initialized');
    }

    // Unsubscribe from previous symbol if any
    _channel?.sink.add({
      'method': 'UNSUBSCRIBE',
      'params': ['btcusdt@trade'],
      'id': 1,
    });

    // Subscribe to new symbol
    _channel?.sink.add({
      'method': 'SUBSCRIBE',
      'params': ['${symbol.toLowerCase()}@trade'],
      'id': 2,
    });
  }

  void listenForUpdates(Function(Map<String, dynamic>) callback) {
    _onDataCallback = callback;
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    _onDataCallback = null;
  }
}