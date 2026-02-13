import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // For Glass effect if needed

class TradeReceiptDialog extends StatelessWidget {
  final QueryDocumentSnapshot trade;

  const TradeReceiptDialog({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    var data = trade.data() as Map<String, dynamic>;

    // Data Parsing
    String pair = data['pair'] ?? 'UNKNOWN';
    String type = data['type'] ?? 'BUY';
    double pnl = (data['pnl'] ?? 0.0).toDouble();
    String reason = data['reason'] ?? 'Execution';
    double entry = (data['entry'] ?? 0.0).toDouble();
    double current = (data['current'] ?? 0.0).toDouble(); // Using current as exit price

    // Date Formatting
    DateTime date = DateTime.now();
    if (data['time'] != null) {
      date = DateTime.fromMillisecondsSinceEpoch(data['time'] * 1000);
    }
    String dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    // 🔥 Dynamic Theme Colors (Crypto Style)
    bool isProfit = pnl >= 0;
    Color themeColor = isProfit ? const Color(0xFF00E676) : const Color(0xFFFF1744); // Neon Green vs Electric Red
    Color bgGradientStart = isProfit ? const Color(0xFF0A2F1F) : const Color(0xFF2F0A0A); // Subtle colored dark BG
    Color bgGradientEnd = const Color(0xFF0D0D0D); // Deep Black

    String statusEmoji = isProfit ? "🤑" : "💀";
    String statusText = isProfit ? "PRINTED" : "COOKED";

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          // Modern Dark Gradient Background
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
          borderRadius: BorderRadius.circular(24),
          // Glowing Border Effect based on PnL
          border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, color: themeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "TRANSACTION DETAILS",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- HERO SECTION (ASSET & PNL) ---
              Text(
                "$pair ($type)",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              // Big PnL Number
              Text(
                "${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}",
                style: TextStyle(
                  color: themeColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              // Status Badge
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$statusText $statusEmoji",
                  style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),

              const SizedBox(height: 30),

              // --- DETAILS CONTAINER ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildCryptoDetailRow("Entry Price", "\$${entry.toStringAsFixed(2)}"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildCryptoDetailRow("Exit Price", "\$${current.toStringAsFixed(2)}"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildCryptoDetailRow("Time", dateStr),
                    const Divider(color: Colors.white10, height: 20),
                    _buildCryptoDetailRow("Strategy", reason, isHighlight: reason != 'Strategy Setup'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Footer
              Text(
                "DIGITAL ASSET RECEIPT • NON-FUNGIBLE FLEX",
                style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for clean rows
  Widget _buildCryptoDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? Colors.orangeAccent : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}