import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Glass Effect

class AuraRankCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> trades;

  const AuraRankCard({super.key, required this.trades});

  // 🔥 AURA CALCULATION LOGIC
  Map<String, dynamic> _calculateAura() {
    int aura = 1000; // Starting Aura (Base Respect)

    // Filter for TODAY only
    DateTime now = DateTime.now();
    var todaysTrades = trades.where((t) {
      var data = t.data() as Map<String, dynamic>;
      if (data['timestamp'] == null) return false;
      DateTime date = (data['timestamp'] as Timestamp).toDate();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).toList();

    for (var trade in todaysTrades) {
      var data = trade.data() as Map<String, dynamic>;
      double pnl = (data['pnl'] ?? 0.0).toDouble();
      String reason = data['reason'] ?? 'Strategy Setup';

      // ✅ GREEN FLAGS (+ AURA)
      if (reason == 'Strategy Setup') {
        aura += 200; // Following rules is Giga Chad behavior
      }
      if (pnl > 0 && reason != 'Gambling') {
        aura += 100; // Clean win
      }

      // 🚩 RED FLAGS (- AURA)
      if (reason == 'FOMO') {
        aura -= 500; // Bro, control yourself
      }
      if (reason == 'Revenge Trade') {
        aura -= 1000; // Emotional damage
      }
      if (reason == 'Gambling') {
        aura -= 800; // Casino mat banao isko
      }
    }

    // 🏆 RANK TITLES (GEN Z SLANG)
    String rankTitle = "NPC 🤖";
    Color glowColor = Colors.grey;
    String comment = "Do something.";
    String emoji = "😐";

    if (aura > 2500) {
      rankTitle = "MARKET MAKER 🏦";
      glowColor = const Color(0xFF00E676); // Neon Green
      comment = "Bro is literally printing money.";
      emoji = "🤑";
    } else if (aura > 1800) {
      rankTitle = "GIGA CHAD 🗿";
      glowColor = Colors.purpleAccent;
      comment = "Locked In. Ice in veins.";
      emoji = "🥶";
    } else if (aura > 1200) {
      rankTitle = "VALID TRADER ✅";
      glowColor = Colors.blueAccent;
      comment = "Respectable stats.";
      emoji = "🫡";
    } else if (aura < 800 && aura > 0) {
      rankTitle = "LIQUIDITY 💧";
      glowColor = Colors.orange;
      comment = "You are the target today.";
      emoji = "🤡";
    } else if (aura <= 0) {
      rankTitle = "COOKED 🍳";
      glowColor = Colors.redAccent;
      comment = "Delete the app. Go touch grass.";
      emoji = "💀";
    }

    return {
      "aura": aura,
      "rank": rankTitle,
      "color": glowColor,
      "comment": comment,
      "emoji": emoji
    };
  }

  @override
  Widget build(BuildContext context) {
    var stats = _calculateAura();
    Color themeColor = stats['color'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        children: [
          // GLOW EFFECT BEHIND
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // MAIN CARD (GLASSMORPHISM)
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CURRENT AURA", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                            const SizedBox(height: 5),
                            Text(
                              "${stats['aura']}",
                              style: TextStyle(
                                  color: themeColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace'
                              ),
                            ),
                          ],
                        ),
                        Text(
                          stats['emoji'],
                          style: const TextStyle(fontSize: 40),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // PROGRESS BAR STYLE
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (stats['aura'] / 3000).clamp(0.0, 1.0), // Max 3000
                        child: Container(
                          decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [BoxShadow(color: themeColor, blurRadius: 8)]
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stats['rank'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: themeColor, blurRadius: 10)]
                          ),
                        ),
                        Expanded(
                          child: Text(
                            stats['comment'],
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}