import 'package:flutter/material.dart';
import 'ai_chatbot_screen.dart';

class AIAdvisorScreen extends StatelessWidget {
  final String geminiApiKey;

  const AIAdvisorScreen({
    Key? key,
    required this.geminiApiKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Advisor')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Personalized insights for your financial growth',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              title: Text('Buy Tesla'),
              subtitle: Text('Confidence: 85%\nStrong earnings growth expected'),
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
          SizedBox(height: 16),
          Text('Market Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            title: Text('Tech Sector Bullish Trend'),
            subtitle: Text('Tech stocks up 5% this week'),
          ),
          SizedBox(height: 16),
          Column(
            children: [
              Text('Portfolio Health Score', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              CircularProgressIndicator(value: 0.75, strokeWidth: 8),
              SizedBox(height: 8),
              Text('75/100 - Good'),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIChatbotScreen(
                  geminiApiKey: geminiApiKey,
                ),
              ),
            ),
            child: Text('Ask AI'),
          ),
        ],
      ),
    );
  }
}