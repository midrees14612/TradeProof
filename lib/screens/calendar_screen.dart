import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("INTEL JOURNAL", style: TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF0F2027)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('trades')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
            }

            // --- DATA PROCESSING ---
            Map<DateTime, double> dailyPnL = {};
            double monthlyProfit = 0;
            double monthlyLoss = 0;

            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['time'] == null) continue;

              DateTime date = DateTime.fromMillisecondsSinceEpoch(data['time'] * 1000);
              DateTime normalizedDate = _normalizeDate(date);
              double pnl = (data['pnl'] ?? 0.0).toDouble();

              if (date.month == _focusedDay.month && date.year == _focusedDay.year) {
                if (pnl >= 0) monthlyProfit += pnl; else monthlyLoss += pnl;
              }

              dailyPnL[normalizedDate] = (dailyPnL[normalizedDate] ?? 0.0) + pnl;
            }
            double netPnL = monthlyProfit + monthlyLoss;

            return Column(
              children: [
                // 📊 ADVANCED SUMMARY STRIP (Animated)
                _buildAnimatedSummary(netPnL, monthlyProfit, monthlyLoss),

                // 📅 CYBER CALENDAR
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      rowHeight: 65, // Thoda bada cell for data

                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
                        leftChevronIcon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF00E676), size: 18),
                        rightChevronIcon: Icon(Icons.arrow_forward_ios, color: Color(0xFF00E676), size: 18),
                      ),

                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                        weekendStyle: TextStyle(color: Colors.white24, fontSize: 12),
                      ),

                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, dailyPnL),
                        todayBuilder: (context, day, focusedDay) => _buildDayCell(day, dailyPnL, isToday: true),
                        outsideBuilder: (context, day, focusedDay) => const SizedBox(), // Clean look
                      ),

                      onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedSummary(double net, double wins, double losses) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem("NET P&L", "\$${net.toInt()}", net >= 0 ? const Color(0xFF00E676) : Colors.redAccent),
              _buildSummaryItem("WINS", "\$${wins.toInt()}", const Color(0xFF00E676)),
              _buildSummaryItem("LOSSES", "\$${losses.abs().toInt()}", Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, Map<DateTime, double> dailyPnL, {bool isToday = false}) {
    DateTime normalizedDay = _normalizeDate(day);
    bool hasTrade = dailyPnL.containsKey(normalizedDay);
    double pnl = hasTrade ? dailyPnL[normalizedDay]! : 0.0;
    bool isProfit = pnl >= 0;

    // --- CYBER COLORS ---
    Color accentColor = isProfit ? const Color(0xFF00E676) : Colors.redAccent;
    if (!hasTrade) accentColor = Colors.white24;
    if (isToday && !hasTrade) accentColor = Colors.blueAccent;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      builder: (context, double value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: hasTrade ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTrade || isToday ? accentColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
            width: hasTrade || isToday ? 1.5 : 1,
          ),
          boxShadow: hasTrade ? [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 8)] : [],
        ),
        child: Stack(
          children: [
            // Date Number
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday ? Colors.blueAccent : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            // PnL Value
            if (hasTrade)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: FittedBox(
                    child: Text(
                      "${pnl >= 0 ? '+' : '-'}${pnl.abs().toInt()}",
                      style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          fontFamily: 'monospace'
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }
}