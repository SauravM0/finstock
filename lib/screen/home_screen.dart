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
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assistant),
            label: 'AI Advisor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Portfolio AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}