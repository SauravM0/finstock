import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screen/login_screen.dart'; // Import all screen files
import 'screen/home_screen.dart';
import 'screen/market_screen.dart';
import 'providers/app_state.dart';
import 'services/ai_financial_service.dart';
import 'providers/ai_financial_provider.dart';
import 'screen/ai_financial_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<AIFinancialService>(
          create: (_) => AIFinancialService(
            geminiApiKey: 'YOUR_GEMINI_API_KEY',
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
      ],
      child: ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
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
        '/market': (context) => MarketScreen(), // Added MarketScreen route
      },
    );
  }
}