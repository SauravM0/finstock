import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class AIChatbotScreen extends StatefulWidget {
  final String geminiApiKey;

  const AIChatbotScreen({
    Key? key,
    required this.geminiApiKey,
  }) : super(key: key);

  @override
  _AIChatbotScreenState createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  late GeminiService _geminiService;
  bool _isLoading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService(
      apiKey: widget.geminiApiKey,
    );
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    
    try {
      final response = await _geminiService.startChat();
      setState(() {
        _messages.add({'sender': 'AI', 'text': response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      _showErrorDialog('Failed to initialize AI advisor. Please try again.');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final userMessage = _controller.text;
      _controller.clear();
      
      setState(() {
        _messages.add({
          'sender': 'User',
          'text': userMessage,
          'timestamp': DateTime.now().toString(),
        });
        _isLoading = true;
        _isError = false;
      });

      try {
        final response = await _geminiService.sendMessage(userMessage);
        
        // Check if response is an error message
        final isErrorResponse = response.contains('No internet connection') ||
            response.contains('Unable to connect') ||
            response.contains('Invalid API key') ||
            response.contains('I apologize');

        if (isErrorResponse) {
          setState(() {
            _messages.add({
              'sender': 'AI',
              'text': response,
              'timestamp': DateTime.now().toString(),
              'isError': 'true',
            });
            _isError = true;
          });
        } else {
          setState(() {
            _messages.add({
              'sender': 'AI',
              'text': response,
              'timestamp': DateTime.now().toString(),
            });
          });
        }
      } catch (e) {
        setState(() {
          _messages.add({
            'sender': 'AI',
            'text': 'Failed to get response. Please try again.',
            'timestamp': DateTime.now().toString(),
            'isError': 'true',
          });
          _isError = true;
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeChat();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _geminiService.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['sender'] == 'User';
    final isError = message['isError'] == 'true';
    final text = message['text'] ?? '';

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
              : (isUser ? Colors.blue[100] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: isError
              ? Border.all(color: Colors.red.shade200)
              : null,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message['sender']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (!isUser) ...[
                  SizedBox(width: 4),
                  Icon(
                    Icons.verified,
                    size: 14,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
            SizedBox(height: 4),
            SelectableText(
              formattedText,
              style: TextStyle(
                color: isError ? Colors.red : null,
                height: 1.4,
              ),
            ),
            if (isError) ...[
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _retryLastMessage(message['text']!),
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Retry'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size(0, 32),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAIResponse(String text) {
    // Add proper spacing after bullet points and numbers
    text = text.replaceAllMapped(
      RegExp(r'(•|\d+\.)\s*'),
      (match) => '${match.group(1)} ',
    );

    // Add line breaks before bullet points and numbers if not already present
    text = text.replaceAllMapped(
      RegExp(r'(?<![\n])(•|\d+\.)'),
      (match) => '\n${match.group(1)}',
    );

    // Ensure proper spacing between paragraphs
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  Future<void> _retryLastMessage(String failedMessage) async {
    // Remove the error message
    setState(() {
      _messages.removeLast();
      _isLoading = true;
    });

    if (failedMessage.contains("Failed to initialize")) {
      await _initializeChat();
    } else {
      // Get the last user message and retry
      String? lastUserMessage;
      for (var i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i]['sender'] == 'User') {
          lastUserMessage = _messages[i]['text'];
          break;
        }
      }

      if (lastUserMessage != null) {
        await _sendMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Financial Advisor'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About AI Advisor'),
                  content: Text(
                    'This AI advisor specializes in financial guidance, including:\n\n'
                    '• Stock market analysis\n'
                    '• Cryptocurrency insights\n'
                    '• Portfolio optimization\n'
                    '• Risk management\n'
                    '• Personal finance advice\n\n'
                    'Note: This is AI-generated advice. Please consult with professional financial advisors for major financial decisions.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Ask me about investments, market trends,\nor financial advice',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildMessage(_messages[index]),
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about finance, investments, or market trends...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}