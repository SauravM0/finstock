import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/investment_agent_provider.dart';
import '../services/investment_agent_service.dart';

class AIInvestmentAgentScreen extends StatefulWidget {
  @override
  _AIInvestmentAgentScreenState createState() => _AIInvestmentAgentScreenState();
}

class _AIInvestmentAgentScreenState extends State<AIInvestmentAgentScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _showAdviceSection = false;
  bool _showSuggestionsSection = false;
  
  // Mock data for demonstration - in a real app, you would get this from a portfolio service
  final Map<String, dynamic> _portfolioData = {
    'stocks': [
      {'symbol': 'AAPL', 'shares': 10, 'avgPrice': 150.00},
      {'symbol': 'MSFT', 'shares': 5, 'avgPrice': 280.00},
      {'symbol': 'GOOGL', 'shares': 2, 'avgPrice': 2700.00},
    ],
    'cash': 5000.00,
    'totalValue': 12500.00,
  };
  
  // Mock market trends data
  final List<Map<String, dynamic>> _marketTrends = [
    {'sector': 'Technology', 'trend': 'Upward', 'confidence': 0.8},
    {'sector': 'Healthcare', 'trend': 'Stable', 'confidence': 0.6},
    {'sector': 'Energy', 'trend': 'Downward', 'confidence': 0.7},
  ];
  
  // Mock user preferences
  final Map<String, dynamic> _userPreferences = {
    'riskTolerance': 'Moderate',
    'investmentHorizon': 'Long-term',
    'sectors': ['Technology', 'Healthcare', 'Finance'],
  };

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Investment Agent'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'API Key Settings',
          ),
        ],
      ),
      body: Consumer<InvestmentAgentProvider>(
        builder: (context, provider, child) {
          // Check if the InvestmentAgentService has a valid API key
          final hasApiKey = context.read<InvestmentAgentService>().isModelInitialized;
          
          if (!hasApiKey) {
            return _buildNoApiKeyMessage();
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPortfolioSummary(),
                SizedBox(height: 16.0),
                _buildQuestionSection(provider),
                SizedBox(height: 16.0),
                if (provider.isLoading)
                  Center(child: CircularProgressIndicator()),
                if (provider.hasError)
                  _buildErrorMessage(provider.error),
                if (_showAdviceSection && !provider.isLoading)
                  _buildAdviceSection(provider),
                SizedBox(height: 16.0),
                _buildSuggestionsButton(provider),
                if (_showSuggestionsSection && !provider.isLoading)
                  _buildSuggestionsSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoApiKeyMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.api_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(
              'API Key Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'To use the AI Investment Agent, you need to provide a Google Gemini API key. '
              'You can get a free API key from the Google AI Studio website.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: Icon(Icons.settings),
              label: Text('Go to Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Summary',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text('Total Value: \$${_portfolioData['totalValue']}'),
            Text('Cash Available: \$${_portfolioData['cash']}'),
            SizedBox(height: 8.0),
            Text('Top Holdings:'),
            ..._portfolioData['stocks'].map<Widget>((stock) => 
              Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('${stock['symbol']}: ${stock['shares']} shares @ \$${stock['avgPrice']}'),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSection(InvestmentAgentProvider provider) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask Your Investment Agent',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'E.g., Should I invest more in tech stocks?',
                border: OutlineInputBorder(),
                suffixIcon: _questionController.text.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _questionController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              ),
              onChanged: (_) => setState(() {}),
              maxLines: 3,
            ),
            SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _questionController.text.isNotEmpty 
                  ? () {
                      FocusScope.of(context).unfocus(); // Hide keyboard
                      provider.getInvestmentAdvice(
                        userQuestion: _questionController.text,
                        portfolioData: _portfolioData,
                        marketTrends: _marketTrends,
                      );
                      setState(() {
                        _showAdviceSection = true;
                        _showSuggestionsSection = false;
                      });
                    }
                  : null, // Disable if text is empty
                icon: Icon(Icons.send),
                label: Text('Get Advice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceSection(InvestmentAgentProvider provider) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Investment Advice',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _questionController.text.isNotEmpty 
                    ? () {
                        provider.getInvestmentAdvice(
                          userQuestion: _questionController.text,
                          portfolioData: _portfolioData,
                          marketTrends: _marketTrends,
                        );
                      }
                    : null,
                  tooltip: 'Regenerate advice',
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              provider.currentAdvice,
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsButton(InvestmentAgentProvider provider) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          provider.getPortfolioSuggestions(
            currentPortfolio: _portfolioData,
            userPreferences: _userPreferences,
            marketData: _marketTrends,
          );
          setState(() {
            _showSuggestionsSection = true;
            _showAdviceSection = false;
          });
        },
        icon: Icon(Icons.auto_awesome),
        label: Text('Generate Portfolio Suggestions'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(InvestmentAgentProvider provider) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.only(top: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Suggestions',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            if (provider.portfolioSuggestions.isEmpty)
              Text('No suggestions available at this time.'),
            ...provider.portfolioSuggestions.map((suggestion) => 
              Card(
                margin: EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: Icon(
                    suggestion['action'] == 'Buy' ? Icons.trending_up : Icons.trending_down,
                    color: suggestion['action'] == 'Buy' ? Colors.green : Colors.red,
                  ),
                  title: Text('${suggestion['asset']} - ${suggestion['action']}'),
                  subtitle: Text(suggestion['reason']),
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Card(
      color: Colors.red[100],
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              error,
              style: TextStyle(color: Colors.red[900]),
            ),
            SizedBox(height: 12.0),
            OutlinedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              onPressed: () {
                if (_questionController.text.isNotEmpty) {
                  Provider.of<InvestmentAgentProvider>(context, listen: false)
                    .getInvestmentAdvice(
                      userQuestion: _questionController.text,
                      portfolioData: _portfolioData,
                      marketTrends: _marketTrends,
                    );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 