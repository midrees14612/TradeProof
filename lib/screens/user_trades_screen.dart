import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserTradesScreen extends StatelessWidget {
  final String uid;
  final String email;

  const UserTradesScreen({super.key, required this.uid, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("INVESTIGATE USER", style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.grey)),
            Text(email, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // 1. USER STATS CARD (Balance Check)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              var data = snapshot.data!.data() as Map<String, dynamic>?;
              double balance = data?['balance'] ?? 0.0;
              double equity = data?['equity'] ?? 0.0;
              String status = data?['subscriptionStatus'] ?? 'active';

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("CURRENT BALANCE", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text("\$${balance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text("ACCOUNT STATUS", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text(status.toUpperCase(), style: TextStyle(color: status == 'blocked' ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                    ]),
                  ],
                ),
              );
            },
          ),

          const Divider(color: Colors.white10),

          // 2. TRADES LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('trades')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Trades Found", style: TextStyle(color: Colors.grey)));
                }

                final trades = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    final data = trades[index].data() as Map<String, dynamic>;
                    final pnl = data['pnl'] ?? 0.0;
                    final isProfit = pnl >= 0;
                    final reason = data['reason'] ?? 'Unknown';

                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          isProfit ? Icons.arrow_outward : Icons.arrow_downward,
                          color: isProfit ? Colors.green : Colors.red,
                        ),
                        title: Text(data['pair'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(reason, style: TextStyle(color: _getReasonColor(reason))),
                        trailing: Text(
                          "\$${pnl.toString()}",
                          style: TextStyle(color: isProfit ? Colors.green : Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Colors
  Color _getReasonColor(String reason) {
    if (reason == 'Gambling') return Colors.pinkAccent;
    if (reason == 'Revenge Trade') return Colors.purpleAccent;
    if (reason == 'Strategy Setup') return Colors.blueAccent;
    return Colors.grey;
  }
}