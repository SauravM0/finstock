import 'package:flutter/material.dart';
import 'ai_chatbot_screen.dart';
import '../services/gemini_service.dart';

class AIAdvisorScreen extends StatefulWidget {
  final String? geminiApiKey;

  const AIAdvisorScreen({
    Key? key,
    this.geminiApiKey,
  }) : super(key: key);

  @override
  _AIAdvisorScreenState createState() => _AIAdvisorScreenState();
}

class _AIAdvisorScreenState extends State<AIAdvisorScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _stockRecommendations = [];
  List<Map<String, dynamic>> _financialTips = [];
  List<Map<String, dynamic>> _marketAlerts = [];
  int _portfolioHealthScore = 75; // Default score

  late GeminiService _geminiService;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load all data concurrently
      final recommendationsFuture = _geminiService.getStockRecommendations();
      final tipsFuture = _geminiService.getFinancialTips();
      final alertsFuture = _geminiService.getMarketAlerts();
      final scoreFuture = _geminiService.getPortfolioHealthScore(['AAPL', 'MSFT', 'GOOGL']);

      // Wait for all futures to complete
      final recommendations = await recommendationsFuture;
      final tips = await tipsFuture;
      final alerts = await alertsFuture;
      final score = await scoreFuture;

      // Check if any of the data is null and use empty lists as fallbacks
      final safeRecommendations = recommendations ?? _getDefaultStockRecommendations();
      final safeTips = tips ?? _getDefaultFinancialTips();
      final safeAlerts = alerts ?? _getDefaultMarketAlerts();

      // Update state with the results
      if (mounted) {
        setState(() {
          _stockRecommendations = safeRecommendations;
          _financialTips = safeTips;
          _marketAlerts = safeAlerts;
          _portfolioHealthScore = score;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading AI advisor data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Could not load data: ${e.toString()}';
          // Use default data
          _stockRecommendations = _getDefaultStockRecommendations();
          _financialTips = _getDefaultFinancialTips();
          _marketAlerts = _getDefaultMarketAlerts();
        });
      }
    }
  }

  // Default data in case of errors
  List<Map<String, dynamic>> _getDefaultStockRecommendations() {
    return [
      {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "recommendation": "Buy",
        "confidence": 85,
        "reason": "Strong product pipeline and services growth"
      },
      {
        "symbol": "MSFT",
        "name": "Microsoft Corporation",
        "recommendation": "Buy",
        "confidence": 80,
        "reason": "Cloud business expansion and AI integration"
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultFinancialTips() {
    return [
      {
        "title": "Emergency Fund First",
        "description": "Build an emergency fund covering 3-6 months of expenses before investing",
        "category": "Savings"
      },
      {
        "title": "Diversify Investments",
        "description": "Spread investments across different asset classes to reduce risk",
        "category": "Investing"
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultMarketAlerts() {
    return [
      {
        "title": "Market Volatility",
        "description": "Markets showing increased volatility - consider reviewing your portfolio",
        "severity": "moderate",
        "impactedSectors": ["Technology", "Finance"]
      },
    ];
  }

  Color _getSeverityColor(String? severity) {
    if (severity == null) return Colors.grey;
    
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getRecommendationColor(String? recommendation) {
    if (recommendation == null) return Colors.grey;
    
    switch (recommendation.toLowerCase()) {
      case 'strong buy':
        return Colors.green.shade800;
      case 'buy':
        return Colors.green;
      case 'hold':
        return Colors.orange;
      case 'sell':
        return Colors.red;
      case 'strong sell':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  // Safe getter methods to avoid null errors
  String _safeGetSymbol(Map<String, dynamic> recommendation) {
    final symbol = recommendation['symbol'];
    if (symbol is String && symbol.isNotEmpty) {
      return symbol.substring(0, 1);
    }
    return 'S';
  }

  String _safeGetString(Map<String, dynamic> map, String key, String defaultValue) {
    final value = map[key];
    if (value is String) {
      return value;
    }
    return defaultValue;
  }

  int _safeGetInt(Map<String, dynamic> map, String key, int defaultValue) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    return defaultValue;
  }

  List<dynamic> _safeGetList(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is List) {
      return value;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('AI Advisor'),
          actions: [
            IconButton(
              icon: Icon(Icons.chat),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIChatbotScreen(),
                ),
              ),
              tooltip: 'Chat with AI',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading financial insights...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: Text('AI Advisor'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Retry',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong'),
              SizedBox(height: 8),
              Text(_errorMessage, textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Advisor'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh data',
          ),
          IconButton(
            icon: Icon(Icons.chat),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIChatbotScreen(),
              ),
            ),
            tooltip: 'Chat with AI',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Portfolio Health Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Portfolio Health Score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: _portfolioHealthScore / 100,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getScoreColor(_portfolioHealthScore),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '$_portfolioHealthScore',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(_portfolioHealthScore),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _portfolioHealthScore >= 80
                                    ? 'Excellent'
                                    : _portfolioHealthScore >= 70
                                        ? 'Good'
                                        : _portfolioHealthScore >= 60
                                            ? 'Fair'
                                            : 'Needs Attention',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(_portfolioHealthScore),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _portfolioHealthScore >= 80
                                    ? 'Your portfolio is well-diversified and balanced.'
                                    : _portfolioHealthScore >= 70
                                        ? 'Your portfolio is performing well but has room for improvement.'
                                        : _portfolioHealthScore >= 60
                                            ? 'Your portfolio needs some adjustments to improve performance.'
                                            : 'Your portfolio requires significant rebalancing.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Stock Recommendations
            Text(
              'Stock Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            if (_stockRecommendations.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No stock recommendations available'),
                ),
              )
            else
              ..._stockRecommendations.map((recommendation) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      _safeGetSymbol(recommendation),
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(_safeGetString(recommendation, 'name', 'Stock'))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRecommendationColor(_safeGetString(recommendation, 'recommendation', '')),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _safeGetString(recommendation, 'recommendation', 'N/A'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(_safeGetString(recommendation, 'reason', 'No reason provided')),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Confidence: '),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _safeGetInt(recommendation, 'confidence', 50) / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getRecommendationColor(_safeGetString(recommendation, 'recommendation', '')),
                              ),
                              minHeight: 8,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${_safeGetInt(recommendation, 'confidence', 50)}%',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              )).toList(),
            
            SizedBox(height: 24),
            
            // Market Alerts
            Text(
              'Market Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            if (_marketAlerts.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No market alerts available'),
                ),
              )
            else
              ..._marketAlerts.map((alert) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: _getSeverityColor(_safeGetString(alert, 'severity', '')),
                    size: 36,
                  ),
                  title: Text(_safeGetString(alert, 'title', 'Alert')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(_safeGetString(alert, 'description', 'No description available')),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (final sector in _safeGetList(alert, 'impactedSectors'))
                            Chip(
                              label: Text(
                                sector.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: _getSeverityColor(_safeGetString(alert, 'severity', '')).withOpacity(0.8),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              )).toList(),
            
            SizedBox(height: 24),
            
            // Financial Tips
            Text(
              'Financial Tips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            if (_financialTips.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No financial tips available'),
                ),
              )
            else
              ..._financialTips.map((tip) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _safeGetString(tip, 'category', '') == 'Investing'
                        ? Icons.trending_up
                        : _safeGetString(tip, 'category', '') == 'Savings'
                            ? Icons.savings
                            : _safeGetString(tip, 'category', '') == 'Budgeting'
                                ? Icons.account_balance_wallet
                                : _safeGetString(tip, 'category', '') == 'Debt Management'
                                    ? Icons.credit_card
                                    : Icons.lightbulb_outline,
                    color: Colors.blue.shade700,
                  ),
                  title: Text(_safeGetString(tip, 'title', 'Tip')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(_safeGetString(tip, 'description', 'No description available')),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _safeGetString(tip, 'category', 'General'),
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              )).toList(),
              
            SizedBox(height: 24),
            
            // Chat button
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIChatbotScreen(),
                ),
              ),
              icon: Icon(Icons.chat),
              label: Text('Ask the AI Advisor'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            SizedBox(height: 16),
            
            Text(
              'All recommendations are AI-generated and should be used as informational guidance only. Consult with a professional financial advisor before making investment decisions.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}