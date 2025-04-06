import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/holding.dart';
import '../models/transaction.dart';

class InvestmentAgentProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  String _error = '';
  Map<String, dynamic> _enhancedAnalysis = {};

  // State for advice
  String _currentAdvice = '';
  List<Map<String, dynamic>> _portfolioSuggestions = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get error => _error;
  bool get hasEnhancedAnalysis => _enhancedAnalysis.isNotEmpty;
  String get currentAdvice => _currentAdvice;
  List<Map<String, dynamic>> get portfolioSuggestions => _portfolioSuggestions;

  Future<void> getEnhancedPortfolioSuggestions({
    required List<Holding> holdings,
    required double cashBalance,
    required List<Transaction> transactions,
    required Map<String, dynamic> marketData,
    required String riskTolerance,
  }) async {
    try {
      _isLoading = true;
      _hasError = false;
      _error = '';
      notifyListeners();

      // In a real app, this would make an API call to an AI service
      // For demo purposes, we'll simulate a response after a delay
      await Future.delayed(Duration(seconds: 3));

      // Generate mock AI response based on input data
      _enhancedAnalysis = _generateMockAnalysis(
        holdings: holdings,
        cashBalance: cashBalance,
        transactions: transactions,
        marketData: marketData,
        riskTolerance: riskTolerance,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _error = e.toString();
      notifyListeners();
    }
  }

  Map<String, dynamic> getPortfolioAnalysis() {
    if (!hasEnhancedAnalysis) return {};

    return {
      'overview': _enhancedAnalysis['analysis']['overview'],
      'strengths': _enhancedAnalysis['analysis']['strengths'],
      'weaknesses': _enhancedAnalysis['analysis']['weaknesses'],
    };
  }

  List<Map<String, dynamic>> getProcessedSuggestions() {
    if (!hasEnhancedAnalysis) return [];

    final List<dynamic> rawSuggestions = _enhancedAnalysis['suggestions'];
    return rawSuggestions.map((suggestion) =>
      suggestion as Map<String, dynamic>
    ).toList();
  }

  void resetState() {
    _enhancedAnalysis = {};
    _isLoading = false;
    _hasError = false;
    _error = '';
    notifyListeners();
  }

  void clearError() {
    _hasError = false;
    _error = '';
    notifyListeners();
  }

  // Get investment advice based on user question
  Future<void> getInvestmentAdvice({
    required String userQuestion,
    required Map<String, dynamic> portfolioData,
    required List<Map<String, dynamic>> marketTrends,
  }) async {
    try {
      _isLoading = true;
      _hasError = false;
      _error = '';
      notifyListeners();

      // In a real app, this would make an API call to an AI service
      // For demo purposes, we'll simulate a response after a delay
      await Future.delayed(Duration(seconds: 2));

      // Generate mock advice based on the question
      _currentAdvice = _generateMockAdvice(userQuestion, portfolioData, marketTrends);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get portfolio suggestions
  Future<void> getPortfolioSuggestions({
    required Map<String, dynamic> currentPortfolio,
    required Map<String, dynamic> userPreferences,
    required List<Map<String, dynamic>> marketData,
  }) async {
    try {
      _isLoading = true;
      _hasError = false;
      _error = '';
      notifyListeners();

      // In a real app, this would make an API call to an AI service
      // For demo purposes, we'll simulate a response after a delay
      await Future.delayed(Duration(seconds: 2));

      // Generate mock suggestions
      _portfolioSuggestions = _generateMockSuggestions(currentPortfolio, userPreferences, marketData);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Generate mock advice based on user question
  String _generateMockAdvice(String question, Map<String, dynamic> portfolio, List<Map<String, dynamic>> marketTrends) {
    // Simple keyword matching for demo purposes
    question = question.toLowerCase();

    if (question.contains('tech') || question.contains('technology')) {
      return "Based on your portfolio and current market conditions, technology stocks represent a significant opportunity. However, valuations are high, so consider dollar-cost averaging into positions rather than investing all at once. Focus on companies with strong balance sheets and sustainable competitive advantages.";
    } else if (question.contains('diversif')) {
      return "Your portfolio could benefit from greater diversification. Currently, you have exposure to only a few sectors, which increases your risk. Consider adding assets from different sectors like healthcare, consumer staples, and utilities. International exposure through ETFs would also help balance your portfolio.";
    } else if (question.contains('risk')) {
      return "Your portfolio's risk level appears to be moderate based on your holdings. To reduce risk, consider increasing your allocation to defensive sectors and bonds. If you're comfortable with more risk, you might increase exposure to growth-oriented sectors like technology and consumer discretionary, but maintain proper position sizing.";
    } else if (question.contains('invest') && (question.contains('bear') || question.contains('down') || question.contains('recession'))) {
      return "During market downturns, focus on quality companies with strong balance sheets, consistent cash flows, and competitive advantages. Consider defensive sectors like utilities, consumer staples, and healthcare. Keep some cash available to take advantage of opportunities, and remember that dollar-cost averaging can be an effective strategy during volatile periods.";
    } else {
      return "Based on your current portfolio allocation and market conditions, I recommend maintaining a balanced approach with a mix of growth and value investments. Consider regular rebalancing to maintain your target asset allocation, and ensure you have adequate emergency funds before increasing market exposure. For specific investment recommendations, please ask about particular sectors or investment goals.";
    }
  }

  // Generate mock portfolio suggestions
  List<Map<String, dynamic>> _generateMockSuggestions(
    Map<String, dynamic> portfolio,
    Map<String, dynamic> preferences,
    List<Map<String, dynamic>> marketData
  ) {
    final String riskTolerance = preferences['riskTolerance'];
    final List<Map<String, dynamic>> suggestions = [];

    // Add suggestions based on risk tolerance
    if (riskTolerance == 'Conservative') {
      suggestions.add({
        'asset': 'VYM',
        'action': 'Buy',
        'reason': 'High-dividend ETF provides stable income with lower volatility, suitable for conservative investors.',
      });
      suggestions.add({
        'asset': 'AAPL',
        'action': 'Reduce',
        'reason': 'Your technology allocation is high for a conservative portfolio. Consider reducing to limit volatility.',
      });
    } else if (riskTolerance == 'Moderate') {
      suggestions.add({
        'asset': 'VTI',
        'action': 'Buy',
        'reason': 'Total market ETF provides broad diversification at low cost, ideal for core portfolio holdings.',
      });
      suggestions.add({
        'asset': 'MSFT',
        'action': 'Buy',
        'reason': 'Strong balance sheet and diverse revenue streams provide growth with reasonable stability.',
      });
    } else { // Aggressive
      suggestions.add({
        'asset': 'TSLA',
        'action': 'Buy',
        'reason': 'High-growth potential aligns with your aggressive risk profile, though expect significant volatility.',
      });
      suggestions.add({
        'asset': 'ARKK',
        'action': 'Buy',
        'reason': 'Innovation-focused ETF offers exposure to disruptive technologies with high growth potential.',
      });
    }

    // Add general suggestions
    suggestions.add({
      'asset': 'Cash Reserves',
      'action': 'Maintain',
      'reason': 'Keep 3-6 months of expenses in cash for emergencies and to capitalize on market opportunities.',
    });

    // Add sector-specific suggestion based on market trends
    for (final trend in marketData) {
      if (trend['trend'] == 'Upward' && trend['confidence'] > 0.7) {
        suggestions.add({
          'asset': '${trend['sector']} ETF',
          'action': 'Buy',
          'reason': 'Strong upward trend in ${trend['sector']} sector with ${(trend['confidence'] * 100).toStringAsFixed(0)}% confidence level.',
        });
        break;
      }
    }

    return suggestions;
  }

  // Mock response generator for demo purposes
  Map<String, dynamic> _generateMockAnalysis({
    required List<Holding> holdings,
    required double cashBalance,
    required List<Transaction> transactions,
    required Map<String, dynamic> marketData,
    required String riskTolerance,
  }) {
    // Calculate some basic portfolio metrics
    double totalValue = holdings.fold<double>(
      0.0,
      (prev, h) => prev + (h.quantity * h.currentPrice)
    ) + cashBalance;

    double techExposure = holdings
        .where((h) =>
            h.sector == 'Technology' ||
            h.symbol == 'AAPL' ||
            h.symbol == 'MSFT' ||
            h.symbol == 'GOOGL')
        .fold<double>(0.0, (prev, h) => prev + (h.quantity * h.currentPrice)) / totalValue;

    double financeExposure = holdings
        .where((h) =>
            h.sector == 'Financials' ||
            h.symbol == 'JPM' ||
            h.symbol == 'BAC' ||
            h.symbol == 'GS')
        .fold<double>(0.0, (prev, h) => prev + (h.quantity * h.currentPrice)) / totalValue;

    bool hasInternationalStocks = holdings.any((h) => h.symbol.endsWith('.L') || h.symbol.endsWith('.HK'));

    // Generate appropriate analysis based on portfolio composition and risk tolerance
    final List<String> strengths = [];
    final List<String> weaknesses = [];
    final List<Map<String, dynamic>> suggestions = [];

    // Add common strengths
    if (holdings.length > 3) {
      strengths.add('Your portfolio has some diversification across ${holdings.length} different assets.');
    }

    if (cashBalance > totalValue * 0.05) {
      strengths.add('You have adequate cash reserves (${(cashBalance / totalValue * 100).toStringAsFixed(1)}% of portfolio) for opportunistic investments.');
    }

    // Add risk-specific strengths
    if (riskTolerance == 'Conservative' && cashBalance > totalValue * 0.1) {
      strengths.add('Your higher cash position aligns well with your conservative risk profile.');
    }

    if (riskTolerance == 'Aggressive' && techExposure > 0.3) {
      strengths.add('Your significant technology exposure may provide growth opportunities, fitting your aggressive risk profile.');
    }

    // Add weaknesses
    if (holdings.length < 5) {
      weaknesses.add('Limited diversification with only ${holdings.length} holdings increases your concentration risk.');
    }

    if (techExposure > 0.4) {
      weaknesses.add('High technology sector concentration (${(techExposure * 100).toStringAsFixed(1)}% of portfolio) creates sector-specific risk.');
    }

    if (!hasInternationalStocks) {
      weaknesses.add('No international exposure limits geographic diversification.');
    }

    if (riskTolerance == 'Conservative' && techExposure > 0.25) {
      weaknesses.add('Technology exposure of ${(techExposure * 100).toStringAsFixed(1)}% may be high for your conservative risk profile.');
    }

    if (riskTolerance == 'Aggressive' && cashBalance > totalValue * 0.15) {
      weaknesses.add('High cash position of ${(cashBalance / totalValue * 100).toStringAsFixed(1)}% may limit growth potential for your aggressive risk profile.');
    }

    // Generate overview
    String overview = 'Based on your $riskTolerance risk profile, ';
    if (strengths.length > weaknesses.length) {
      overview += 'your portfolio is generally well-structured but has some areas for improvement.';
    } else if (weaknesses.length > strengths.length) {
      overview += 'your portfolio needs some adjustments to better align with your investment goals.';
    } else {
      overview += 'your portfolio has both strengths and areas that need attention.';
    }

    // Generate suggestions based on analysis and risk tolerance
    if (riskTolerance == 'Conservative') {
      if (techExposure > 0.25) {
        suggestions.add({
          'type': 'sell',
          'symbol': 'AAPL',
          'action': 'Consider reducing tech exposure',
          'reasoning': 'Your technology allocation is high for a conservative portfolio. Reducing positions in high-volatility tech stocks could better align with your risk tolerance.'
        });
      }

      if (cashBalance < totalValue * 0.1) {
        suggestions.add({
          'type': 'allocate',
          'action': 'Increase cash reserves',
          'reasoning': 'For your conservative risk profile, maintaining adequate cash reserves (10-15% of portfolio) provides stability and opportunities for buying during market dips.'
        });
      }

      suggestions.add({
        'type': 'buy',
        'symbol': 'VYM',
        'action': 'Add high-dividend ETF exposure',
        'reasoning': 'High-dividend ETFs like VYM can provide stable income and lower volatility, aligning with your conservative risk profile.'
      });
    }
    else if (riskTolerance == 'Moderate') {
      if (holdings.length < 5) {
        suggestions.add({
          'type': 'allocate',
          'action': 'Increase portfolio diversification',
          'reasoning': 'Adding 3-5 more positions across different sectors would reduce individual stock risk while maintaining moderate growth potential.'
        });
      }

      if (!hasInternationalStocks) {
        suggestions.add({
          'type': 'buy',
          'symbol': 'VXUS',
          'action': 'Add international exposure',
          'reasoning': 'International stocks can provide diversification benefits and exposure to global growth opportunities, balancing your moderate risk portfolio.'
        });
      }

      if (financeExposure < 0.1) {
        suggestions.add({
          'type': 'buy',
          'symbol': 'XLF',
          'action': 'Consider adding financial sector exposure',
          'reasoning': 'Financial sector ETFs like XLF can benefit from rising interest rates and provide diversification from technology stocks.'
        });
      }
    }
    else if (riskTolerance == 'Aggressive') {
      if (cashBalance > totalValue * 0.15) {
        suggestions.add({
          'type': 'allocate',
          'action': 'Deploy excess cash',
          'reasoning': 'Your cash position is high for an aggressive portfolio. Consider deploying capital into growth opportunities to maximize potential returns.'
        });
      }

      suggestions.add({
        'type': 'buy',
        'symbol': 'ARKK',
        'action': 'Consider adding disruptive innovation exposure',
        'reasoning': 'ETFs focused on disruptive innovation like ARKK can provide high growth potential, aligning with your aggressive risk profile.'
      });

      if (!hasInternationalStocks) {
        suggestions.add({
          'type': 'buy',
          'symbol': 'MCHI',
          'action': 'Add emerging markets exposure',
          'reasoning': 'Emerging markets like China can offer significant growth opportunities, suitable for your aggressive approach to investing.'
        });
      }
    }

    // Add a general diversification suggestion
    suggestions.add({
      'type': 'allocate',
      'action': 'Follow the 5-10-40 rule',
      'reasoning': 'For better diversification, consider keeping each position to less than 5% of your portfolio, each sector to less than 10%, and each asset class to less than 40%.'
    });

    // Build and return the complete analysis
    return {
      'analysis': {
        'overview': overview,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'riskTolerance': riskTolerance,
        'portfolioValue': totalValue,
        'cashPercentage': cashBalance / totalValue,
        'sectorExposure': {
          'technology': techExposure,
          'financials': financeExposure,
        }
      },
      'suggestions': suggestions,
    };
  }
}
