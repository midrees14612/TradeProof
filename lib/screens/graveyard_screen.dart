import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GraveyardScreen extends StatelessWidget {
  const GraveyardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Pitch Black
      appBar: AppBar(
        title: const Text("THE GRAVEYARD ⚰️", style: TextStyle(color: Colors.white70, letterSpacing: 3, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white54),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('trades')
            .where('pnl', isLessThan: 0) // Sirf Loss wali trades
            .orderBy('pnl', descending: false) // Sabse bada loss pehle
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          }

          var deaths = snapshot.data!.docs;

          if (deaths.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.green, size: 60),
                  const SizedBox(height: 20),
                  const Text("NO DEATHS YET", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("You are Immortal... for now.", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Tombstones per row
              childAspectRatio: 0.75, // Tall shape like a stone
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: deaths.length,
            itemBuilder: (context, index) {
              var data = deaths[index].data();
              return _buildTombstone(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildTombstone(Map<String, dynamic> data) {
    // Data Parsing
    String pair = data['pair'] ?? 'Unknown';
    String reason = data['reason'] ?? 'Unknown Cause';
    double loss = (data['pnl'] ?? 0.0).toDouble();

    // Date
    String dateStr = "Unknown Date";
    if (data['time'] != null) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(data['time'] * 1000);
      dateStr = DateFormat('MMM dd, yyyy').format(date);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Stone Grey
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(100), // Tombstone Curve
          topRight: Radius.circular(100),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: Colors.white10, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(5, 5))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text("R.I.P", style: TextStyle(fontFamily: 'serif', color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Icon(Icons.sentiment_very_dissatisfied, color: Colors.white24, size: 30),
          const SizedBox(height: 15),

          // Name
          Text(pair, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          // Cause of Death
          const Text("Died of:", style: TextStyle(color: Colors.grey, fontSize: 10)),
          Text(reason.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          // Loss Amount
          Text("\$${loss.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'monospace')),

          const Spacer(),
          Text(dateStr, style: TextStyle(color: Colors.grey[800], fontSize: 10)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}