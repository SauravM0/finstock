import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({
    Key? key,
  }) : super(key: key);

  @override
  _AIChatbotScreenState createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  late GeminiService _geminiService;
  bool _isLoading = false;
  bool _isError = false;
  bool _isUsingDemoMode = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _showSuggestions = true;

  // Predefined question suggestions for new users
  final List<String> _suggestions = [
    "I have 10000 dollars, where should I invest it?",
    "What's the optimal asset allocation for a 35-year-old?",
    "How do I create a budget that I'll actually stick to?",
    "Should I prioritize paying off debt or investing?",
    "How much should I save for retirement by age 40?",
    "Is cryptocurrency a good investment in today's market?",
    "What tax-efficient investing strategies should I consider?",
    "How can I protect my portfolio during market downturns?",
  ];

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final response = await _geminiService.startChat();

      // Check if response suggests an API key issue
      final bool possibleApiKeyIssue = response.contains("problem with the API") ||
                                      response.contains("backup service");

      setState(() {
        _messages.add({
          'sender': 'AI',
          'text': "Hello! I'm FinStock, your AI Financial Advisor with expertise in global markets. I can provide personalized guidance on:\n\n• Investment strategies and portfolio optimization\n• Budgeting and debt management\n• Retirement planning and tax-efficient investing\n• Cryptocurrency and digital assets\n• Market trend analysis and economic indicators\n\nSelect a question below or type your own financial question to get started!",
          'timestamp': DateTime.now().toString(),
          'isDemo': possibleApiKeyIssue,
        });
        _isLoading = false;
        _isUsingDemoMode = possibleApiKeyIssue;
        _showSuggestions = true;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
        _isUsingDemoMode = true;
        _messages.add({
          'sender': 'AI',
          'text': "Hello! I'm FinStock, your AI Financial Advisor. I'm currently operating in offline mode, but I can still provide detailed financial guidance on:\n\n• Investment strategies and asset allocation\n• Budgeting and saving techniques\n• Retirement planning strategies\n• Cryptocurrency investment approaches\n• Market analysis and economic trends\n\nSelect a question below or ask me anything about personal finance or investing!",
          'timestamp': DateTime.now().toString(),
          'isDemo': true,
        });
        _showSuggestions = true;
      });
    }
  }

  Future<void> _sendMessage([String? predefinedMessage]) async {
    String message = predefinedMessage ?? _controller.text;

    if (message.isEmpty) return;

    if (predefinedMessage == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add({
        'sender': 'User',
        'text': message,
        'timestamp': DateTime.now().toString(),
      });
      _isLoading = true;
      _isError = false;
      _showSuggestions = false;
    });

    try {
      final response = await _geminiService.sendMessage(message);

      // Check if response is an error message or using demo mode
      final bool isErrorResponse = response.contains('No internet connection') ||
          response.contains('Unable to connect') ||
          response.contains('Invalid API key') ||
          response.contains('I apologize') ||
          response.contains('trouble accessing') ||
          response.contains('error processing');

      final bool isUsingDemo = response.contains('Please note this is general advice') ||
                              response.contains('This is simplified advice') ||
                              response.contains('This general advice may need adjustment') ||
                              response.contains('This is general guidance');

      setState(() {
        _messages.add({
          'sender': 'AI',
          'text': response,
          'timestamp': DateTime.now().toString(),
          'isError': isErrorResponse ? true : null,
          'isDemo': isUsingDemo,
        });
        _isError = isErrorResponse;
        _isUsingDemoMode = _isUsingDemoMode || isUsingDemo;
        _isLoading = false;
      });
    } catch (e) {
      _retryCount++;
      setState(() {
        if (_retryCount >= _maxRetries) {
          // After too many failures, switch to demo mode responses
          _isUsingDemoMode = true;
          _messages.add({
            'sender': 'AI',
            'text': _getSimpleDemoResponse(message),
            'timestamp': DateTime.now().toString(),
            'isDemo': true,
          });
        } else {
          _messages.add({
            'sender': 'AI',
            'text': "I apologize, but I encountered a temporary technical issue connecting to my financial knowledge database. I'm still here to help! Please try asking your question again in a slightly different way, or select one of the suggested financial topics below. I'm particularly good at answering questions about investment strategies, retirement planning, and budgeting.",
            'timestamp': DateTime.now().toString(),
            'isError': true,
          });
          _showSuggestions = true;
        }
        _isError = true;
        _isLoading = false;
      });
    }
  }

  String _getSimpleDemoResponse(String message) {
    message = message.toLowerCase();

    if (message.contains('stock') || message.contains('invest')) {
      return "When investing in stocks, diversification is key to reducing risk. Consider a mix of different sectors and asset classes (like ETFs) to start.\n\nFor beginners, index funds offer an excellent way to gain broad market exposure without needing to pick individual stocks. Many successful investors recommend starting with low-cost index funds that track major indices like the S&P 500.\n\nRemember to only invest money you don't need in the short term, as markets can be volatile.";
    } else if (message.contains('crypto') || message.contains('bitcoin')) {
      return "Cryptocurrency investments can be highly volatile and should typically be limited to a small percentage of your portfolio - many financial advisors suggest no more than 5% for most investors.\n\nIf you're interested in crypto, consider starting with the established coins like Bitcoin or Ethereum rather than newer, unproven alternatives.\n\nBe aware that cryptocurrency markets can experience extreme price swings, and it's important to only invest what you can afford to lose.";
    } else if (message.contains('budget') || message.contains('save')) {
      return "Creating a budget using the 50/30/20 rule can be effective:\n• 50% for needs (housing, food, utilities)\n• 30% for wants (entertainment, dining out)\n• 20% for savings and debt repayment\n\nStart by tracking your spending for a month to understand where your money is going. Many free apps can help automate this process.\n\nFor savings, aim to build an emergency fund covering 3-6 months of expenses before focusing on other financial goals.";
    } else if (message.contains('retire') || message.contains('retirement')) {
      return "The earlier you start saving for retirement, the better, thanks to compound interest. Even small contributions can grow significantly over time.\n\nConsider tax-advantaged retirement accounts like 401(k)s (especially if your employer offers matching contributions) and IRAs.\n\nA general guideline is to save 15% of your pre-tax income for retirement, but this varies based on your age, retirement goals, and current savings.";
    } else if (message.contains('debt') || message.contains('loan')) {
      return "When tackling debt, consider either:\n\n1. The avalanche method: Pay off highest-interest debt first (mathematically optimal)\n2. The snowball method: Pay off smallest balances first (psychologically rewarding)\n\nFor student loans, explore income-driven repayment plans if you're struggling with payments.\n\nAvoid payday loans and high-interest credit card debt whenever possible, as these can trap you in cycles of debt.";
    } else {
      return "Here are some foundational financial principles:\n\n1. Build an emergency fund covering 3-6 months of expenses\n2. Pay off high-interest debt\n3. Take advantage of employer retirement matching\n4. Invest consistently for long-term goals\n5. Ensure you have appropriate insurance coverage\n\nThese fundamentals apply to most financial situations and can help you build a solid foundation.";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatAIResponse(String text) {
    // Check if this is an investment recommendation response
    final bool isInvestmentRecommendation = text.contains('Based on your investment amount') ||
                                          text.contains('here are the best options');

    if (isInvestmentRecommendation) {
      // Apply special formatting for investment recommendations
      return _formatInvestmentRecommendation(text);
    }

    // Format bullet points and numbered lists
    final formattedText = text
        .replaceAllMapped(RegExp(r'^\s*[•-]\s*(.+)$', multiLine: true),
            (match) => '• ${match.group(1)}')
        .replaceAllMapped(RegExp(r'^\s*(\d+)\.\s*(.+)$', multiLine: true),
            (match) => '${match.group(1)}. ${match.group(2)}');
    return formattedText;
  }

  String _formatInvestmentRecommendation(String text) {
    // Extract the header and recommendations
    final parts = text.split('\n\n');
    String header = parts.isNotEmpty ? parts[0] : '';

    // Format each recommendation line with bold symbols
    final formattedText = text.replaceAllMapped(
      RegExp(r'^(\d+\.\s+)([A-Z]+(?:\.[A-Z])?):\s+([^-]+)\s*-\s*(.+)$', multiLine: true),
      (match) => '${match.group(1)}**${match.group(2)}**: ${match.group(3)} - ${match.group(4)}'
    );

    return formattedText;
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'User';
    final isError = message['isError'] == true;
    final isDemo = message['isDemo'] == true;
    final text = message['text'] ?? '';

    // Check if this is an investment recommendation
    final bool isInvestmentRecommendation = !isUser &&
        (text.contains('Based on your investment amount') || text.contains('here are the best options'));

    // Format bullet points and lists in AI responses
    final formattedText = !isUser ? _formatAIResponse(text) : text;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red[50]
              : (isUser ? Colors.blue[100] :
                 (isInvestmentRecommendation ? Colors.green[50] :
                  (isDemo ? Colors.grey[200] : Colors.blue[50]))),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
          border: isError
              ? Border.all(color: Colors.red.shade200)
              : (isDemo ? Border.all(color: Colors.orange.shade200) :
                 (isInvestmentRecommendation ? Border.all(color: Colors.green.shade300) : null)),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && isDemo)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 12, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Simplified Advice',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (!isUser && isInvestmentRecommendation)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 12, color: Colors.green.shade700),
                    SizedBox(width: 4),
                    Text(
                      'Investment Recommendations',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            isInvestmentRecommendation
                ? _buildInvestmentRecommendationContent(formattedText)
                : Text(
                    formattedText,
                    style: TextStyle(
                      color: isError ? Colors.red.shade700 : (isUser ? Colors.black87 : Colors.black),
                      height: 1.4,
                      fontSize: 15,
                    ),
                  ),
            if (isError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: _initializeChat,
                  child: Text('Restart Chat'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentRecommendationContent(String text) {
    // Split the text into lines
    final lines = text.split('\n');

    // Extract header and recommendations
    String header = '';
    List<String> recommendations = [];
    String footer = '';

    bool inRecommendations = false;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      if (line.contains('here are the best options')) {
        header = line;
        inRecommendations = true;
      } else if (inRecommendations && line.startsWith(RegExp(r'\d+\.'))) {
        recommendations.add(line);
      } else if (inRecommendations && recommendations.isNotEmpty && !line.startsWith(RegExp(r'\d+\.'))) {
        footer = line;
        inRecommendations = false;
      } else if (!inRecommendations && recommendations.isEmpty) {
        header = header.isEmpty ? line : '$header\n$line';
      } else if (!inRecommendations && !recommendations.isEmpty) {
        footer = footer.isEmpty ? line : '$footer\n$line';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          header,
          style: TextStyle(
            color: Colors.black87,
            height: 1.4,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 8),

        // Recommendations
        ...recommendations.map((rec) {
          // Parse the recommendation
          final match = RegExp(r'^(\d+\.\s+)([A-Z]+(?:\.[A-Z])?):\s+([^-]+)\s*-\s*(.+)$')
              .firstMatch(rec);

          if (match != null) {
            final number = match.group(1) ?? '';
            final symbol = match.group(2) ?? '';
            final name = match.group(3)?.trim() ?? '';
            final reason = match.group(4) ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black87, fontSize: 15, height: 1.4),
                        children: [
                          TextSpan(
                            text: symbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          TextSpan(text: ': '),
                          TextSpan(text: name),
                          TextSpan(text: ' - '),
                          TextSpan(
                            text: reason,
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Text(rec, style: TextStyle(fontSize: 15, height: 1.4));
          }
        }).toList(),

        // Footer if exists
        if (footer.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              footer,
              style: TextStyle(
                color: Colors.black87,
                height: 1.4,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 8),
        children: _suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              label: Text(
                suggestion.length > 30 ? '${suggestion.substring(0, 27)}...' : suggestion,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                ),
              ),
              onPressed: () => _sendMessage(suggestion),
              backgroundColor: Colors.blue.shade50,
              elevation: 1,
              shadowColor: Colors.blue.shade100,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.shade200, width: 0.5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.support_agent, color: Colors.blue.shade700),
              radius: 18,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FinStock AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Financial Advisor',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeChat,
            tooltip: 'Restart conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUsingDemoMode)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.orange.shade100],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline, size: 14, color: Colors.orange.shade800),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'re using simplified guidance mode. The advisor will provide general financial advice based on best practices.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              padding: EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_showSuggestions && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  Text(
                    'Try asking about:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  _buildSuggestionChips(),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about your finances...',
                      prefixIcon: Icon(Icons.account_balance, color: Colors.blue.shade300),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.send),
                  mini: true,
                  elevation: 2,
                  backgroundColor: _isLoading ? Colors.grey.shade400 : Colors.blue.shade600,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Responses are AI-generated and should not replace professional financial advice.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}