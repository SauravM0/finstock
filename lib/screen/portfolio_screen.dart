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
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).hintColor,
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
        double investedValue = totalValue - portfolioProvider.cashBalance;
        double investedPercentage = totalValue > 0 ? (investedValue / totalValue) * 100 : 0;
        double cashPercentage = totalValue > 0 ? (portfolioProvider.cashBalance / totalValue) * 100 : 0;
        
        // Get the last updated time
        DateTime now = DateTime.now();
        String lastUpdated = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
        
        // Calculate overall P/L estimates
        double dailyChange = totalValue * 0.01; // For demo, assume 1% daily change
        double overallGainLoss = 0;
        double overallGainLossPercent = 0;
        
        if (portfolioProvider.holdings.isNotEmpty) {
          double totalCost = portfolioProvider.holdings.fold(
            0.0, 
            (prev, holding) => prev + holding.totalCost
          );
          
          overallGainLoss = investedValue - totalCost;
          overallGainLossPercent = totalCost > 0 ? (overallGainLoss / totalCost) * 100 : 0;
        }
        
        // Find top performers and losers
        List<Holding> sortedHoldings = List.from(portfolioProvider.holdings);
        if (sortedHoldings.isNotEmpty) {
          sortedHoldings.sort((a, b) {
            double aProfit = (a.currentPrice - a.averageCost) / a.averageCost;
            double bProfit = (b.currentPrice - b.averageCost) / b.averageCost;
            return bProfit.compareTo(aProfit); // Descending order
          });
        }
        
        List<Holding> topPerformers = sortedHoldings.take(3).toList();
        List<Holding> worstPerformers = sortedHoldings.reversed.take(3).toList();
        
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            // Portfolio summary KPIs
            _buildPortfolioHeader(totalValue, portfolioProvider, overallGainLoss, overallGainLossPercent),
            
            // Last updated indicator
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                child: Text(
                  'Last updated: $lastUpdated',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            
            // Portfolio breakdown card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBreakdownItem(
                            'Invested',
                            '\$${investedValue.toStringAsFixed(2)}',
                            '${investedPercentage.toStringAsFixed(1)}%',
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        Expanded(
                          child: _buildBreakdownItem(
                            'Cash',
                            '\$${portfolioProvider.cashBalance.toStringAsFixed(2)}',
                            '${cashPercentage.toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    ),
                    
                    if (portfolioProvider.holdings.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 8),
                      Text(
                        'Asset Allocation',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 200, // Reduced height for better layout
                        child: _buildAssetAllocationChart(portfolioProvider),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Top performers
            if (topPerformers.isNotEmpty) ...[
              Text(
                'Top Performers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              ...topPerformers.map((holding) => _buildPerformerItem(holding, isGainer: true)),
              SizedBox(height: 24),
            ],
            
            // Worst performers
            if (worstPerformers.isNotEmpty) ...[
              Text(
                'Underperforming Assets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              ...worstPerformers.map((holding) => _buildPerformerItem(holding, isGainer: false)),
              SizedBox(height: 24),
            ],
            
            // Holdings count
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Assets',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${portfolioProvider.holdings.length} holdings',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    Icon(
                      Icons.analytics_outlined,
                      size: 28,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // View all holdings button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.visibility),
                label: Text('View All Holdings'),
                onPressed: () {
                  _tabController.animateTo(1); // Switch to Assets tab
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            SizedBox(height: 32),
          ],
        );
      }
    );
  }

  // Enhanced Portfolio Header
  Widget _buildPortfolioHeader(
    double totalValue, 
    PortfolioProvider portfolioProvider,
    double overallGainLoss,
    double overallGainLossPercent,
  ) {
    bool isPositive = overallGainLossPercent >= 0;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Portfolio Value',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).hintColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '\$${totalValue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 12),
          if (overallGainLoss != 0) Row(
            children: [
              Text(
                'Overall: ',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '${isPositive ? '+' : ''}\$${overallGainLoss.toStringAsFixed(2)} (${isPositive ? '+' : ''}${overallGainLossPercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isPositive ? Colors.black : Colors.black,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isPositive ? Colors.black : Colors.black,
              )
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiItem('Holdings', '${portfolioProvider.holdings.length}'),
              _buildKpiItem('Invested', '\$${(totalValue - portfolioProvider.cashBalance).toStringAsFixed(2)}'),
              _buildKpiItem('Cash', '\$${portfolioProvider.cashBalance.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildKpiItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBreakdownItem(String label, String value, String percentage) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
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
              color: Colors.black,
              value: investedValue,
              title: 'Invested',
              titleStyle: TextStyle(color: Colors.white, fontSize: 12),
              radius: 100,
            ),
            PieChartSectionData(
              color: Colors.grey[300],
              value: portfolioProvider.cashBalance,
              title: 'Cash',
              titleStyle: TextStyle(color: Colors.black, fontSize: 12),
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
                  _buildLegendItem('Invested', Colors.black),
                  SizedBox(width: 16),
                  _buildLegendItem('Cash', Colors.grey[300]!),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPerformerItem(Holding holding, {required bool isGainer}) {
    double gainLossPercent = ((holding.currentPrice - holding.averageCost) / holding.averageCost) * 100;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              holding.symbol[0],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.symbol,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${holding.quantity.toStringAsFixed(2)} shares',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${holding.currentPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  Icon(
                    gainLossPercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  Text(
                    '${gainLossPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
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
                    minX: 0,
                    maxX: 6,
                    minY: totalValue * 0.9,
                    maxY: totalValue * 1.1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.black,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('\$${value.toInt()}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final int day = value.toInt();
                            final daysAgo = 6 - day;
                            return Text(daysAgo == 0 ? 'Today' : '$daysAgo d',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      verticalInterval: 1,
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        );
                      },
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[300]!),
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
                color: selectedTimeRange == range 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: selectedTimeRange == range 
                      ? Colors.white
                      : Colors.black,
                  fontWeight: selectedTimeRange == range 
                      ? FontWeight.bold 
                      : FontWeight.normal,
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                Text(
                  '${percentChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
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
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
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
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
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
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
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

  // Asset Card for Assets Tab
  Widget _buildAssetCard(Holding holding) {
    final currentValue = holding.quantity * holding.currentPrice;
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
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    holding.symbol[0],
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.symbol,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Current: \$${holding.currentPrice.toStringAsFixed(2)} | Avg: \$${holding.averageCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).hintColor, 
                          fontSize: 14
                        ),
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
                  '${gainLossPercent.toStringAsFixed(2)}%',
                ),
              ],
            ),
          ],
        ),
      ),
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
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.black,
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