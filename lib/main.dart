import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screen/login_screen.dart'; // Import all screen files
import 'screen/home_screen.dart';
import 'screen/market_screen.dart';
import 'providers/app_state.dart';
import 'services/ai_financial_service.dart';
import 'providers/ai_financial_provider.dart';
import 'screen/ai_financial_screen.dart';
import 'services/api_key_service.dart';
import 'services/investment_agent_service.dart';
import 'providers/investment_agent_provider.dart';
import 'screen/ai_investment_agent_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get the Gemini API key from secure storage
  final geminiApiKey = await ApiKeyService.getGeminiApiKey();
  
  // Only validate if the key is not empty
  bool isValidApiKey = false;
  if (geminiApiKey.isNotEmpty) {
    isValidApiKey = await ApiKeyService.validateGeminiApiKey(geminiApiKey);
    if (!isValidApiKey) {
      print('Warning: Gemini API key validation failed. Some AI features may not work correctly.');
    }
  } else {
    print('No Gemini API key provided. AI features will not be available.');
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AIFinancialService>(
          create: (_) => AIFinancialService(
            geminiApiKey: geminiApiKey,
          ),
        ),
        ChangeNotifierProxyProvider<AIFinancialService, AIFinancialProvider>(
          create: (context) => AIFinancialProvider(
            aiService: context.read<AIFinancialService>(),
          ),
          update: (context, aiService, previous) => AIFinancialProvider(
            aiService: aiService,
          ),
        ),
        Provider<InvestmentAgentService>(
          create: (_) => InvestmentAgentService(
            apiKey: geminiApiKey,
          ),
        ),
        ChangeNotifierProxyProvider<InvestmentAgentService, InvestmentAgentProvider>(
          create: (context) => InvestmentAgentProvider(
            service: context.read<InvestmentAgentService>(),
          ),
          update: (context, service, previous) => InvestmentAgentProvider(
            service: service,
          ),
        ),
      ],
      child: ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MyApp(geminiApiKey: geminiApiKey, hasValidApiKey: isValidApiKey),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String geminiApiKey;
  final bool hasValidApiKey;
  
  const MyApp({Key? key, required this.geminiApiKey, required this.hasValidApiKey}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: LoginScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/market': (context) => MarketScreen(),
        '/ai_financial': (context) => AIFinancialScreen(geminiApiKey: geminiApiKey),
        '/investment_agent': (context) => AIInvestmentAgentScreen(),
      },
    );
  }
}