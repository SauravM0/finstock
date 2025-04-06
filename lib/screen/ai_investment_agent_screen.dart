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
        centerTitle: true,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {}, // Optional: Add navigation to portfolio details
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Portfolio Summary',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            // Portfolio details
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total value with larger font
                  Row(
                    children: [
                      Text(
                        'Total Value: ',
                        style: TextStyle(fontSize: 16.0),
                      ),
                      Text(
                        '\$${_portfolioData['totalValue']}',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  // Cash available
                  Row(
                    children: [
                      Text('Cash Available: '),
                      Text(
                        '\$${_portfolioData['cash']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  // Holdings header
                  Text(
                    'Top Holdings',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  // Holdings list with dividers
                  ..._buildHoldingsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build holdings list with dividers
  List<Widget> _buildHoldingsList() {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Widget> holdingsWidgets = [];

    for (int i = 0; i < _portfolioData['stocks'].length; i++) {
      final stock = _portfolioData['stocks'][i];

      // Add holding item
      holdingsWidgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      stock['symbol'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Text(
                    '${stock['shares']} shares',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
              Text(
                '\$${stock['avgPrice']}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );

      // Add divider if not the last item
      if (i < _portfolioData['stocks'].length - 1) {
        holdingsWidgets.add(Divider(height: 1));
      }
    }

    return holdingsWidgets;
  }

  Widget _buildQuestionSection(InvestmentAgentProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondaryContainer,
                  colorScheme.secondaryContainer.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ask Your Investment Agent',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Icon(
                  Icons.chat_bubble_outline,
                  color: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
          // Question input area
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text field with animation
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _questionController.text.isNotEmpty
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'E.g., Should I invest more in tech stocks?',
                      helperText: 'Ask any investment-related question',
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
                ),
                SizedBox(height: 24.0),
                // Button with loading state
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
                    icon: provider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                            ),
                          )
                        : Icon(Icons.send),
                    label: Text(provider.isLoading ? 'Getting Advice...' : 'Get Advice'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(InvestmentAgentProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.tertiaryContainer,
                  colorScheme.tertiaryContainer.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Investment Advice',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.onTertiaryContainer),
                  onPressed: _questionController.text.isNotEmpty && !provider.isLoading
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
          ),
          // Advice content
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI-generated advice with subtle styling
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI response
                      Text(
                        provider.currentAdvice,
                        style: TextStyle(fontSize: 16.0, height: 1.5),
                      ),
                      // Source attribution
                      if (provider.currentAdvice.isNotEmpty) ...[
                        SizedBox(height: 16.0),
                        Row(
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 16.0,
                              color: colorScheme.outline,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'AI-generated advice',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsButton(InvestmentAgentProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: provider.isLoading
            ? null
            : () {
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
          icon: provider.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              )
            : Icon(Icons.auto_awesome),
          label: Text(provider.isLoading ? 'Generating...' : 'Generate Portfolio Suggestions'),
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(InvestmentAgentProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portfolio Suggestions',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
          // Suggestions content
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.portfolioSuggestions.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'No suggestions available at this time.',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: provider.portfolioSuggestions.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8.0),
                    itemBuilder: (context, index) {
                      final suggestion = provider.portfolioSuggestions[index];
                      final isBuy = suggestion['action'] == 'Buy';

                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(
                            color: isBuy ? colorScheme.tertiary.withOpacity(0.5) : colorScheme.error.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {}, // Optional: Add action when tapped
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Action icon
                                Container(
                                  padding: EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: isBuy ? colorScheme.tertiaryContainer : colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Icon(
                                    isBuy ? Icons.trending_up : Icons.trending_down,
                                    color: isBuy ? colorScheme.onTertiaryContainer : colorScheme.onErrorContainer,
                                  ),
                                ),
                                SizedBox(width: 16.0),
                                // Suggestion details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Asset and action
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                            child: Text(
                                              suggestion['asset'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSecondaryContainer,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.0),
                                          Text(
                                            suggestion['action'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isBuy ? colorScheme.tertiary : colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.0),
                                      // Reason
                                      Text(
                                        suggestion['reason'],
                                        style: TextStyle(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: colorScheme.error.withOpacity(0.5), width: 1),
      ),
      color: colorScheme.errorContainer.withOpacity(0.7),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: colorScheme.onError,
                    size: 20.0,
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Error Occurred',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
            // Divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: colorScheme.error.withOpacity(0.3), height: 1),
            ),
            // Error message
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                error,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Dismiss the error
                    Provider.of<InvestmentAgentProvider>(context, listen: false)
                      .clearError();
                  },
                  child: Text('Dismiss'),
                ),
                SizedBox(width: 8.0),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}