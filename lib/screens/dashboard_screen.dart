import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

// 📦 CUSTOM WIDGETS
import '../widgets/ai_insight_card.dart';
import '../widgets/aura_card.dart';
import '../widgets/trade_receipt.dart';
import 'graveyard_screen.dart';
import 'vault_screen.dart';
import 'login_screen.dart';
import 'market_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;

  // --- 🧘‍♂️ Monk Mode State ---
  bool _isMonkMode = false;
  String _currentQuote = "Focus on the process, not the outcome.";
  final List<String> _stoicQuotes = [
    "Emotions Off. Logic On.",
    "We suffer more in imagination than reality.",
    "You have power over your mind, not outside events.",
    "The best revenge is not to be like your enemy.",
    "Don't explain your philosophy. Embody it."
  ];

  // --- 💾 Navigation State ---
  int _selectedIndex = 0;
  bool _isLoadingTab = true;

  // --- 📊 Trading State ---
  final _pairController = TextEditingController();
  final _profitController = TextEditingController();
  String _tradeType = 'Buy';
  bool _isProfit = true;
  String _selectedReason = 'Strategy Setup';
  String? _editingDocId;
  String _currentFilter = 'All';

  final List<String> _reasons = ['Strategy Setup', 'FOMO', 'Revenge Trade', 'Gambling', 'News Event', 'Mistake'];

  @override
  void initState() {
    super.initState();
    _loadLastTab();
  }

  Future<void> _loadLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('last_tab_index') ?? 0;
      _isLoadingTab = false;
    });
  }

  Future<void> _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tab_index', index);
  }

  void _toggleMonkMode() {
    setState(() {
      _isMonkMode = !_isMonkMode;
      if (_isMonkMode) _currentQuote = _stoicQuotes[Random().nextInt(_stoicQuotes.length)];
    });
  }

  Future<void> _addTrade() async {
    if (_pairController.text.isEmpty || _profitController.text.isEmpty) return;
    String cleanText = _profitController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    double value = double.tryParse(cleanText) ?? 0.0;
    if (!_isProfit) value = value * -1;

    final tradeData = {
      'pair': _pairController.text.toUpperCase(),
      'type': _tradeType,
      'pnl': value,
      'reason': _selectedReason,
      'status': 'CLOSED',
      'timestamp': FieldValue.serverTimestamp(),
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000
    };

    if (_editingDocId == null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('trades').add(tradeData);
    } else {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('trades').doc(_editingDocId).update(tradeData);
    }
    _pairController.clear();
    _profitController.clear();
    if (mounted) Navigator.pop(context);
  }

  // ====================================================
  // 🎨 ANIMATED UI HELPERS
  // ====================================================

  Widget _buildMonkText(String value, TextStyle style) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isMonkMode
          ? Text("••••••", key: const ValueKey("hidden"), style: style.copyWith(color: Colors.grey, fontFamily: 'monospace'))
          : Text(value, key: const ValueKey("visible"), style: style),
    );
  }

  Widget _buildCyberFilter(String label, Color color, IconData icon) {
    final isSelected = _currentFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.4)]) : null,
          color: isSelected ? null : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? color.withOpacity(0.6) : Colors.white10),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(label.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeItem(QueryDocumentSnapshot trade, int index) {
    final data = trade.data() as Map<String, dynamic>;
    final pnl = (data['pnl'] ?? 0.0).toDouble();
    final isProfit = pnl >= 0;
    final isRunning = data['status'] == 'OPEN';
    final reason = data['reason'] ?? 'Strategy Setup';

    Color accentColor = isRunning ? Colors.cyanAccent : (isProfit ? const Color(0xFF00E676) : const Color(0xFFFF1744));
    if (reason == 'FOMO') accentColor = Colors.orangeAccent;
    if (reason == 'Revenge Trade' || reason == 'Gambling') accentColor = Colors.purpleAccent;

    // Entrance Animation for each item
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showAddTradeForm(tradeToEdit: trade),
        onLongPress: () => showDialog(context: context, builder: (context) => TradeReceiptDialog(trade: trade)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
              boxShadow: [BoxShadow(color: accentColor.withOpacity(0.05), blurRadius: 10)]
          ),
          child: Row(
            children: [
              Container(
                  width: 4, height: 40,
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: accentColor, blurRadius: 8)])
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${data['pair']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(reason.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _buildMonkText("${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}", TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                if (isRunning) const Text("LIVE 📡", style: TextStyle(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================
  // ⚡️ MAIN VIEW BUILDER
  // ====================================================

  Widget _buildDashboardView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
        var userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        double balance = (userData['balance'] ?? 0.0).toDouble();
        double equity = (userData['equity'] ?? 0.0).toDouble();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(_isMonkMode ? "MONK MODE" : "TERMINAL", style: TextStyle(color: _isMonkMode ? Colors.amber : Colors.white, letterSpacing: 4, fontWeight: FontWeight.w900)),
            backgroundColor: Colors.transparent, elevation: 0,
            actions: [
              IconButton(onPressed: _toggleMonkMode, icon: Icon(_isMonkMode ? Icons.visibility_off : Icons.visibility, color: _isMonkMode ? Colors.amber : Colors.white54)),
              IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())), icon: const Icon(Icons.person, color: Colors.blueAccent)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTradeForm(),
            backgroundColor: const Color(0xFF00E676),
            elevation: 10,
            child: const Icon(Icons.add, color: Colors.black, size: 30),
          ),
          body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _isMonkMode ? [Colors.black, Colors.black] : [const Color(0xFF000000), const Color(0xFF0F2027)]
                )
            ),
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('trades').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, tradeSnap) {
                if (!tradeSnap.hasData) return const Center(child: CircularProgressIndicator());

                final allTrades = tradeSnap.data!.docs;
                final filteredTrades = allTrades.where((t) {
                  final d = t.data() as Map<String, dynamic>;
                  if (_currentFilter == 'All') return true;
                  if (_currentFilter == 'Running') return d['status'] == 'OPEN';
                  return d['reason'] == _currentFilter;
                }).toList();

                return SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(children: [
                          if (_isMonkMode) _buildMonkBanner(),
                          if (!_isMonkMode) ...[
                            AuraRankCard(trades: allTrades),
                            AiInsightCard(trades: allTrades),
                            _buildPortalButtons(),
                          ],
                          _buildBalanceHeader(balance, equity),
                          _buildCyberFilterRow(),
                        ]),
                      ),
                      SliverList(
                          delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildTradeItem(filteredTrades[index], index),
                              childCount: filteredTrades.length
                          )
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- SUB-WIDGETS WITH ANIMATIONS ---
  Widget _buildMonkBanner() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 1),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) => Opacity(opacity: value, child: child),
      child: Container(
        margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
        child: Column(children: [
          const Icon(Icons.self_improvement, color: Colors.amber, size: 30),
          const SizedBox(height: 10),
          Text(_currentQuote, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 14))
        ]),
      ),
    );
  }

  Widget _buildPortalButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(children: [
        _portalBtn("THE VAULT", const Color(0xFFFFD700), Icons.lock_open, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultScreen()))),
        const SizedBox(width: 15),
        _portalBtn("GRAVEYARD", Colors.redAccent, Icons.church, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GraveyardScreen()))),
      ]),
    );
  }

  Widget _portalBtn(String title, Color color, IconData icon, VoidCallback tap) {
    return Expanded(
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 55,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))
          ]),
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(double b, double e) {
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)]
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("CURRENT BALANCE", style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMonkText("\$${b.toStringAsFixed(2)}", const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("NET EQUITY", style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMonkText("\$${e.toStringAsFixed(2)}", TextStyle(color: e >= b ? const Color(0xFF00E676) : Colors.redAccent, fontSize: 26, fontWeight: FontWeight.w900))
        ]),
      ]),
    );
  }

  Widget _buildCyberFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(children: [
        _buildCyberFilter('All', Colors.white, Icons.grid_view),
        _buildCyberFilter('Running', Colors.cyanAccent, Icons.timelapse),
        _buildCyberFilter('Strategy Setup', Colors.blueAccent, Icons.psychology),
        _buildCyberFilter('FOMO', Colors.orangeAccent, Icons.warning),
        _buildCyberFilter('Revenge Trade', Colors.purpleAccent, Icons.whatshot),
      ]),
    );
  }

  void _showAddTradeForm({QueryDocumentSnapshot? tradeToEdit}) {
    if (tradeToEdit != null) {
      _editingDocId = tradeToEdit.id;
      final data = tradeToEdit.data() as Map<String, dynamic>;
      _pairController.text = data['pair'];
      double pnl = data['pnl'] is int ? (data['pnl'] as int).toDouble() : data['pnl'];
      _isProfit = pnl >= 0;
      _profitController.text = pnl.abs().toString();
      _tradeType = data['type'] ?? 'Buy';
      _selectedReason = data['reason'] ?? 'Strategy Setup';
    } else {
      _editingDocId = null; _pairController.clear(); _profitController.clear(); _isProfit = true; _tradeType = 'Buy'; _selectedReason = 'Strategy Setup';
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 30),
              decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: Colors.white10))
              ),
              child: StatefulBuilder(builder: (context, setModalState) {
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 25),
                  Text(_editingDocId == null ? "NEW TRADE ENTRY" : "EDIT TRADE INTEL", style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 30),
                  Row(children: [
                    Expanded(child: _buildTypeToggle(setModalState, true)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTypeToggle(setModalState, false)),
                  ]),
                  const SizedBox(height: 25),
                  _buildModalField(_profitController, "PROFIT/LOSS AMOUNT", Icons.attach_money),
                  const SizedBox(height: 15),
                  _buildModalField(_pairController, "TRADING PAIR (e.g. XAUUSD)", Icons.currency_bitcoin),
                  const SizedBox(height: 25),
                  ElevatedButton(
                      onPressed: _addTrade,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text(_editingDocId == null ? "CONFIRM ENTRY" : "UPDATE INTEL", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1))
                  ),
                ]);
              }),
            ),
          );
        }
    );
  }

  Widget _buildTypeToggle(void Function(void Function()) setModalState, bool profit) {
    bool selected = _isProfit == profit;
    return GestureDetector(
      onTap: () => setModalState(() => _isProfit = profit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            color: selected ? (profit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)) : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? (profit ? Colors.green : Colors.red) : Colors.transparent)
        ),
        child: Center(child: Text(profit ? "PROFIT" : "LOSS", style: TextStyle(color: profit ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildModalField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00E676), size: 20),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTab) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))));
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _selectedIndex, children: [_buildDashboardView(), const MarketScreen(), const CalendarScreen()]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10, width: 0.5))),
        child: BottomNavigationBar(
          backgroundColor: Colors.black, selectedItemColor: const Color(0xFF00E676), unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex, onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Terminal'),
            BottomNavigationBarItem(icon: Icon(Icons.candlestick_chart_outlined), activeIcon: Icon(Icons.candlestick_chart), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Journal')
          ],
        ),
      ),
    );
  }
}