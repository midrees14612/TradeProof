import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Clipboard ke liye
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("MY PROFILE", style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String status = userData['subscriptionStatus'] ?? 'active';
          bool isActive = status == 'active';
          String email = user?.email ?? "No Email";
          String uid = user?.uid ?? "Unknown";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 👤 AVATAR SECTION
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),

                // 🆔 USER ID (Copyable)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: uid));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User ID Copied!"), duration: Duration(seconds: 1)));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("ID: ${uid.substring(0, 8)}...", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        const SizedBox(width: 5),
                        Icon(Icons.copy, size: 12, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 💳 SUBSCRIPTION CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? [const Color(0xFF00E676).withOpacity(0.2), Colors.transparent]
                          : [const Color(0xFFFF1744).withOpacity(0.2), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isActive ? const Color(0xFF00E676).withOpacity(0.5) : const Color(0xFFFF1744).withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MEMBERSHIP STATUS", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isActive ? "PRO TRADER" : "EXPIRED", style: TextStyle(color: isActive ? const Color(0xFF00E676) : const Color(0xFFFF1744), fontSize: 22, fontWeight: FontWeight.bold)),
                          Icon(isActive ? Icons.verified : Icons.error, color: isActive ? const Color(0xFF00E676) : const Color(0xFFFF1744)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(isActive ? "Full access to Terminal & Signals" : "Please contact admin to renew.", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ⚙️ SETTINGS LIST
                _buildSettingsTile(Icons.lock, "Change Password", () {
                  // Future: Implement Password Reset Logic
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feature coming soon!")));
                }),
                _buildSettingsTile(Icons.support_agent, "Contact Support", () {
                  // Future: Open WhatsApp
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact Admin on WhatsApp")));
                }),

                const SizedBox(height: 20),

                // 🚪 LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
    );
  }
}