import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiInsightCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> trades;

  const AiInsightCard({super.key, required this.trades});

  // 🧠 DAILY AI BRAIN (Sirf Aaj Ka Hisab + Gen Z Style)
  Map<String, dynamic> _analyzeData() {
    // 1. AAJ KI DATE NIKALO
    DateTime now = DateTime.now();

    // 2. SIRF AAJ KI TRADES FILTER KARO (Daily Reset Logic)
    List<QueryDocumentSnapshot> todaysTrades = trades.where((t) {
      var data = t.data() as Map<String, dynamic>;

      // Timestamp check
      if (data['timestamp'] == null) return false;

      DateTime tradeDate = (data['timestamp'] as Timestamp).toDate();

      // Agar saal, mahina aur din same hai, to ye aaj ki trade hai
      return tradeDate.year == now.year &&
          tradeDate.month == now.month &&
          tradeDate.day == now.day;
    }).toList();

    // --- VARIABLES FOR TODAY ---
    double totalProfit = 0;
    double totalLoss = 0;
    int wins = 0;
    int losses = 0;

    for (var trade in todaysTrades) {
      var data = trade.data() as Map<String, dynamic>;
      double pnl = (data['pnl'] ?? 0.0).toDouble();

      if (pnl >= 0) {
        totalProfit += pnl;
        wins++;
      } else {
        totalLoss += pnl.abs();
        losses++;
      }
    }

    // --- CALCULATIONS ---
    int dailyTradeCount = todaysTrades.length;
    double winRate = dailyTradeCount > 0 ? (wins / dailyTradeCount) * 100 : 0;

    // R:R Ratio Logic
    double avgWin = wins > 0 ? totalProfit / wins : 0;
    double avgLoss = losses > 0 ? totalLoss / losses : 0;
    String rrRatio = avgLoss == 0 ? "Inf" : (avgWin / avgLoss).toStringAsFixed(1);

    // --- 🤖 AI DECISION MATRIX (The Brain) ---

    // Default State (Agar aaj koi trade nahi li)
    if (dailyTradeCount == 0) {
      return {
        "score": 100,
        "title": "FRESH AURA ✨",
        "insight": "New Day. Zero Mistakes. Wait for the A+ Setup.",
        "color": Colors.blueGrey,
        "winRate": 0,
        "rrRatio": "0.0",
        "tradeCount": 0
      };
    }

    // 🛑 RULE 1: 4 LOSSES = STOP TRADING (Critical)
    if (losses >= 4) {
      return {
        "score": 0,
        "title": "YOU ARE COOKED 💀",
        "insight": "4 Losses today? Bro, the market is destroying you. Close the app NOW or you will blow the account.",
        "color": const Color(0xFFFF1744), // Deep Red
        "winRate": winRate.toInt(),
        "rrRatio": rrRatio,
        "tradeCount": dailyTradeCount
      };
    }

    // ⚠️ RULE 2: OVERTRADING (> 3 TRADES)
    if (dailyTradeCount > 3) {
      return {
        "score": 40,
        "title": "SLOW DOWN FAM ✋",
        "insight": "You took $dailyTradeCount trades. Limit is 3. You are gambling now. Walk away.",
        "color": Colors.orangeAccent,
        "winRate": winRate.toInt(),
        "rrRatio": rrRatio,
        "tradeCount": dailyTradeCount
      };
    }

    // ✅ RULE 3: WINNING DAY (Green)
    if (wins > losses) {
      return {
        "score": 95,
        "title": "GIGA CHAD 🗿",
        "insight": "Locked In. Discipline is on point. Keep printing.",
        "color": const Color(0xFF00E676), // Bright Green
        "winRate": winRate.toInt(),
        "rrRatio": rrRatio,
        "tradeCount": dailyTradeCount
      };
    }

    // 📉 RULE 4: LOSING BUT UNDER LIMIT
    return {
      "score": 60,
      "title": "DRAWDOWN 📉",
      "insight": "You are red today. Don't force a revenge trade. Relax.",
      "color": Colors.purpleAccent,
      "winRate": winRate.toInt(),
      "rrRatio": rrRatio,
      "tradeCount": dailyTradeCount
    };
  }

  @override
  Widget build(BuildContext context) {
    var data = _analyzeData();
    Color themeColor = data['color'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor.withOpacity(0.8), themeColor.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // HEADER ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24)
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DAILY AI MENTOR", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(data['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
              // Trade Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  "${data['tradeCount']}/3 Trades",
                  style: TextStyle(
                      color: (data['tradeCount'] as int) > 3 ? Colors.redAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                  ),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white12, height: 30),

          // INSIGHT TEXT
          SizedBox(
            width: double.infinity,
            child: Text(
              data['insight'],
              textAlign: TextAlign.left,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 20),

          // STATS FOOTER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat("WIN RATE", "${data['winRate']}%", Icons.pie_chart_outline),
                Container(width: 1, height: 30, color: Colors.white10),
                _buildMiniStat("R:R RATIO", "${data['rrRatio']}", Icons.balance),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        )
      ],
    );
  }
}