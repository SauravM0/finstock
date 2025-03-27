import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_data_service.dart';
import '../providers/app_state.dart';
import '../widgets/trading_view_widget.dart';
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
  bool isCachedData = false;
  bool isMockData = false;
  String lastUpdated = '';
  String _selectedSymbol = 'AAPL';
  String _timeframe = '1D';
  Map<String, dynamic>? _currentChartData;
  bool _isPositiveChange = false;
  final List<String> _availableSymbols = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'BTC/USD', 'ETH/USD'];
  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '1Y', '5Y'];
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMarketData();
    _loadPreferences();
  }

  Future<void> _initializeMarketData() async {
    if (isRefreshing) return; // Prevent multiple simultaneous refreshes

    try {
      setState(() {
        isLoading = !isRefreshing; // Only show full screen loader on initial load
        isRefreshing = true;
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
            isCachedData = data['isCached'] == true;
            isMockData = data['isMock'] == true;
            lastUpdated = DateTime.now().toString().substring(0, 19); // Format: YYYY-MM-DD HH:MM:SS
            refreshCounter++; // Increment to force refresh
            isLoading = false;
            isRefreshing = false;
          });
          print('Received market data update: ${data.keys.toString()}');
        },
        onError: (e) {
          setState(() {
            error = e.toString();
            isLoading = false;
            isRefreshing = false;
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
          isRefreshing = false;
        });
      }
      print('Error initializing market data: $e');
    }
  }

  Future<void> _refreshSymbol(String symbol) async {
    try {
      setState(() {
        isRefreshing = true;
      });
      
      await _marketDataService.subscribeToSymbol(symbol.toLowerCase());
      print('Subscribed to symbol: $symbol');
      
      setState(() {
        isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        isRefreshing = false;
      });
      print('Error subscribing to symbol: $e');
      
      // Show a snackbar with the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to subscribe to $symbol: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
        // Refresh stocks
        await _refreshSymbol('AAPL');
      } else if (currentTab == 1) {
        // Refresh crypto
        await _refreshSymbol('BTCUSDT');
      } else if (currentTab == 2) {
        // Refresh news
        final news = await _marketDataService.getMarketNews();
        setState(() {
          marketNews = news;
          isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        isRefreshing = false;
      });
      
      // Show a snackbar with the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
          if (isCachedData)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: 'Using cached data',
                child: Icon(Icons.cloud_off, color: Colors.amber),
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
            onPressed: isRefreshing ? null : _initializeMarketData,
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
                      _buildStocksTab(),
                      _buildCryptoTab(),
                      _buildNewsTab(),
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
                liveMarketData = {
                  'stocks': {
                    'c': 147.56, // current price
                    'h': 148.21, // high price
                    'l': 146.08, // low price
                    'o': 146.35, // open price
                    'pc': 146.18, // previous close
                    'dp': 0.95, // percent change
                  },
                  'time': DateTime.now().millisecondsSinceEpoch,
                  'isMock': true
                };
                lastUpdated = DateTime.now().toString().substring(0, 19);
                refreshCounter++;
              });
            },
            child: Text('Continue with Demo Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksTab() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
      children: [
        if (lastUpdated.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: $lastUpdated${isCachedData ? ' (Cached)' : ''}${isMockData ? ' (Demo)' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isMockData ? Colors.orange : (isCachedData ? Colors.amber : Colors.grey),
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
        _buildStockCard('AAPL', 'Apple Inc.'),
        SizedBox(height: 16),
        _buildStockCard('MSFT', 'Microsoft Corporation'),
        SizedBox(height: 16),
        _buildStockCard('GOOGL', 'Alphabet Inc.'),
      ],
    );
  }

  Widget _buildStockCard(String symbol, String name) {
    // Extract stock data if available
    final stockPrice = liveMarketData.containsKey('stocks') 
      ? liveMarketData['stocks']['c']?.toString() ?? 'N/A' 
      : 'N/A';
    
    final stockChange = liveMarketData.containsKey('stocks') 
      ? liveMarketData['stocks']['dp']?.toString() ?? '0.0' 
      : '0.0';
    
    final isPositiveChange = (double.tryParse(stockChange) ?? 0) >= 0;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(name),
                if (isMockData)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Tooltip(
                      message: 'Demo data',
                      child: Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            subtitle: Text(symbol),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stockPrice != 'N/A')
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$$stockPrice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositiveChange ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositiveChange ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          Text(
                            '$stockChange%',
                            style: TextStyle(
                              color: isPositiveChange ? Colors.green : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: isRefreshing ? null : () => _refreshSymbol(symbol),
                ),
              ],
            ),
          ),
          // Use a key derived from refreshCounter to force rebuild when data changes
          TradingViewWidget(
            key: Key('$symbol-$refreshCounter'),
            symbol: symbol,
            isStockChart: true,
            height: 400,
            liveData: liveMarketData['stocks'],
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoTab() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
      children: [
        if (lastUpdated.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: $lastUpdated${isCachedData ? ' (Cached)' : ''}${isMockData ? ' (Demo)' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isMockData ? Colors.orange : (isCachedData ? Colors.amber : Colors.grey),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Cryptocurrency Markets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _buildCryptoCard('BTCUSDT', 'Bitcoin'),
        SizedBox(height: 16),
        _buildCryptoCard('ETHUSDT', 'Ethereum'),
      ],
    );
  }

  Widget _buildCryptoCard(String symbol, String name) {
    // Try to find price in liveMarketData
    String price = 'N/A';
    bool hasLivePrice = false;
    
    // Check in old format
    if (liveMarketData.containsKey('p')) {
      price = double.tryParse(liveMarketData['p']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00';
      hasLivePrice = true;
    } 
    // Check in new format
    else if (liveMarketData.containsKey('data') && 
        liveMarketData['data'] is List && 
        (liveMarketData['data'] as List).isNotEmpty) {
      var data = liveMarketData['data'][0];
      if (data != null && data.containsKey('p')) {
        price = double.tryParse(data['p']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00';
        hasLivePrice = true;
      }
    }
    
    // For mock data, show a sample price
    if (isMockData && !hasLivePrice) {
      price = symbol.contains('BTC') ? '29,348.75' : '1,897.32';
      hasLivePrice = true;
    }
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(name),
                if (isMockData)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Tooltip(
                      message: 'Demo data',
                      child: Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            subtitle: Text(symbol),
            trailing: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: isRefreshing ? null : () => _refreshSymbol(symbol),
            ),
          ),
          // Display the latest price if available
          if (hasLivePrice)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest Price:'),
                  Text(
                    '\$$price',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          // Use a key derived from refreshCounter to force rebuild when data changes
          TradingViewWidget(
            key: Key('$symbol-$refreshCounter'),
            symbol: symbol,
            isStockChart: false,
            height: 400,
            liveData: liveMarketData,
            useMockData: isMockData,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    if (marketNews.isEmpty) {
      return Center(
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
                      'Last updated: $lastUpdated${isCachedData ? ' (Cached)' : ''}${isMockData ? ' (Demo)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isMockData ? Colors.orange : (isCachedData ? Colors.amber : Colors.grey),
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
    } finally {
      _fetchMarketData();
    }
  }

  Future<void> _fetchMarketData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _marketDataService.getMarketData(_selectedSymbol, _timeframe, useMockData: isMockData);
      
      setState(() {
        _currentChartData = data;
        isLoading = false;
        
        // Determine if the change is positive or negative
        double? lastClose = data['close'] != null ? 
            (data['close'] as List<dynamic>).last as double? : null;
        double? firstClose = data['close'] != null && (data['close'] as List<dynamic>).isNotEmpty ? 
            (data['close'] as List<dynamic>).first as double? : null;
            
        if (lastClose != null && firstClose != null) {
          _isPositiveChange = lastClose > firstClose;
        } else {
          _isPositiveChange = false;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load market data: $e')),
      );
    }
  }

  void _changeSymbol(String symbol) {
    setState(() {
      _selectedSymbol = symbol;
    });
    _fetchMarketData();
  }

  void _changeTimeframe(String timeframe) {
    setState(() {
      _timeframe = timeframe;
    });
    _fetchMarketData();
  }
}