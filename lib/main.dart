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
    // Get the current theme mode from the UserPreferencesProvider
    final userPreferences = Provider.of<UserPreferencesProvider>(context);
    final isDarkMode = userPreferences.isDarkMode;

    return MaterialApp(
      title: 'FinStock',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: LoginScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/market': (context) => MarketScreen(),
        '/ai_financial': (context) => AIFinancialScreen(geminiApiKey: geminiApiKey),
        '/portfolio_suggestions': (context) => PortfolioSuggestionsScreen(),
      },
    );
  }

  // Build light theme with Material 3 design
  ThemeData _buildLightTheme() {
    // Define the color scheme for light mode
    const ColorScheme colorScheme = ColorScheme.light(
      primary: Color(0xFF0A3D62),      // Deep blue
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E4FF),
      onPrimaryContainer: Color(0xFF001D36),
      secondary: Color(0xFF2E86DE),    // Lighter blue
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD8E2FF),
      onSecondaryContainer: Color(0xFF001A41),
      tertiary: Color(0xFF2ECC71),     // Green for positive values
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFB8F5C9),
      onTertiaryContainer: Color(0xFF002111),
      error: Color(0xFFE74C3C),        // Red for errors/negative values
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      background: Colors.white,
      onBackground: Color(0xFF1A1C1E),
      surface: Colors.white,
      onSurface: Color(0xFF1A1C1E),
      surfaceVariant: Color(0xFFE7E0EC),
      onSurfaceVariant: Color(0xFF49454F),
      outline: Color(0xFF79747E),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFF303033),
      onInverseSurface: Color(0xFFF3F3F3),
      inversePrimary: Color(0xFFADC6FF),
      surfaceTint: Color(0xFF0A3D62),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.light,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A3D62),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 0;
              if (states.contains(MaterialState.hovered)) return 2;
              return 1;
            },
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          animationDuration: const Duration(milliseconds: 200),
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.white.withOpacity(0.1);
              }
              return null;
            },
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: MaterialStateProperty.resolveWith<BorderSide>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return BorderSide(color: colorScheme.primary, width: 2);
              }
              return BorderSide(color: colorScheme.outline, width: 1);
            },
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
      ),

      // Tab bar theme
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        helperStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
        errorStyle: TextStyle(color: colorScheme.error),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 3,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Navigation bar theme (for bottom navigation)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        elevation: 3,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        actionTextColor: colorScheme.inversePrimary,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimary),
      ),
    );
  }

  // Build dark theme with Material 3 design
  ThemeData _buildDarkTheme() {
    // Define the color scheme for dark mode
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: Color(0xFF90CAF9),      // Light blue
      onPrimary: Color(0xFF003258),
      primaryContainer: Color(0xFF00497B),
      onPrimaryContainer: Color(0xFFD1E4FF),
      secondary: Color(0xFF7BB5F5),    // Lighter blue
      onSecondary: Color(0xFF00325A),
      secondaryContainer: Color(0xFF004880),
      onSecondaryContainer: Color(0xFFD1E4FF),
      tertiary: Color(0xFF6CDA97),     // Green for positive values
      onTertiary: Color(0xFF003919),
      tertiaryContainer: Color(0xFF005229),
      onTertiaryContainer: Color(0xFF89F8B1),
      error: Color(0xFFFF8980),        // Red for errors/negative values
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFFFDAD6),
      background: Color(0xFF1A1C1E),
      onBackground: Color(0xFFE2E2E5),
      surface: Color(0xFF1A1C1E),
      onSurface: Color(0xFFE2E2E5),
      surfaceVariant: Color(0xFF44474E),
      onSurfaceVariant: Color(0xFFC5C6D0),
      outline: Color(0xFF8E9099),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFFE2E2E5),
      onInverseSurface: Color(0xFF2F3033),
      inversePrimary: Color(0xFF0061A6),
      surfaceTint: Color(0xFF90CAF9),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1C1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 0;
              if (states.contains(MaterialState.hovered)) return 2;
              return 1;
            },
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          animationDuration: const Duration(milliseconds: 200),
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.black.withOpacity(0.1);
              }
              return null;
            },
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          side: MaterialStateProperty.resolveWith<BorderSide>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return BorderSide(color: colorScheme.primary, width: 2);
              }
              return BorderSide(color: colorScheme.outline, width: 1);
            },
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
        color: const Color(0xFF2C2F33), // Slightly lighter than background
      ),

      // Tab bar theme
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2F33),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        helperStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
        errorStyle: TextStyle(color: colorScheme.error),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: const Color(0xFF2C2F33),
        elevation: 3,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Navigation bar theme (for bottom navigation)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1C1E),
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        elevation: 3,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        actionTextColor: colorScheme.inversePrimary,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimary),
      ),
    );
  }
}