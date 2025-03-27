import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_data_service.dart';
import '../providers/app_state.dart';
import '../widgets/trading_view_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMarketData();
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
            isLoading = false;
          });
        },
        onError: (e) {
          setState(() {
            error = e.toString();
            isLoading = false;
          });
        },
      );

      // Fetch market news
      final news = await _marketDataService.getMarketNews();
      setState(() {
        marketNews = news;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeMarketData,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStocksTab(),
                    _buildCryptoTab(),
                    _buildNewsTab(),
                  ],
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
          Text(
            error!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeMarketData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksTab() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Popular Stocks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        TradingViewWidget(
          symbol: 'AAPL',
          isStockChart: true,
          height: 400,
        ),
        SizedBox(height: 16),
        TradingViewWidget(
          symbol: 'MSFT',
          isStockChart: true,
          height: 400,
        ),
        SizedBox(height: 16),
        TradingViewWidget(
          symbol: 'GOOGL',
          isStockChart: true,
          height: 400,
        ),
      ],
    );
  }

  Widget _buildCryptoTab() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Cryptocurrency Markets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        TradingViewWidget(
          symbol: 'BTCUSDT',
          isStockChart: false,
          height: 400,
        ),
        SizedBox(height: 16),
        TradingViewWidget(
          symbol: 'ETHUSDT',
          isStockChart: false,
          height: 400,
        ),
      ],
    );
  }

  Widget _buildNewsTab() {
    return ListView.builder(
      itemCount: marketNews.length,
      itemBuilder: (context, index) {
        final news = marketNews[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(news['title'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(news['summary'] ?? ''),
                SizedBox(height: 4),
                Text(
                  news['date'] ?? '',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Handle news item tap
            },
          ),
        );
      },
    );
  }
}