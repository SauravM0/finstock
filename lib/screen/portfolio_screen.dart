import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/holding.dart';

class PortfolioScreen extends StatefulWidget {
  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedTimeRange = '1M';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Portfolio'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Assets'),
            Tab(text: 'Performance'),
          ],
        ),
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, portfolioProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(portfolioProvider),
              _buildAssetsTab(portfolioProvider),
              _buildPerformanceTab(portfolioProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCashDialog(context);
        },
        child: Icon(Icons.add),
        tooltip: 'Add Cash',
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab(PortfolioProvider portfolioProvider) {
    return FutureBuilder<double>(
      future: portfolioProvider.getTotalPortfolioValue(),
      builder: (context, snapshot) {
        double totalValue = snapshot.data ?? 0.0;
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPortfolioHeader(totalValue, portfolioProvider),
              _buildAssetAllocationChart(portfolioProvider),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Your Holdings', style: Theme.of(context).textTheme.titleLarge),
              ),
              _buildHoldingsList(portfolioProvider),
            ],
          ),
        );
      }
    );
  }

  // Assets Tab
  Widget _buildAssetsTab(PortfolioProvider portfolioProvider) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildCashCard(portfolioProvider),
        SizedBox(height: 16),
        Text('Your Investments', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 8),
        ...portfolioProvider.holdings.map((holding) => _buildAssetCard(holding)),
      ],
    );
  }

  // Performance Tab with fl_chart
  Widget _buildPerformanceTab(PortfolioProvider portfolioProvider) {
    return Column(
      children: [
        _buildTimeRangeSelector(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: FutureBuilder<double>(
              future: portfolioProvider.getTotalPortfolioValue(),
              builder: (context, snapshot) {
                double totalValue = snapshot.data ?? 0.0;
                
                // For demo purposes, generate some mock history points
                final List<FlSpot> spots = List.generate(
                  7,
                  (index) => FlSpot(
                    index.toDouble(),
                    totalValue * (0.95 + (index / 50)), // Create some variation
                  ),
                );
                
                return LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('\$${value.toInt()}');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final int day = value.toInt();
                            final daysAgo = 6 - day;
                            return Text(daysAgo == 0 ? 'Today' : '$daysAgo d');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Show portfolio performance summary
        Padding(
          padding: EdgeInsets.all(16),
          child: _buildPerformanceSummary(portfolioProvider),
        ),
      ],
    );
  }

  // Enhanced Portfolio Header
  Widget _buildPortfolioHeader(double totalValue, PortfolioProvider portfolioProvider) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Portfolio Value',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 12),
          Text(
            '\$${totalValue.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
              SizedBox(width: 4),
              Text(
                'Cash: \$${portfolioProvider.cashBalance.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Asset Allocation Chart
  Widget _buildAssetAllocationChart(PortfolioProvider portfolioProvider) {
    return Container(
      height: 280,
      padding: EdgeInsets.all(16),
      child: FutureBuilder<double>(
        future: portfolioProvider.getTotalPortfolioValue(),
        builder: (context, snapshot) {
          double totalValue = snapshot.data ?? 0.0;
          double investedValue = totalValue - portfolioProvider.cashBalance;
          
          // For simplicity, we'll just show cash vs invested
          List<PieChartSectionData> sections = [
            PieChartSectionData(
              color: Colors.blue,
              value: investedValue,
              title: 'Invested',
              titleStyle: TextStyle(color: Colors.white, fontSize: 12),
              radius: 100,
            ),
            PieChartSectionData(
              color: Colors.green,
              value: portfolioProvider.cashBalance,
              title: 'Cash',
              titleStyle: TextStyle(color: Colors.white, fontSize: 12),
              radius: 100,
            ),
          ];
          
          return Column(
            children: [
              Text(
                'Asset Allocation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 12),
              Expanded(
                child: totalValue > 0
                    ? PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      )
                    : Center(
                        child: Text('Add assets to see your allocation'),
                      ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Invested', Colors.blue),
                  SizedBox(width: 16),
                  _buildLegendItem('Cash', Colors.green),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Holdings List for Overview Tab
  Widget _buildHoldingsList(PortfolioProvider portfolioProvider) {
    if (portfolioProvider.holdings.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No holdings yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Visit the Market tab to invest in stocks and crypto',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 80),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: portfolioProvider.holdings.length,
      itemBuilder: (context, index) {
        final holding = portfolioProvider.holdings[index];
        // Generate a mock current price based on average cost
        final currentPrice = holding.averageCost * (0.9 + (0.2 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
        final currentValue = holding.quantity * currentPrice;
        final gainLoss = currentValue - holding.totalCost;
        final gainLossPercent = (gainLoss / holding.totalCost) * 100;
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(holding.symbol[0]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.symbol,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${holding.quantity.toStringAsFixed(2)} shares • \$${holding.averageCost.toStringAsFixed(2)} avg cost',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${currentValue.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${gainLossPercent >= 0 ? '+' : ''}${gainLossPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: gainLossPercent >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Asset Card for Assets Tab
  Widget _buildAssetCard(Holding holding) {
    // Generate a mock current price based on average cost
    final currentPrice = holding.averageCost * (0.9 + (0.2 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
    final currentValue = holding.quantity * currentPrice;
    final gainLoss = currentValue - holding.totalCost;
    final gainLossPercent = (gainLoss / holding.totalCost) * 100;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(holding.symbol[0]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.symbol,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Current: \$${currentPrice.toStringAsFixed(2)} | Avg: \$${holding.averageCost.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAssetDetailItem('Shares', '${holding.quantity.toStringAsFixed(2)}'),
                _buildAssetDetailItem('Value', '\$${currentValue.toStringAsFixed(2)}'),
                _buildAssetDetailItem(
                  'Gain/Loss',
                  '${gainLossPercent >= 0 ? '+' : ''}${gainLossPercent.toStringAsFixed(2)}%',
                  color: gainLossPercent >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Cash Card for Assets Tab
  Widget _buildCashCard(PortfolioProvider portfolioProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.attach_money, color: Colors.green),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Balance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Available for investment',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              '\$${portfolioProvider.cashBalance.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // Time Range Selector
  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['1D', '1W', '1M', '3M', '1Y', 'All'].map((range) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTimeRange = range;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selectedTimeRange == range ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: selectedTimeRange == range ? Colors.white : Colors.black,
                  fontWeight: selectedTimeRange == range ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // Performance Summary Widget
  Widget _buildPerformanceSummary(PortfolioProvider portfolioProvider) {
    return FutureBuilder<double>(
      future: portfolioProvider.getTotalPortfolioValue(),
      builder: (context, snapshot) {
        double totalValue = snapshot.data ?? 0.0;
        
        // Generate mock performance data
        final dayChange = (totalValue * 0.005) * (DateTime.now().millisecondsSinceEpoch % 3 == 0 ? -1 : 1);
        final weekChange = (totalValue * 0.02) * (DateTime.now().millisecondsSinceEpoch % 2 == 0 ? -1 : 1);
        final monthChange = (totalValue * 0.05);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Summary', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            _buildPerformanceItem('Today', dayChange, totalValue),
            SizedBox(height: 8),
            _buildPerformanceItem('Past Week', weekChange, totalValue),
            SizedBox(height: 8),
            _buildPerformanceItem('Past Month', monthChange, totalValue),
          ],
        );
      },
    );
  }
  
  // Performance Item
  Widget _buildPerformanceItem(String period, double change, double total) {
    final percentChange = (change / total) * 100;
    final isPositive = change >= 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(period, style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Text(
              '${isPositive ? '+' : ''}\$${change.toStringAsFixed(2)}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '(${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Helper Widgets
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }
  
  Widget _buildAssetDetailItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  // Add Cash Dialog
  void _showAddCashDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Cash to Your Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
                portfolioProvider.addCash(amount);
                Navigator.of(ctx).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added \$${amount.toStringAsFixed(2)} to your account'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Add Cash'),
          ),
        ],
      ),
    );
  }
}

// Asset Detail Screen
class AssetDetailScreen extends StatelessWidget {
  final String assetName;
  final Map<String, dynamic> assetData;
  
  const AssetDetailScreen({
    Key? key,
    required this.assetName,
    required this.assetData,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(assetName),
      ),
      body: Center(
        child: Text('Asset Details Coming Soon'),
      ),
    );
  }
}