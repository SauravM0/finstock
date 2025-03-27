import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PortfolioScreen extends StatefulWidget {
  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedTimeRange = '1M';

  // Sample portfolio data
  final Map<String, Map<String, dynamic>> portfolioData = {
    'Apple (AAPL)': {
      'value': 15000.0,
      'shares': 100,
      'change': 2.8,
      'history': [14500, 14750, 14900, 15000], // 1M data points
    },
    'Bitcoin (BTC)': {
      'value': 20000.0,
      'shares': 0.5,
      'change': 4.2,
      'history': [19000, 19500, 19800, 20000],
    },
    'Tesla (TSLA)': {
      'value': 10000.0,
      'shares': 40,
      'change': -1.5,
      'history': [10200, 10100, 10050, 10000],
    },
    'Cash': {
      'value': 5000.0,
      'shares': 5000,
      'change': 0.0,
      'history': [5000, 5000, 5000, 5000],
    },
  };

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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAssetsTab(),
          _buildPerformanceTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAssetDialog(context);
        },
        child: Icon(Icons.add),
        tooltip: 'Add Asset',
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab() {
    double totalValue = portfolioData.values
        .map((asset) => asset['value'] as double)
        .reduce((a, b) => a + b);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioHeader(totalValue),
          _buildAssetAllocationChart(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Top Holdings', style: Theme.of(context).textTheme.titleLarge),
          ),
          _buildQuickAssetList(),
        ],
      ),
    );
  }

  // Assets Tab
  Widget _buildAssetsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: portfolioData.length,
      itemBuilder: (context, index) {
        String assetName = portfolioData.keys.elementAt(index);
        Map<String, dynamic> asset = portfolioData[assetName]!;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(assetName[0]),
            ),
            title: Text(assetName),
            subtitle: Text('\$${asset['value'].toStringAsFixed(2)} • ${asset['shares']} units'),
            trailing: Text(
              '${asset['change'] > 0 ? '+' : ''}${asset['change']}%',
              style: TextStyle(
                color: asset['change'] >= 0 ? Colors.green : Colors.red,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssetDetailScreen(assetName: assetName, assetData: asset),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Performance Tab - Fixed fl_chart API usage
  Widget _buildPerformanceTab() {
    return Column(
      children: [
        _buildTimeRangeSelector(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(portfolioData.values.first['history'].length, (index) {
                      double total = 0;
                      portfolioData.values.forEach((asset) {
                        total += asset['history'][index].toDouble();
                      });
                      return FlSpot(index.toDouble(), total);
                    }),
                    isCurved: true,
                    color: Colors.blue,
                    dotData: FlDotData(show: false),
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
                        return Text('D${value.toInt()}');
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
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced Portfolio Header
  Widget _buildPortfolioHeader(double totalValue) {
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
              Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
              SizedBox(width: 4),
              Text(
                '+2.5% today',
                style: TextStyle(color: Colors.greenAccent, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced Pie Chart
  Widget _buildAssetAllocationChart() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: portfolioData.entries.map((entry) {
            double total = portfolioData.values
                .map((asset) => asset['value'] as double)
                .reduce((a, b) => a + b);
            double percentage = (entry.value['value'] / total) * 100;
            return PieChartSectionData(
              value: entry.value['value'],
              color: Colors.primaries[portfolioData.keys.toList().indexOf(entry.key) % Colors.primaries.length],
              title: '${entry.key.split(' ')[0]}\n${percentage.toStringAsFixed(1)}%',
              radius: 80,
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
        ),
      ),
    );
  }

  // Quick Asset List
  Widget _buildQuickAssetList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: portfolioData.length > 3 ? 3 : portfolioData.length,
      itemBuilder: (context, index) {
        String assetName = portfolioData.keys.elementAt(index);
        Map<String, dynamic> asset = portfolioData[assetName]!;
        return ListTile(
          title: Text(assetName),
          subtitle: Text('\$${asset['value'].toStringAsFixed(2)} • ${asset['change']}%'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssetDetailScreen(assetName: assetName, assetData: asset),
              ),
            );
          },
        );
      },
    );
  }

  // Time Range Selector
  Widget _buildTimeRangeSelector() {
    List<String> ranges = ['1D', '1W', '1M', '1Y'];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ranges.map((range) {
          return ChoiceChip(
            label: Text(range),
            selected: selectedTimeRange == range,
            selectedColor: Colors.blue.shade100,
            onSelected: (selected) {
              if (selected) {
                setState(() => selectedTimeRange = range);
                // TODO: Fetch and update chart data based on range
              }
            },
          );
        }).toList(),
      ),
    );
  }

  // Add Asset Dialog
  void _showAddAssetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Asset Name'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Value'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement asset addition logic
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

class AssetDetailScreen extends StatelessWidget {
  final String assetName;
  final Map<String, dynamic> assetData;

  const AssetDetailScreen({required this.assetName, required this.assetData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(assetName)),
      body: Center(
        child: Text('Detailed view for $assetName\nValue: \$${assetData['value']}'),
      ),
    );
  }
}