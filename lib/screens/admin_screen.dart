import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'user_trades_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // --- LOGIC METHODS ---
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  Future<void> _deleteUser(BuildContext context, String uid, String email) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("TERMINATE USER", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
        content: Text("Are you sure you want to delete $email? This action is permanent.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(c, true),
              child: const Text("DELETE", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    }
  }

  Future<void> _toggleBlockStatus(BuildContext context, String uid, bool isBlocked) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'subscriptionStatus': isBlocked ? 'active' : 'blocked'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("COMMAND CENTER", style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.5),
        flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
            icon: const Icon(Icons.terminal, color: Color(0xFF00E676)),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF000000)],
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            final users = snapshot.data!.docs;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 120)),

                // 📊 ANIMATED STATS HEADER
                SliverToBoxAdapter(
                  child: _buildAnimatedHeader(users.length),
                ),

                // 👥 ANIMATED USER LIST
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final userData = users[index].data();
                      final uid = users[index].id;
                      final email = userData['email'] ?? 'Unknown';
                      final status = userData['subscriptionStatus'] ?? 'active';
                      final isBlocked = status == 'blocked';
                      final role = userData['role'] ?? 'user';

                      return _buildAnimatedUserCard(context, uid, email, role, isBlocked, index);
                    },
                    childCount: users.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- UI WIDGETS WITH ANIMATIONS ---

  Widget _buildAnimatedHeader(int totalUsers) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.05), blurRadius: 20)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem("TOTAL NODES", totalUsers.toString(), Colors.blueAccent),
            Container(width: 1, height: 40, color: Colors.white10),
            _statItem("SYSTEM STATUS", "SECURE", const Color(0xFF00E676)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)])),
      ],
    );
  }

  Widget _buildAnimatedUserCard(BuildContext context, String uid, String email, String role, bool isBlocked, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(value * 0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildUserCard(context, uid, email, role, isBlocked),
    );
  }

  Widget _buildUserCard(BuildContext context, String uid, String email, String role, bool isBlocked) {
    Color statusColor = isBlocked ? Colors.redAccent : const Color(0xFF00E676);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: isBlocked ? Colors.redAccent.withOpacity(0.02) : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isBlocked ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
          boxShadow: [
            if (isBlocked) BoxShadow(color: Colors.redAccent.withOpacity(0.05), blurRadius: 10)
          ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(role == 'admin' ? Icons.shield_rounded : Icons.person_rounded, color: statusColor, size: 24),
          ),
          title: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                _buildStatusDot(statusColor),
                const SizedBox(width: 8),
                Text(
                    isBlocked ? "ACCESS REVOKED" : "ACTIVE OPERATIVE",
                    style: TextStyle(color: statusColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(Icons.analytics_outlined, Colors.blueAccent, "Intel", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserTradesScreen(uid: uid, email: email)));
              }),
              _actionBtn(isBlocked ? Icons.lock_open_rounded : Icons.block_flipped, isBlocked ? Colors.greenAccent : Colors.orangeAccent, "Security", () {
                _toggleBlockStatus(context, uid, isBlocked);
              }),
              _actionBtn(Icons.delete_forever_rounded, Colors.redAccent, "Purge", () {
                _deleteUser(context, uid, email);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 4, spreadRadius: 1)]
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, String tooltip, VoidCallback tap) {
    return IconButton(
      onPressed: tap,
      icon: Icon(icon, color: color.withOpacity(0.7), size: 22),
      tooltip: tooltip,
      splashRadius: 25,
      visualDensity: VisualDensity.compact,
    );
  }
}