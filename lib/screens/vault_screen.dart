import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // ✨ Rich Dark Green/Gold Background
      backgroundColor: const Color(0xFF05100A),
      appBar: AppBar(
        title: const Text("THE VAULT 🏦", style: TextStyle(color: Color(0xFFFFD700), letterSpacing: 3, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('trades')
            .where('pnl', isGreaterThanOrEqualTo: 0) // Sirf Wins
            .orderBy('pnl', descending: true) // Sabse bada profit pehle
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          var wins = snapshot.data!.docs;

          if (wins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.grey, size: 60),
                  const SizedBox(height: 20),
                  const Text("VAULT IS EMPTY", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Start printing money to fill this up.", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: wins.length,
            itemBuilder: (context, index) {
              var data = wins[index].data();
              return _buildGoldBar(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildGoldBar(Map<String, dynamic> data) {
    String pair = data['pair'] ?? 'Unknown';
    double profit = (data['pnl'] ?? 0.0).toDouble();

    String dateStr = "Unknown Date";
    if (data['time'] != null) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(data['time'] * 1000);
      dateStr = DateFormat('MMM dd, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 80,
      decoration: BoxDecoration(
        // 🌟 Gold Gradient Effect
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)], // Gold to Dark Gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Left Side (Icon)
          Container(
            width: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
            ),
            child: const Center(child: Icon(Icons.emoji_events, color: Colors.white, size: 30)),
          ),

          // Middle (Details)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pair, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(dateStr, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Right (Amount)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              "+\$${profit.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}