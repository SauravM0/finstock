import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/investment_agent_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/user_preferences_provider.dart';

class PortfolioSuggestionsScreen extends StatefulWidget {
  @override
  _PortfolioSuggestionsScreenState createState() => _PortfolioSuggestionsScreenState();
}

class _PortfolioSuggestionsScreenState extends State<PortfolioSuggestionsScreen> {
  bool _isGenerating = false;
  bool _shouldShowIntro = true;
  
  @override
  Widget build(BuildContext context) {
    final investmentAgentProvider = Provider.of<InvestmentAgentProvider>(context);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final userPreferences = Provider.of<UserPreferencesProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Portfolio Suggestions'),
      ),
      body: _isGenerating
          ? _buildLoadingState()
          : investmentAgentProvider.hasEnhancedAnalysis
              ? _buildSuggestionsView(investmentAgentProvider)
              : _buildInitialState(
                  investmentAgentProvider, 
                  portfolioProvider, 
                  userPreferences,
                ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Analyzing your portfolio...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          Text(
            'Our AI is carefully reviewing your transaction history\n'
            'and current holdings to provide personalized suggestions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialState(
    InvestmentAgentProvider investmentAgentProvider,
    PortfolioProvider portfolioProvider,
    UserPreferencesProvider userPreferences,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_shouldShowIntro) _buildIntroSection(),
          SizedBox(height: 24),
          _buildRiskToleranceSelector(userPreferences),
          SizedBox(height: 24),
          _buildGenerateButton(
            investmentAgentProvider,
            portfolioProvider,
            userPreferences,
          ),
          SizedBox(height: 16),
          if (investmentAgentProvider.hasError)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      investmentAgentProvider.error,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildIntroSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'AI Portfolio Suggestions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Our AI will analyze your portfolio and provide personalized suggestions based on:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 8),
            _buildFeatureItem('Your current holdings'),
            _buildFeatureItem('Your transaction history'),
            _buildFeatureItem('Current market conditions'),
            _buildFeatureItem('Your risk tolerance'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    child: Text('Hide this intro'),
                    onPressed: () {
                      setState(() {
                        _shouldShowIntro = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  Widget _buildRiskToleranceSelector(UserPreferencesProvider userPreferences) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Risk Tolerance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Select the level of risk you\'re comfortable with for your investments.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: userPreferences.riskTolerance,
              decoration: InputDecoration(
                labelText: 'Risk Tolerance',
                border: OutlineInputBorder(),
              ),
              items: UserPreferencesProvider.riskToleranceOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  userPreferences.setRiskTolerance(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGenerateButton(
    InvestmentAgentProvider investmentAgentProvider,
    PortfolioProvider portfolioProvider,
    UserPreferencesProvider userPreferences,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(Icons.auto_awesome),
        label: Text('Generate Portfolio Suggestions'),
        onPressed: () async {
          // Basic market data (in a real app, this would come from a service)
          final mockMarketData = {
            'market_indices': [
              {'name': 'S&P 500', 'value': 5021.25, 'change_pct': 0.8},
              {'name': 'Nasdaq', 'value': 15823.67, 'change_pct': 1.2},
              {'name': 'Dow Jones', 'value': 38671.54, 'change_pct': 0.5},
            ],
            'sector_performance': [
              {'sector': 'Technology', 'change_pct': 1.5},
              {'sector': 'Healthcare', 'change_pct': -0.3},
              {'sector': 'Financials', 'change_pct': 0.7},
              {'sector': 'Energy', 'change_pct': -0.8},
            ],
            'economic_indicators': [
              {'name': 'Inflation Rate', 'value': '3.1%'},
              {'name': 'Interest Rate', 'value': '5.50%'},
              {'name': 'Unemployment', 'value': '3.8%'},
            ],
          };
          
          setState(() {
            _isGenerating = true;
          });
          
          try {
            await investmentAgentProvider.getEnhancedPortfolioSuggestions(
              holdings: portfolioProvider.holdings,
              cashBalance: portfolioProvider.cashBalance,
              transactions: portfolioProvider.transactions,
              marketData: mockMarketData,
              riskTolerance: userPreferences.riskTolerance,
            );
          } finally {
            setState(() {
              _isGenerating = false;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildSuggestionsView(InvestmentAgentProvider investmentAgentProvider) {
    final analysis = investmentAgentProvider.getPortfolioAnalysis();
    final suggestions = investmentAgentProvider.getProcessedSuggestions();
    
    return RefreshIndicator(
      onRefresh: () async {
        investmentAgentProvider.resetState();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisCard(analysis),
            SizedBox(height: 16),
            Text('Suggested Actions', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            ...suggestions.map((suggestion) => _buildSuggestionCard(suggestion)),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Reset & Start Over'),
                    onPressed: () {
                      investmentAgentProvider.resetState();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    if (analysis.isEmpty) {
      return SizedBox.shrink();
    }
    
    final overview = analysis['overview'] as String? ?? 'No overview available';
    final strengths = analysis['strengths'] as List? ?? [];
    final weaknesses = analysis['weaknesses'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Portfolio Analysis', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text(overview),
            if (strengths.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Strengths', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              ...strengths.map((strength) => _buildAnalysisItem(strength.toString(), Colors.green)),
            ],
            if (weaknesses.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Areas for Improvement', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              ...weaknesses.map((weakness) => _buildAnalysisItem(weakness.toString(), Colors.orange)),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisItem(String text, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            color == Colors.green ? Icons.arrow_circle_up : Icons.arrow_circle_down,
            color: color,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final type = suggestion['type'] as String? ?? 'allocate';
    final symbol = suggestion['symbol'] as String? ?? '';
    final action = suggestion['action'] as String? ?? 'No action specified';
    final reasoning = suggestion['reasoning'] as String? ?? 'No reasoning provided';
    
    // Determine icon and color based on suggestion type
    IconData icon;
    Color color;
    
    switch (type.toLowerCase()) {
      case 'buy':
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case 'sell':
        icon = Icons.remove_circle_outline;
        color = Colors.red;
        break;
      case 'hold':
        icon = Icons.pause_circle_outline;
        color = Colors.blue;
        break;
      case 'allocate':
      default:
        icon = Icons.pie_chart_outline;
        color = Colors.purple;
        break;
    }
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (symbol.isNotEmpty)
                        Text(
                          'Symbol: $symbol',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Reasoning:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(reasoning),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (type.toLowerCase() == 'buy' || type.toLowerCase() == 'sell')
                  OutlinedButton.icon(
                    icon: Icon(type.toLowerCase() == 'buy' ? Icons.shopping_cart : Icons.sell),
                    label: Text(type.toLowerCase() == 'buy' ? 'Go to Buy' : 'Go to Sell'),
                    onPressed: () {
                      // Navigate to market screen with symbol pre-selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Navigate to trade screen for $symbol'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 