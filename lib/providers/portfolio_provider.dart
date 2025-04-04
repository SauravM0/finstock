import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import '../services/market_data_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final MarketDataService _marketDataService;
  List<Holding> _holdings = [];
  List<Transaction> _transactions = [];
  double _cashBalance = 10000.0; // Starting with $10,000 cash
  bool _isLoading = true;
  String _error = '';
  
  // Getters
  List<Holding> get holdings => _holdings;
  List<Transaction> get transactions => _transactions;
  double get cashBalance => _cashBalance;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;
  
  // Constants for SharedPreferences keys
  static const String _transactionsKey = 'transactions';
  static const String _holdingsKey = 'holdings';
  static const String _cashBalanceKey = 'cash_balance';
  
  // Constructor
  PortfolioProvider({required MarketDataService marketDataService}) 
      : _marketDataService = marketDataService {
    _loadData();
  }
  
  // Load data from SharedPreferences
  Future<void> _loadData() async {
    try {
      _setLoading(true);
      _clearError();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load transactions
      final transactionsJson = prefs.getString(_transactionsKey);
      if (transactionsJson != null) {
        _transactions = Transaction.listFromJson(transactionsJson);
      }
      
      // Load cash balance
      final cashBalance = prefs.getDouble(_cashBalanceKey);
      if (cashBalance != null) {
        _cashBalance = cashBalance;
      }
      
      // We'll recalculate holdings based on transactions in a real app,
      // but for now just use sample data if no transactions exist
      if (_transactions.isEmpty) {
        addSampleHoldings();
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load portfolio data: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save transactions
      await prefs.setString(_transactionsKey, Transaction.listToJson(_transactions));
      
      // Save cash balance
      await prefs.setDouble(_cashBalanceKey, _cashBalance);
    } catch (e) {
      print('Error saving portfolio data: $e');
      // Don't set error state here as it might disrupt the UI
    }
  }
  
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
    
    try {
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
      
      // Record transaction
      final transaction = Transaction(
        symbol: symbol,
        action: 'buy',
        quantity: quantity,
        price: price,
        totalAmount: totalCost,
        timestamp: DateTime.now(),
      );
      
      _transactions.add(transaction);
      
      // Save data to storage
      await _saveData();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error buying stock: $e');
      return false;
    }
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
    
    try {
      final totalSaleAmount = quantity * price;
      
      // Update cash balance
      _cashBalance += totalSaleAmount;
      
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
      
      // Record transaction
      final transaction = Transaction(
        symbol: symbol,
        action: 'sell',
        quantity: quantity,
        price: price,
        totalAmount: totalSaleAmount,
        timestamp: DateTime.now(),
      );
      
      _transactions.add(transaction);
      
      // Save data to storage
      await _saveData();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error selling stock: $e');
      return false;
    }
  }
  
  // Add cash to account
  Future<void> addCash(double amount) async {
    if (amount <= 0) return;
    
    try {
      _cashBalance += amount;
      
      // Record transaction
      final transaction = Transaction(
        symbol: 'CASH',
        action: 'deposit',
        quantity: 1,
        price: amount,
        totalAmount: amount,
        timestamp: DateTime.now(),
      );
      
      _transactions.add(transaction);
      
      // Save data to storage
      await _saveData();
      
      notifyListeners();
    } catch (e) {
      print('Error adding cash: $e');
    }
  }
  
  // Get transactions for a specific symbol
  List<Transaction> getTransactionsForSymbol(String symbol) {
    return _transactions.where((t) => t.symbol == symbol).toList();
  }
  
  // Get recent transactions - last 30 days by default
  List<Transaction> getRecentTransactions({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _transactions
        .where((t) => t.timestamp.isAfter(cutoffDate))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Latest first
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
  
  // Get portfolio performance (simplified for mock)
  Map<String, double> getPortfolioPerformance() {
    // This would involve a more complex calculation in a real app
    // For our demo, we'll return mock performance data
    return {
      'daily': (_getRandomPerformance() * 0.01), // e.g., 0.02 (2%)
      'weekly': (_getRandomPerformance() * 0.03),
      'monthly': (_getRandomPerformance() * 0.05),
      'yearly': (_getRandomPerformance() * 0.12),
    };
  }
  
  // Helper to generate slightly random performance numbers
  double _getRandomPerformance() {
    final base = DateTime.now().millisecond % 10;
    if (base < 3) return -1.0 * (base + 1);  // 30% chance negative
    return base / 2.0;  // 70% chance positive
  }
  
  // Add sample holdings for demonstration purposes
  void addSampleHoldings() {
    _holdings = [
      Holding(
        symbol: 'AAPL',
        quantity: 10,
        averageCost: 180.0,
        sector: 'Technology',
        currentPrice: 188.52,
      ),
      Holding(
        symbol: 'MSFT',
        quantity: 5,
        averageCost: 330.0,
        sector: 'Technology',
        currentPrice: 337.30,
      ),
      Holding(
        symbol: 'GOOGL',
        quantity: 8,
        averageCost: 135.0,
        sector: 'Technology',
        currentPrice: 141.80,
      ),
      Holding(
        symbol: 'AMZN',
        quantity: 4,
        averageCost: 120.0,
        sector: 'Consumer Cyclical',
        currentPrice: 125.25,
      ),
      Holding(
        symbol: 'JPM',
        quantity: 7,
        averageCost: 145.0,
        sector: 'Financials',
        currentPrice: 151.42,
      ),
      Holding(
        symbol: 'JNJ',
        quantity: 6,
        averageCost: 160.0,
        sector: 'Healthcare',
        currentPrice: 152.95,
      ),
    ];
    
    // Create corresponding transactions for these holdings
    _transactions = [
      Transaction(
        symbol: 'AAPL',
        action: 'buy',
        quantity: 10,
        price: 180.0,
        totalAmount: 1800.0,
        timestamp: DateTime.now().subtract(Duration(days: 60)),
      ),
      Transaction(
        symbol: 'MSFT',
        action: 'buy',
        quantity: 5,
        price: 330.0,
        totalAmount: 1650.0,
        timestamp: DateTime.now().subtract(Duration(days: 45)),
      ),
      Transaction(
        symbol: 'GOOGL',
        action: 'buy',
        quantity: 8,
        price: 135.0,
        totalAmount: 1080.0,
        timestamp: DateTime.now().subtract(Duration(days: 30)),
      ),
      Transaction(
        symbol: 'AMZN',
        action: 'buy',
        quantity: 4,
        price: 120.0,
        totalAmount: 480.0,
        timestamp: DateTime.now().subtract(Duration(days: 25)),
      ),
      Transaction(
        symbol: 'JPM',
        action: 'buy',
        quantity: 7,
        price: 145.0,
        totalAmount: 1015.0,
        timestamp: DateTime.now().subtract(Duration(days: 20)),
      ),
      Transaction(
        symbol: 'JNJ',
        action: 'buy',
        quantity: 6,
        price: 160.0,
        totalAmount: 960.0,
        timestamp: DateTime.now().subtract(Duration(days: 15)),
      ),
    ];
    
    // Update cash balance (starting with initial $10,000 minus the purchases)
    _cashBalance = 10000.0 - 1800.0 - 1650.0 - 1080.0 - 480.0 - 1015.0 - 960.0;
    
    // Notify listeners about the change
    notifyListeners();
  }
  
  // Clear all portfolio data (for testing/reset)
  Future<void> clearPortfolioData() async {
    try {
      _holdings = [];
      _transactions = [];
      _cashBalance = 10000.0;
      
      // Save empty data to storage
      await _saveData();
      
      notifyListeners();
    } catch (e) {
      print('Error clearing portfolio data: $e');
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void _clearError() {
    _error = '';
    notifyListeners();
  }
} 