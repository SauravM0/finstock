import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'portfolio_screen.dart';
import 'market_screen.dart';
import 'ai_advisor_screen.dart';
import 'settings_screen.dart';
import 'portfolio_suggestions_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _storage = FlutterSecureStorage();
  late final List<Widget> _screens;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  Future<void> _initializeScreens() async {
    try {
      // Initialize screens
      _screens = [
        PortfolioScreen(),
        MarketScreen(),
        AIAdvisorScreen(),
        PortfolioSuggestionsScreen(),
        SettingsScreen(),
      ];

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing screens: $e');

      // Fallback initialization
      _screens = [
        PortfolioScreen(),
        MarketScreen(),
        AIAdvisorScreen(),
        PortfolioSuggestionsScreen(),
        SettingsScreen(),
      ];

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get the theme's color scheme
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        animationDuration: const Duration(milliseconds: 800),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.assistant_outlined),
            selectedIcon: Icon(Icons.assistant),
            label: 'AI Advisor',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Portfolio AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}