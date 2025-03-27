import 'package:flutter/foundation.dart';
import '../services/ai_financial_service.dart';

class AIFinancialProvider with ChangeNotifier {
  final AIFinancialService _aiService;
  Map<String, dynamic>? _portfolioAnalysis;
  Map<String, dynamic>? _recommendations;
  Map<String, dynamic>? _technicalAnalysis;
  Map<String, dynamic>? _fundamentalAnalysis;
  Map<String, dynamic>? _marketSentiment;
  bool _isLoading = false;
  String? _error;

  AIFinancialProvider({required AIFinancialService aiService})
      : _aiService = aiService;

  Map<String, dynamic>? get portfolioAnalysis => _portfolioAnalysis;
  Map<String, dynamic>? get recommendations => _recommendations;
  Map<String, dynamic>? get technicalAnalysis => _technicalAnalysis;
  Map<String, dynamic>? get fundamentalAnalysis => _fundamentalAnalysis;
  Map<String, dynamic>? get marketSentiment => _marketSentiment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> analyzePortfolio(List<Map<String, dynamic>> assets) async {
    _setLoading(true);
    try {
      _portfolioAnalysis = await _aiService.analyzePortfolio(assets);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getStockRecommendations({
    required String riskLevel,
    required double investmentAmount,
    required List<String> preferredSectors,
  }) async {
    _setLoading(true);
    try {
      _recommendations = await _aiService.getStockRecommendations(
        riskLevel: riskLevel,
        investmentAmount: investmentAmount,
        preferredSectors: preferredSectors,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> analyzeTechnicalIndicators(String symbol) async {
    _setLoading(true);
    try {
      _technicalAnalysis = await _aiService.getTechnicalAnalysis(symbol);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> analyzeFundamentals(String symbol) async {
    _setLoading(true);
    try {
      _fundamentalAnalysis = await _aiService.getFundamentalAnalysis(symbol);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> analyzeMarketSentiment(String symbol) async {
    _setLoading(true);
    try {
      _marketSentiment = await _aiService.analyzeMarketSentiment(symbol);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _portfolioAnalysis = null;
    _recommendations = null;
    _technicalAnalysis = null;
    _fundamentalAnalysis = null;
    _marketSentiment = null;
    _error = null;
    notifyListeners();
  }
} 