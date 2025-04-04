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
import 'services/market_data_service.dart';
import 'providers/portfolio_provider.dart';
import 'providers/user_preferences_provider.dart';
import 'providers/investment_agent_provider.dart';
import 'screen/portfolio_suggestions_screen.dart';

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
  
  // Create the market data service
  final marketDataService = MarketDataService();
  await marketDataService.initialize();
  
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
        // Add investment agent provider
        ChangeNotifierProvider<InvestmentAgentProvider>(
          create: (_) => InvestmentAgentProvider(),
        ),
        // Add market data service provider
        Provider<MarketDataService>.value(
          value: marketDataService,
        ),
        // Add portfolio provider
        ChangeNotifierProxyProvider<MarketDataService, PortfolioProvider>(
          create: (context) => PortfolioProvider(
            marketDataService: context.read<MarketDataService>(),
          )..addSampleHoldings(), // Initialize with sample data
          update: (context, marketDataService, previous) => previous!,
        ),
        // Add user preferences provider
        ChangeNotifierProvider<UserPreferencesProvider>(
          create: (_) => UserPreferencesProvider(),
        ),
      ],
      child: ChangeNotifierProvider(
        create: (_) => AppState(),
        child: AppTheme(geminiApiKey: geminiApiKey, hasValidApiKey: isValidApiKey),
      ),
    ),
  );
}

class AppTheme extends StatelessWidget {
  final String geminiApiKey;
  final bool hasValidApiKey;
  
  const AppTheme({Key? key, required this.geminiApiKey, required this.hasValidApiKey}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinStock',
      debugShowCheckedModeBanner: false,
      theme: _buildBlackAndWhiteTheme(),
      home: LoginScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/market': (context) => MarketScreen(),
        '/ai_financial': (context) => AIFinancialScreen(geminiApiKey: geminiApiKey),
        '/portfolio_suggestions': (context) => PortfolioSuggestionsScreen(),
      },
    );
  }
  
  // Build black and white theme
  ThemeData _buildBlackAndWhiteTheme() {
    return ThemeData(
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.light,
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
      
      // Tab bar theme
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.black,
        unselectedLabelColor: Color(0xFF707070),
        indicatorColor: Colors.black,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF707070)),
        labelStyle: const TextStyle(color: Colors.black),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Color(0xFF707070),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: Colors.black,
      ),
      
      // Divider color
      dividerColor: Colors.black,
      
      // Hint color
      hintColor: const Color(0xFF707070),
      
      // Primary color swatch - using a black MaterialColor
      primarySwatch: const MaterialColor(
        0xFF000000,
        <int, Color>{
          50: Colors.black,
          100: Colors.black,
          200: Colors.black,
          300: Colors.black,
          400: Colors.black,
          500: Colors.black,
          600: Colors.black,
          700: Colors.black,
          800: Colors.black,
          900: Colors.black,
        },
      ),
    );
  }
}