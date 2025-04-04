import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/holding.dart';
import '../models/transaction.dart';

class InvestmentAgentProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  String _error = '';
  Map<String, dynamic> _enhancedAnalysis = {};
  
  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get error => _error;
  bool get hasEnhancedAnalysis => _enhancedAnalysis.isNotEmpty;
  
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
