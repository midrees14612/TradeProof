import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Glassmorphism
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Animation Controllers
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // --- 🔥 SECURE SIGNUP LOGIC ---
  Future<void> _signup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All identifiers required!"), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'subscriptionStatus': 'active',
        });
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Signup Failed"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Background Gradient
          _buildBackground(),

          // 2. Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // ICON WITH NEON GLOW
                    _buildAnimatedIcon(),

                    const SizedBox(height: 25),
                    const Text(
                      "NEW DEPLOYMENT",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
                    ),
                    const Text(
                      "JOIN THE ELITE TERMINAL",
                      style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2),
                    ),
                    const SizedBox(height: 40),

                    // GLASS FORM
                    _buildGlassForm(),

                    const SizedBox(height: 20),
                    _buildBackToLogin(),
                    const SizedBox(height: 40),
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
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF000000), Color(0xFF0F2027), Color(0xFF000000)],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00E676).withOpacity(0.05),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00E676).withOpacity(0.1), blurRadius: 40, spreadRadius: 5)
        ],
      ),
      child: const Icon(Icons.person_add_outlined, size: 60, color: Color(0xFF00E676)),
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildField(_nameController, "FULL NAME", Icons.person_outline),
              const SizedBox(height: 20),
              _buildField(_emailController, "EMAIL ADDRESS", Icons.alternate_email),
              const SizedBox(height: 20),
              _buildField(_passwordController, "ENCRYPTION KEY", Icons.lock_outline, isPass: true),
              const SizedBox(height: 40),

              // REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 10,
                    shadowColor: const Color(0xFF00E676).withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                      : const Text("INITIALIZE ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF00E676), size: 18),
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00E676))),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: RichText(
        text: TextSpan(
          text: "ALREADY REGISTERED? ",
          style: TextStyle(color: Colors.grey[600], fontSize: 11, letterSpacing: 1),
          children: const [
            TextSpan(text: "LOGIN HERE", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}