import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfitChart extends StatelessWidget {
  final List<QueryDocumentSnapshot> trades;

  const ProfitChart({super.key, required this.trades});

  @override
  Widget build(BuildContext context) {
    // 1. Data Process Karo (Cumulative P&L)
    List<FlSpot> spots = [];
    double currentBalance = 0;

    // Graph zero se shuru hona chahiye
    spots.add(const FlSpot(0, 0));

    // Purani trades pehle aani chahiye calculation ke liye
    // Isliye hum list ko reverse kar rahe hain kyunki dashboard mein wo descending thi
    final sortedTrades = trades.reversed.toList();

    for (int i = 0; i < sortedTrades.length; i++) {
      final pnl = sortedTrades[i]['pnl'] ?? 0.0;
      currentBalance += pnl; // Pichla balance + naya profit
      spots.add(FlSpot((i + 1).toDouble(), currentBalance));
    }

    // 2. Agar koi trade nahi hai to khali box dikhao
    if (spots.length <= 1) {
      return const SizedBox(height: 100, child: Center(child: Text("Add trades to see graph", style: TextStyle(color: Colors.grey))));
    }

    // 3. Graph Design
    return Container(
      height: 200, // Graph ki height
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Card Background
        borderRadius: BorderRadius.circular(18),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false), // Jalio (Grid) ko chupao
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Left numbers hide
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 100)), // Right side numbers
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),

          // Line Design
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true, // Smooth line
              color: const Color(0xFF00E676), // Neon Green Line
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false), // Dots hatao
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00E676).withOpacity(0.1), // Green Glow neeche
              ),
            ),
          ],
        ),
      ),
    );
  }
}