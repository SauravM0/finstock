import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class TradingViewWidget extends StatefulWidget {
  final String symbol;
  final String interval;
  final String theme;
  final bool isStockChart;
  final double height;

  const TradingViewWidget({
    Key? key,
    required this.symbol,
    this.interval = '1D',
    this.theme = 'light',
    this.isStockChart = true,
    this.height = 400,
  }) : super(key: key);

  @override
  State<TradingViewWidget> createState() => _TradingViewWidgetState();
}

class _TradingViewWidgetState extends State<TradingViewWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_generateTradingViewWidget());
  }

  String _generateTradingViewWidget() {
    // Determine the widget type based on isStockChart
    final String widgetType = widget.isStockChart ? 'symbol' : 'crypto-currency-market';
    final String symbolPrefix = widget.isStockChart ? '' : 'BINANCE:';

    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { margin: 0; }
            .tradingview-widget-container { height: 100%; }
          </style>
        </head>
        <body>
          <div class="tradingview-widget-container">
            <div id="tradingview_widget"></div>
            <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
            <script type="text/javascript">
              new TradingView.widget({
                "width": "100%",
                "height": "100%",
                "symbol": "$symbolPrefix${widget.symbol}",
                "interval": "${widget.interval}",
                "timezone": "exchange",
                "theme": "${widget.theme}",
                "style": "1",
                "toolbar_bg": "#f1f3f6",
                "enable_publishing": false,
                "allow_symbol_change": true,
                "container_id": "tradingview_widget",
                "hide_top_toolbar": false,
                "hide_legend": false,
                "save_image": false,
                "studies": [
                  "MASimple@tv-basicstudies",
                  "RSI@tv-basicstudies",
                  "MACD@tv-basicstudies"
                ],
                "show_popup_button": true,
                "popup_width": "1000",
                "popup_height": "650",
                "locale": "en"
              });
            </script>
          </div>
        </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
} 