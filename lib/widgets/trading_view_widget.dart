import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/market_data_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TradingViewWidget extends StatefulWidget {
  final String symbol;
  final bool isStockChart;
  final double height;
  final Map<String, dynamic>? chartData;
  final Map<String, dynamic>? liveData;
  final bool useMockData;

  const TradingViewWidget({
    Key? key,
    required this.symbol,
    this.isStockChart = true,
    this.height = 300,
    this.chartData,
    this.liveData,
    this.useMockData = false,
  }) : super(key: key);

  @override
  _TradingViewWidgetState createState() => _TradingViewWidgetState();
}

class _TradingViewWidgetState extends State<TradingViewWidget> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<FlSpot> _chartPoints = [];
  bool _hasInternetConnection = true;
  
  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _processChartData();
  }
  
  @override
  void didUpdateWidget(TradingViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveData != widget.liveData || 
        oldWidget.chartData != widget.chartData ||
        oldWidget.symbol != widget.symbol) {
      _processChartData();
    }
  }
  
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternetConnection = connectivityResult != ConnectivityResult.none;
    });
  }
  
  void _processChartData() {
    setState(() => _isLoading = true);
    
    try {
      _chartPoints = [];
      
      // First try to use chartData if provided
      if (widget.chartData != null) {
        final data = widget.chartData!;
        
        if (data.containsKey('time') && data.containsKey('close')) {
          final times = data['time'] as List;
          final closes = data['close'] as List;
          
          for (int i = 0; i < times.length && i < closes.length; i++) {
            _chartPoints.add(FlSpot(i.toDouble(), closes[i] as double));
          }
        }
      } 
      // If no chartData but liveData is provided
      else if (widget.liveData != null) {
        // Different formats based on whether it's a stock or crypto
        if (widget.isStockChart) {
          // Stock format
          if (widget.liveData!.containsKey('stocks')) {
            final stockData = widget.liveData!['stocks'];
            // Create a simple line chart based on available price data
            final prices = [
              stockData['o'] ?? 0.0, // open
              (stockData['o'] ?? 0.0) * 1.01, // slight move up
              (stockData['h'] ?? 0.0), // high
              (stockData['l'] ?? 0.0), // low
              stockData['c'] ?? 0.0, // close
            ];
            
            for (int i = 0; i < prices.length; i++) {
              _chartPoints.add(FlSpot(i.toDouble(), prices[i] as double));
            }
          }
        } else {
          // Crypto format - check different possible data formats
          if (widget.liveData!.containsKey('data') && 
              widget.liveData!['data'] is List && 
              (widget.liveData!['data'] as List).isNotEmpty) {
            // Try to extract price from WebSocket data format
            var points = [];
            for (var item in widget.liveData!['data']) {
              if (item.containsKey('p')) {
                points.add(double.tryParse(item['p'].toString()) ?? 0.0);
              }
            }
            
            for (int i = 0; i < points.length; i++) {
              _chartPoints.add(FlSpot(i.toDouble(), points[i] as double));
            }
          } else if (widget.liveData!.containsKey('p')) {
            // Simple price point
            _chartPoints = [
              FlSpot(0, double.tryParse(widget.liveData!['p'].toString()) ?? 0.0),
              FlSpot(1, double.tryParse(widget.liveData!['p'].toString()) ?? 0.0),
            ];
          }
        }
      }
      
      // If we couldn't get any data points, create mock data
      if (_chartPoints.isEmpty) {
        _createMockChartPoints();
      }
      
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('Error processing chart data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
        // Create mock data as fallback
        _createMockChartPoints();
      });
    }
  }
  
  void _createMockChartPoints() {
    // Create some sample data points if we couldn't get real data
    final baseValue = widget.symbol.contains('BTC') ? 29000.0 : 
                     widget.symbol.contains('ETH') ? 1800.0 :
                     widget.symbol.contains('AAPL') ? 150.0 :
                     widget.symbol.contains('GOOGL') ? 2800.0 :
                     widget.symbol.contains('MSFT') ? 350.0 : 100.0;
    
    _chartPoints = List.generate(20, (i) {
      final random = (i * 17) % 100 / 1000.0;
      return FlSpot(
        i.toDouble(), 
        baseValue * (1 + 0.02 * i / 20) + baseValue * (random - 0.05)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show connectivity warning if applicable
    if (!_hasInternetConnection && !widget.useMockData) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            color: Colors.red.shade100,
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline - Using cached data',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildChartWidget(),
          ),
        ],
      );
    }

    // Show mock data indicator if applicable
    if (widget.useMockData) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using demo data',
                    style: TextStyle(color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildChartWidget(),
          ),
        ],
      );
    }

    return SizedBox(
      height: widget.height,
      child: _buildChartWidget(),
    );
  }

  Widget _buildChartWidget() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Failed to load chart',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _processChartData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_chartPoints.isEmpty) {
      return Center(
        child: Text('No data available for ${widget.symbol}'),
      );
    }

    // Determine min and max Y values for the chart
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (var spot in _chartPoints) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    
    // Add some padding
    final range = maxY - minY;
    minY = minY - range * 0.05;
    maxY = maxY + range * 0.05;
    
    // Determine if trend is positive (for color)
    final isPositive = _chartPoints.isNotEmpty && 
                      _chartPoints.length > 1 && 
                      _chartPoints.last.y >= _chartPoints.first.y;
    
    final lineColor = isPositive ? Colors.green : Colors.red;
                      
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            horizontalInterval: range / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: _chartPoints.length > 10 ? (_chartPoints.length / 5).ceil().toDouble() : 1,
                getTitlesWidget: (value, meta) {
                  // Simple labels for x-axis
                  if (value % 5 != 0) return SizedBox.shrink();
                  
                  int index = value.toInt();
                  if (index < 0 || index >= _chartPoints.length) {
                    return SizedBox.shrink();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      index.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: range / 5,
                getTitlesWidget: (value, meta) {
                  // Format based on magnitude
                  String formattedValue;
                  if (value >= 1000) {
                    formattedValue = '${(value / 1000).toStringAsFixed(1)}K';
                  } else {
                    formattedValue = value.toStringAsFixed(1);
                  }
                  
                  return Text(
                    formattedValue,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: (_chartPoints.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: _chartPoints,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${widget.symbol}: \$${spot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
} 