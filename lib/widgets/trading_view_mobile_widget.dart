import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class TradingViewMobileWidget extends StatefulWidget {
  final String symbol;
  final bool isStockChart;
  final double height;
  final Map<String, dynamic>? chartData;
  final Map<String, dynamic>? liveData;
  final bool useMockData;

  const TradingViewMobileWidget({
    Key? key,
    required this.symbol,
    this.isStockChart = true,
    this.height = 300,
    this.chartData,
    this.liveData,
    this.useMockData = false,
  }) : super(key: key);

  @override
  _TradingViewMobileWidgetState createState() => _TradingViewMobileWidgetState();
}

class _TradingViewMobileWidgetState extends State<TradingViewMobileWidget> {
  List<FlSpot> _chartPoints = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _createChartPoints();
  }
  
  @override
  void didUpdateWidget(TradingViewMobileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || 
        oldWidget.isStockChart != widget.isStockChart || 
        oldWidget.liveData != widget.liveData) {
      _createChartPoints();
    }
  }
  
  void _createChartPoints() {
    // Create some sample data points for chart
    final baseValue = widget.symbol.contains('BTC') ? 29000.0 : 
                     widget.symbol.contains('ETH') ? 1800.0 :
                     widget.symbol.contains('AAPL') ? 150.0 :
                     widget.symbol.contains('GOOGL') ? 2800.0 :
                     widget.symbol.contains('MSFT') ? 350.0 : 100.0;
    
    try {
      // Generate at least 20 points for a better-looking chart
      _chartPoints = List.generate(20, (i) {
        final noise = math.Random().nextDouble() * 0.1 - 0.05; // Random value between -0.05 and 0.05
        return FlSpot(
          i.toDouble(), 
          baseValue * (1 + 0.02 * i / 20) + baseValue * noise
        );
      });
    } catch (e) {
      print('Error generating chart points: $e');
      // Fallback to minimal set of points in case of error
      _chartPoints = [
        FlSpot(0, baseValue),
        FlSpot(1, baseValue * 1.01),
        FlSpot(2, baseValue * 1.02),
        FlSpot(3, baseValue * 1.03),
      ];
    }
    
    // Safety check: ensure we have at least 2 points for min/max calculations
    if (_chartPoints.length < 2) {
      _chartPoints = [
        FlSpot(0, baseValue),
        FlSpot(1, baseValue * 1.01),
      ];
    }
  }

  Future<void> _openTradingViewApp() async {
    String tvSymbol;
    
    if (widget.isStockChart) {
      tvSymbol = widget.symbol;
    } else {
      // For crypto, add USDT if it's not already there
      String cryptoSymbol = widget.symbol;
      if (!cryptoSymbol.toUpperCase().contains('USDT')) {
        cryptoSymbol = '${cryptoSymbol.toUpperCase()}USDT';
      }
      tvSymbol = cryptoSymbol;
    }
    
    // Create app deep link for TradingView
    final appUri = Uri.parse('tradingview://chart/$tvSymbol');
    
    // Create web fallback URL
    final webUrl = widget.isStockChart
        ? 'https://www.tradingview.com/chart/?symbol=$tvSymbol'
        : 'https://www.tradingview.com/chart/?symbol=BINANCE:$tvSymbol';
    
    final webUri = Uri.parse(webUrl);
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Try to launch the TradingView app first
      final canLaunchApp = await canLaunchUrl(appUri);
      
      if (canLaunchApp) {
        await launchUrl(appUri);
      } else {
        // If app is not installed, open in web browser
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open TradingView: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate min/max Y values safely
    double minY, maxY;
    if (_chartPoints.isEmpty) {
      minY = 0;
      maxY = 100;
    } else {
      minY = _chartPoints.map((p) => p.y).reduce(math.min) * 0.95;
      maxY = _chartPoints.map((p) => p.y).reduce(math.max) * 1.05;
    }
    
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          // Preview chart with open button
          Expanded(
            child: Stack(
              children: [
                // Chart preview
                LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    minX: 0,
                    maxX: (_chartPoints.length - 1).toDouble().clamp(1, double.infinity),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartPoints,
                        isCurved: true,
                        color: _getChartColor(),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _getChartColor().withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Overlay for interaction
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openTradingViewApp,
                      child: Container(
                        alignment: Alignment.center,
                        child: widget.useMockData 
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Using demo data',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.open_in_new,
                              size: 48,
                              color: Colors.white.withOpacity(0.7),
                            ),
                      ),
                    ),
                  ),
                ),
                
                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          
          // Button to open TradingView
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _openTradingViewApp,
              icon: Icon(Icons.candlestick_chart),
              label: Text('Open in TradingView'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getChartColor() {
    // Determine if chart should show positive (green) or negative (red) trend
    if (_chartPoints.length >= 2) {
      final startY = _chartPoints.first.y;
      final endY = _chartPoints.last.y;
      return endY >= startY ? Colors.green : Colors.red;
    }
    return Colors.blue;
  }
} 