import 'package:flutter/foundation.dart';
import '../models/holding.dart';
import '../services/market_data_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final MarketDataService _marketDataService;
  List<Holding> _holdings = [];
  double _cashBalance = 10000.0; // Starting with $10,000 cash
  
  // Getters
  List<Holding> get holdings => _holdings;
  double get cashBalance => _cashBalance;
  
  // Constructor
  PortfolioProvider({required MarketDataService marketDataService}) 
      : _marketDataService = marketDataService;
  
  // Buy stock
  Future<bool> buyStock(String symbol, double quantity, double price) async {
    if (quantity <= 0 || price <= 0) {
      return false;
    }
    
    final totalCost = quantity * price;
    
    // Check if user has enough cash
    if (totalCost > _cashBalance) {
      return false;
    }
    
    // Update cash balance
    _cashBalance -= totalCost;
    
    // Check if the user already owns this stock
    final existingHoldingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
    
    if (existingHoldingIndex >= 0) {
      // Update existing holding
      final existingHolding = _holdings[existingHoldingIndex];
      _holdings[existingHoldingIndex] = Holding.combine(existingHolding, quantity, price);
    } else {
      // Add new holding
      _holdings.add(Holding(
        symbol: symbol,
        quantity: quantity,
        averageCost: price,
      ));
    }
    
    notifyListeners();
    return true;
  }
  
  // Sell stock
  Future<bool> sellStock(String symbol, double quantity, double price) async {
    if (quantity <= 0 || price <= 0) {
      return false;
    }
    
    // Find the holding
    final existingHoldingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
    
    if (existingHoldingIndex < 0) {
      return false; // User doesn't own this stock
    }
    
    final existingHolding = _holdings[existingHoldingIndex];
    
    // Check if user has enough shares to sell
    if (existingHolding.quantity < quantity) {
      return false;
    }
    
    // Update cash balance
    _cashBalance += quantity * price;
    
    // Update holdings
    final remainingQuantity = existingHolding.quantity - quantity;
    
    if (remainingQuantity > 0) {
      // Update the holding with reduced quantity
      _holdings[existingHoldingIndex] = existingHolding.copyWith(
        quantity: remainingQuantity,
      );
    } else {
      // Remove the holding if no shares left
      _holdings.removeAt(existingHoldingIndex);
    }
    
    notifyListeners();
    return true;
  }
  
  // Add cash to account
  void addCash(double amount) {
    if (amount > 0) {
      _cashBalance += amount;
      notifyListeners();
    }
  }
  
  // Get current portfolio value
  Future<double> getTotalPortfolioValue() async {
    double totalValue = _cashBalance;
    
    // This could be optimized to batch fetch current prices
    for (var holding in _holdings) {
      try {
        // In a real app, get the current price from the market data service
        // For now, we'll use a mock price (current price = average cost * random factor)
        final currentPrice = holding.averageCost * (0.9 + (0.2 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
        totalValue += holding.quantity * currentPrice;
      } catch (e) {
        // Fallback to average cost if current price is unavailable
        totalValue += holding.totalCost;
      }
    }
    
    return totalValue;
  }
  
  // For demo purposes, add some initial holdings
  void addSampleHoldings() {
    _holdings = [
      Holding(symbol: 'AAPL', quantity: 10, averageCost: 180.0),
      Holding(symbol: 'MSFT', quantity: 5, averageCost: 350.0),
      Holding(symbol: 'GOOGL', quantity: 3, averageCost: 140.0),
    ];
    _cashBalance = 5000.0;
    notifyListeners();
  }
} 