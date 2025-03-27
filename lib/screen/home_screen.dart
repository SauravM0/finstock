import 'package:flutter/material.dart';
import 'portfolio_screen.dart';
import 'market_screen.dart';
import 'ai_advisor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // TODO: Store this in a secure environment variable or configuration file
  // Get your API key from: https://makersuite.google.com/app/apikey
  final String _geminiApiKey = 'AIzaSyDVdoSvSUTP9xxYpsEBDVGAu0zkUUpMmDA'; // Replace with your actual API key

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PortfolioScreen(),
      MarketScreen(),
      AIAdvisorScreen(geminiApiKey: _geminiApiKey),
      SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
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