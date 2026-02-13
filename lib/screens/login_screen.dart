import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Glassmorphism ke liye
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Pulse animation controller for logo
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  // --- 🔥 LOGIN LOGIC (Same as yours, but clean) ---
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;
      if (user != null && mounted) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await FirebaseAuth.instance.signOut();
          _showError("Account not found!");
          return;
        }
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data['subscriptionStatus'] == 'blocked') {
          await FirebaseAuth.instance.signOut();
          _showBlockedDialog();
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => data['role'] == 'admin' ? const AdminScreen() : const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login Failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("ACCESS DENIED 🔒", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("Your account is blocked. Contact Admin.", style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Gradient & Circles
          _buildBackground(),

          // 2. Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // --- LOGO PULSE ---
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.1).animate(_logoController),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E676).withOpacity(0.1),
                          boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
                        ),
                        child: const Icon(Icons.shield_outlined, size: 80, color: Color(0xFF00E676)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- TITLE ANIMATION ---
                    const Text(
                      "TERMINAL LOGIN",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
                    ),
                    const SizedBox(height: 8),
                    Text("SECURE SYSTEM ACCESS", style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 2)),
                    const SizedBox(height: 50),

                    // --- GLASS CARD ---
                    _buildGlassForm(),

                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                      child: RichText(
                        text: TextSpan(
                          text: "New operative? ",
                          style: TextStyle(color: Colors.grey[600]),
                          children: const [TextSpan(text: "CREATE ACCOUNT", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF000000), Color(0xFF0F2027), Color(0xFF000000)],
        ),
      ),
    );
  }

  Widget _buildGlassForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildTextField(_emailController, "IDENTIFIER (EMAIL)", Icons.alternate_email, false),
              const SizedBox(height: 20),
              _buildTextField(_passwordController, "ACCESS CODE", Icons.lock_open_rounded, true),
              const SizedBox(height: 40),

              // --- NEON BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 15,
                    shadowColor: const Color(0xFF00E676).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                      : const Text("INITIALIZE LOGIN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPass) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white, letterSpacing: 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 2),
        prefixIcon: Icon(icon, color: const Color(0xFF00E676), size: 20),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00E676))),
      ),
    );
  }
}