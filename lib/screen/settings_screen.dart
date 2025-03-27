import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = FlutterSecureStorage();
  bool _isLoading = true;
  bool _useMockData = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Load mock data preference
      String? useMockDataStr = await _storage.read(key: 'use_mock_data');
      _useMockData = useMockDataStr == 'true';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMockData(bool value) async {
    try {
      await _storage.write(key: 'use_mock_data', value: value.toString());
      setState(() => _useMockData = value);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value 
            ? 'Mock data enabled. App will use offline data.' 
            : 'Mock data disabled. App will use real data when available.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update setting: $e')),
      );
    }
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              
              Text(
                'Data Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16.0),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mock Data Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'When enabled, the app will use locally generated mock data instead of making API calls. This is useful for testing or when you have limited internet connectivity.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      SwitchListTile(
                        title: Text('Use Mock Data'),
                        subtitle: Text(
                          _useMockData
                              ? 'Using offline demo data'
                              : 'Using real-time market data when available'
                        ),
                        value: _useMockData,
                        onChanged: _toggleMockData,
                        secondary: Icon(
                          _useMockData ? Icons.cloud_off : Icons.cloud_done,
                          color: _useMockData ? Colors.orange : Colors.green,
                        ),
                      ),
                      if (_useMockData)
                        Container(
                          padding: EdgeInsets.all(8.0),
                          color: Colors.orange.shade50,
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Mock data mode is enabled. The app will show simulated data.',
                                  style: TextStyle(color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24.0),
              
              Text(
                'Network Status',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16.0),
              
              FutureBuilder<bool>(
                future: _checkConnectivity(),
                builder: (context, snapshot) {
                  bool isConnected = snapshot.data ?? false;
                  
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            isConnected ? Icons.wifi : Icons.wifi_off,
                            color: isConnected ? Colors.green : Colors.red,
                            size: 36,
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isConnected ? 'Connected' : 'Offline',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isConnected ? Colors.green : Colors.red,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  isConnected 
                                    ? 'You have an active internet connection. The app can fetch real-time data.'
                                    : 'No internet connection detected. The app will use cached or mock data.',
                                  style: TextStyle(
                                    color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 24.0),
              
              Text(
                'About',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16.0),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.bar_chart, color: Colors.white),
                        ),
                        title: Text(
                          'Finance AI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text('Version 1.0.0'),
                      ),
                      Divider(),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Finance AI is a comprehensive financial app with AI-powered insights, market data visualization, and investment tracking capabilities.',
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        '© 2023 Finance AI',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24.0),
              
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Finance AI',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2023 Finance AI',
                      children: [
                        SizedBox(height: 16.0),
                        Text(
                          'A finance app with AI-powered insights and market data visualization.',
                        ),
                      ],
                    );
                  },
                  icon: Icon(Icons.info_outline),
                  label: Text('About this app'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}