import 'dart:async';

class TradeResult {
  final bool success;
  final String message;
  final String symbol;
  final double quantity;
  final double price;
  final double totalAmount;
  final DateTime timestamp;
  
  const TradeResult({
    required this.success,
    required this.message,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.timestamp,
  });
  
  factory TradeResult.success({
    required String symbol,
    required double quantity,
    required double price,
    required String action,
  }) {
    final totalAmount = quantity * price;
    return TradeResult(
      success: true,
      message: '$action ${quantity.toStringAsFixed(2)} shares of $symbol at \$${price.toStringAsFixed(2)} per share',
      symbol: symbol,
      quantity: quantity,
      price: price,
      totalAmount: totalAmount,
      timestamp: DateTime.now(),
    );
  }
  
  factory TradeResult.failure({
    required String symbol,
    required double quantity,
    required double price,
    required String reason,
  }) {
    return TradeResult(
      success: false,
      message: 'Trade failed: $reason',
      symbol: symbol,
      quantity: quantity,
      price: price,
      totalAmount: quantity * price,
      timestamp: DateTime.now(),
    );
  }
}

class TradingService {
  // Mock method to buy stock
  Future<TradeResult> buyStock(String symbol, double quantity, double price) async {
    // Simulate network request
    await Future.delayed(Duration(milliseconds: 300));
    
    // In a real app, this would call an API to place an order
    // For this mock implementation, we'll simulate a successful trade
    
    if (quantity <= 0) {
      return TradeResult.failure(
        symbol: symbol,
        quantity: quantity,
        price: price,
        reason: 'Quantity must be greater than 0',
      );
    }
    
    return TradeResult.success(
      symbol: symbol,
      quantity: quantity,
      price: price,
      action: 'Bought',
    );
  }
  
  // Mock method to sell stock
  Future<TradeResult> sellStock(String symbol, double quantity, double price) async {
    // Simulate network request
    await Future.delayed(Duration(milliseconds: 300));
    
    // In a real app, this would call an API to place a sell order
    if (quantity <= 0) {
      return TradeResult.failure(
        symbol: symbol,
        quantity: quantity,
        price: price,
        reason: 'Quantity must be greater than 0',
      );
    }
    
    return TradeResult.success(
      symbol: symbol,
      quantity: quantity,
      price: price,
      action: 'Sold',
    );
  }
} 