import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_data_service.dart';
import '../providers/app_state.dart';
import '../widgets/trading_view_mobile_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late MarketDataService _marketDataService;
  late TabController _tabController;
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> marketNews = [];
  Map<String, dynamic> liveMarketData = {};
  int refreshCounter = 0; // Used to force refresh TradingViewWidget
  bool isRefreshing = false;
  bool isMockData = false;
  String lastUpdated = '';
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMarketData();
    _loadPreferences();
  }

  Future<void> _initializeMarketData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      _marketDataService = MarketDataService();
      await _marketDataService.initialize();

      // Subscribe to market data updates
      _marketDataService.dataStream.listen(
        (data) {
          // Handle real-time market data updates
          setState(() {
            liveMarketData = data;
            isMockData = data['isMock'] == true;
            lastUpdated = DateTime.now().toString().substring(0, 19); // Format: YYYY-MM-DD HH:MM:SS
            refreshCounter++; // Increment to force refresh
            isLoading = false;
          });
          print('Received market data update: ${data.keys.toString()}');
        },
        onError: (e) {
          setState(() {
            error = e.toString();
            isLoading = false;
          });
          print('Market data stream error: $e');
        },
      );

      // Fetch market news
      try {
        final news = await _marketDataService.getMarketNews();
        if (mounted) {
          setState(() {
            marketNews = news;
          });
        }
      } catch (e) {
        print('Error fetching market news: $e');
        // Don't set global error for news failure
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
      print('Error initializing market data: $e');
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (isRefreshing) return; // Prevent multiple refreshes

    final currentTab = _tabController.index;
    
    setState(() {
      isRefreshing = true;
    });
    
    try {
      if (currentTab == 0) {
        // Refresh stocks (increment the counter to force TradingView refresh)
        setState(() {
          refreshCounter++;
        });
      } else if (currentTab == 1) {
        // Refresh crypto
        setState(() {
          refreshCounter++;
        });
      } else if (currentTab == 2) {
        // Refresh news
        final news = await _marketDataService.getMarketNews();
        setState(() {
          marketNews = news;
        });
      }
    } catch (e) {
      print('Error refreshing: $e');
    } finally {
      setState(() {
        isRefreshing = false;
        lastUpdated = DateTime.now().toString().substring(0, 19);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _marketDataService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market Data'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Stocks'),
            Tab(text: 'Crypto'),
            Tab(text: 'News'),
          ],
        ),
        actions: [
          if (isMockData)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: 'Using demo data',
                child: Icon(Icons.data_array, color: Colors.orange),
              ),
            ),
          IconButton(
            icon: isRefreshing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.refresh),
            onPressed: isRefreshing ? null : _refreshCurrentTab,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStocksTab(key: PageStorageKey('stocks-tab')),
                      _buildCryptoTab(key: PageStorageKey('crypto-tab')),
                      _buildNewsTab(key: PageStorageKey('news-tab')),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              error!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeMarketData,
            child: Text('Retry'),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Clear the error and show mock data instead
              setState(() {
                error = null;
                isLoading = false;
                isMockData = true;
                refreshCounter++;
                lastUpdated = DateTime.now().toString().substring(0, 19);
              });
            },
            child: Text('Continue with Demo Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksTab({Key? key}) {
    return ListView(
      key: key,
      physics: AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
      children: [
        if (lastUpdated.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: $lastUpdated${isMockData ? ' (Demo)' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isMockData ? Colors.orange : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Popular Stocks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        // Stock chart
        Container(
          height: 350,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'S&P 500',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TradingViewMobileWidget(
                      symbol: 'SPY',
                      isStockChart: true,
                      useMockData: isMockData,
                      liveData: liveMarketData,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Additional stock charts would follow here
        Container(
          height: 350,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apple Inc.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TradingViewMobileWidget(
                      symbol: 'AAPL',
                      isStockChart: true,
                      useMockData: isMockData,
                      liveData: liveMarketData,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCryptoTab({Key? key}) {
    return ListView(
      key: key,
      physics: AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
      children: [
        if (lastUpdated.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: $lastUpdated${isMockData ? ' (Demo)' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isMockData ? Colors.orange : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Cryptocurrencies',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        // Bitcoin chart
        Container(
          height: 350,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bitcoin (BTC)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TradingViewMobileWidget(
                      symbol: 'BTC',
                      isStockChart: false,
                      useMockData: isMockData,
                      liveData: liveMarketData,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Ethereum chart
        Container(
          height: 350,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ethereum (ETH)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TradingViewMobileWidget(
                      symbol: 'ETH',
                      isStockChart: false,
                      useMockData: isMockData,
                      liveData: liveMarketData,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsTab({Key? key}) {
    if (marketNews.isEmpty) {
      return Center(
        key: key,
        child: isRefreshing
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No market news available'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        setState(() {
                          isRefreshing = true;
                        });
                        final news = await _marketDataService.getMarketNews();
                        setState(() {
                          marketNews = news;
                          isRefreshing = false;
                        });
                      } catch (e) {
                        setState(() {
                          isRefreshing = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to load news: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text('Reload News'),
                  ),
                ],
              ),
      );
    }
    
    return ListView.builder(
      key: key,
      physics: AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
      itemCount: marketNews.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header with last updated time
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market News',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (lastUpdated.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Last updated: $lastUpdated${isMockData ? ' (Demo)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isMockData ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        
        final newsIndex = index - 1;
        final news = marketNews[newsIndex];
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(news['title'] ?? ''),
                ),
                if (isMockData)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Tooltip(
                      message: 'Demo content',
                      child: Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(news['summary'] ?? ''),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      news['date'] ?? '',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (news['source'] != null)
                      Text(
                        news['source'],
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // Handle news item tap
              if (news['url'] != null && news['url'].toString().isNotEmpty) {
                // Open URL if available
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening article...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _loadPreferences() async {
    try {
      // Load mock data preference
      String? useMockDataStr = await _storage.read(key: 'use_mock_data');
      setState(() {
        isMockData = useMockDataStr == 'true';
      });
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }
}