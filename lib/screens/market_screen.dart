import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  late TabController _tabController;

  String currentPair = "XAUUSD";
  List<String> selectedStudies = [];

  final List<String> allPairs = ["XAUUSD", "EURUSD", "GBPUSD", "USDJPY", "USDCAD", "BTCUSD", "ETHUSD", "SOLUSD", "US30", "SPX500", "NAS100"];

  final Map<String, String> availableIndicators = {
    "RSI": "RSI@tv-basicstudies",
    "MACD": "MACD@tv-basicstudies",
    "EMA 50": "Moving Average Exponential@tv-basicstudies",
    "Bollinger Bands": "BB@tv-basicstudies",
    "Stochastic": "StochasticRSI@tv-basicstudies",
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initController();
    _loadSavedSettings();
  }

  void _initController() {
    _controller = WebViewController();

    // 🔥 PLATFORM ERROR FIX: Web par ye functions nahi chaltay
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.setBackgroundColor(const Color(0xFF000000));
    }

    _loadChart();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPair = prefs.getString('saved_pair');
    List<String>? savedIndicators = prefs.getStringList('saved_indicators');

    if (savedPair != null || savedIndicators != null) {
      if (mounted) {
        setState(() {
          if (savedPair != null) currentPair = savedPair;
          if (savedIndicators != null) selectedStudies = savedIndicators;
        });
        _loadChart();
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_pair', currentPair);
    await prefs.setStringList('saved_indicators', selectedStudies);
  }

  void _loadChart() {
    String symbol = currentPair;
    String studiesArray = selectedStudies.map((e) => '"$e"').join(',');

    String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>body, html { margin: 0; padding: 0; height: 100%; background-color: #000000; }</style>
      </head>
      <body>
        <div id="tradingview_widget" style="height:100vh;width:100vw"></div>
        <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
        <script type="text/javascript">
          new TradingView.widget({
            "autosize": true,
            "symbol": "$symbol",
            "interval": "D",
            "timezone": "Etc/UTC",
            "theme": "dark",
            "style": "1",
            "locale": "en",
            "enable_publishing": false,
            "hide_top_toolbar": false,
            "hide_side_toolbar": false,
            "allow_symbol_change": true,
            "container_id": "tradingview_widget",
            "studies": [$studiesArray]
          });
        </script>
      </body>
      </html>
    ''';
    _controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: _buildSearchBox(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "LIVE CHART"),
            Tab(text: "INDICATORS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildChartContainer(),
          _buildIndicatorList(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (textValue) => textValue.text.isEmpty
            ? []
            : allPairs.where((p) => p.contains(textValue.text.toUpperCase())),
        onSelected: (selection) {
          setState(() => currentPair = selection);
          _saveSettings();
          _loadChart();
          FocusScope.of(context).unfocus();
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          if (controller.text.isEmpty) controller.text = currentPair;
          return TextField(
            controller: controller, focusNode: focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: Color(0xFF00E676), size: 20),
              border: InputBorder.none,
              hintText: "Search Asset...",
              hintStyle: TextStyle(color: Colors.white24),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartContainer() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) => Opacity(opacity: value, child: child),
      child: WebViewWidget(controller: _controller),
    );
  }

  Widget _buildIndicatorList() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF0F2027)],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: availableIndicators.length,
        itemBuilder: (context, index) {
          String key = availableIndicators.keys.elementAt(index);
          String value = availableIndicators.values.elementAt(index);
          bool isSelected = selectedStudies.contains(value);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00E676).withOpacity(0.05) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? const Color(0xFF00E676).withOpacity(0.5) : Colors.white10),
            ),
            child: CheckboxListTile(
              activeColor: const Color(0xFF00E676),
              checkColor: Colors.black,
              title: Text(key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(isSelected ? "SYSTEM ACTIVE" : "OFFLINE", style: TextStyle(color: isSelected ? const Color(0xFF00E676) : Colors.white24, fontSize: 10, letterSpacing: 1)),
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  val! ? selectedStudies.add(value) : selectedStudies.remove(value);
                });
                _saveSettings();
                _loadChart();
              },
            ),
          );
        },
      ),
    );
  }
}