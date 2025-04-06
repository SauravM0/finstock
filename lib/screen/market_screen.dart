import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_data_service.dart';
import '../providers/app_state.dart';
import '../widgets/trading_view_mobile_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/portfolio_provider.dart';
import '../services/trading_service.dart';
import '../models/holding.dart';

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
  final TradingService _tradingService = TradingService();

  // List of tradable stocks
  final List<Map<String, dynamic>> tradableStocks = [
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 180.0},
    {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'price': 350.0},
    {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'price': 140.0},
    {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'price': 130.0},
    {'symbol': 'TSLA', 'name': 'Tesla, Inc.', 'price': 200.0},
  ];

  // List of tradable crypto
  final List<Map<String, dynamic>> tradableCrypto = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 30000.0},
    {'symbol': 'ETH', 'name': 'Ethereum', 'price': 1800.0},
  ];

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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 16),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
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
    return ListView.builder(
      key: key,
      physics: AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
      itemCount: tradableStocks.length + 3, // stocks + header + 2 charts
      itemBuilder: (context, index) {
        // Header with last updated
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          );
        }

        // Stocks
        if (index > 0 && index <= tradableStocks.length) {
          final stock = tradableStocks[index - 1];
          return _buildTradableAssetCard(
            symbol: stock['symbol'],
            name: stock['name'],
            price: stock['price'],
            isStock: true,
          );
        }

        // S&P 500 chart
        if (index == tradableStocks.length + 1) {
          return Container(
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
          );
        }

        // Apple chart
        return Container(
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
        );
      },
    );
  }

  Widget _buildCryptoTab({Key? key}) {
    return ListView.builder(
      key: key,
      physics: AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works
      itemCount: tradableCrypto.length + 3, // crypto + header + 2 charts
      itemBuilder: (context, index) {
        // Header with last updated
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          );
        }

        // Crypto assets
        if (index > 0 && index <= tradableCrypto.length) {
          final crypto = tradableCrypto[index - 1];
          return _buildTradableAssetCard(
            symbol: crypto['symbol'],
            name: crypto['name'],
            price: crypto['price'],
            isStock: false,
          );
        }

        // Bitcoin chart
        if (index == tradableCrypto.length + 1) {
          return Container(
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
          );
        }

        // Ethereum chart
        return Container(
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
        );
      },
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

  Widget _buildTradableAssetCard({
    required String symbol,
    required String name,
    required double price,
    required bool isStock,
  }) {
    // Generate random price change percentage between -3.0% and +3.0%
    final priceChange = (DateTime.now().millisecondsSinceEpoch % 6) - 3.0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isStock ? Colors.blue.shade100 : Colors.amber.shade100,
                  child: Text(symbol[0]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        symbol,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: priceChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add_circle_outline, color: Colors.white),
                    label: Text('Buy', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _showTradeDialog(
                        context: context,
                        symbol: symbol,
                        name: name,
                        currentPrice: price,
                        isBuy: true,
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.white),
                    label: Text('Sell', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _showTradeDialog(
                        context: context,
                        symbol: symbol,
                        name: name,
                        currentPrice: price,
                        isBuy: false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTradeDialog({
    required BuildContext context,
    required String symbol,
    required String name,
    required double currentPrice,
    required bool isBuy,
  }) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    final TextEditingController quantityController = TextEditingController();
    final action = isBuy ? 'Buy' : 'Sell';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '$action $name ($symbol)',
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Price: \$${currentPrice.toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text(isBuy
                ? 'Available Cash: \$${portfolioProvider.cashBalance.toStringAsFixed(2)}'
                : 'Current Holdings: ${_getQuantityOwned(portfolioProvider, symbol).toStringAsFixed(2)} shares'
            ),
            SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to ${isBuy ? 'buy' : 'sell'}',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) {
                final quantity = double.tryParse(quantityController.text) ?? 0;
                final totalValue = quantity * currentPrice;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Value: \$${totalValue.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isBuy && quantity > 0)
                      Text(
                        'Remaining Cash: \$${(portfolioProvider.cashBalance - totalValue).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: portfolioProvider.cashBalance >= totalValue ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBuy ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text) ?? 0;

              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid quantity'))
                );
                return;
              }

              Navigator.of(ctx).pop();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text('Processing ${isBuy ? 'purchase' : 'sale'}...'),
                        ],
                      ),
                    ),
                  );
                },
              );

              try {
                // Execute the trade
                final result = isBuy
                    ? await _tradingService.buyStock(symbol, quantity, currentPrice)
                    : await _tradingService.sellStock(symbol, quantity, currentPrice);

                // Close loading dialog
                Navigator.of(context).pop();

                if (result.success) {
                  // Update portfolio
                  bool portfolioUpdated = isBuy
                      ? await portfolioProvider.buyStock(symbol, quantity, currentPrice)
                      : await portfolioProvider.sellStock(symbol, quantity, currentPrice);

                  if (portfolioUpdated) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Show failure message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBuy
                            ? 'Insufficient funds to complete this purchase'
                            : 'Insufficient shares to complete this sale'
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                Navigator.of(context).pop();

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('An error occurred: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  double _getQuantityOwned(PortfolioProvider provider, String symbol) {
    final holding = provider.holdings.firstWhere(
      (h) => h.symbol == symbol,
      orElse: () => Holding(symbol: symbol, quantity: 0, averageCost: 0),
    );
    return holding.quantity;
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