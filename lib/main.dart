import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart'; // User Dashboard
import 'screens/admin_screen.dart';     // Admin Panel

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TradeProof',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00E676)),
      ),
      home: const AuthWrapper(), // 🔥 Logic Yahan Hai
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Agar User Logged Out hai -> Login Screen
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 2. Agar User Logged In hai -> Role Check karo
        User? user = snapshot.data;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
          builder: (context, userSnapshot) {

            // Jab tak data aa raha hai, Loading dikhao
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
              );
            }

            // Data Check
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              var userData = userSnapshot.data!.data() as Map<String, dynamic>;
              String role = userData['role'] ?? 'user'; // Default user
              String status = userData['subscriptionStatus'] ?? 'active';

              // 🛑 BLOCK CHECK: Agar User blocked hai to logout kar do
              if (role == 'user' && status == 'blocked') {
                FirebaseAuth.instance.signOut();
                return const LoginScreen(); // Ya Blocked Screen dikha sakte ho
              }

              // ✅ ADMIN ROUTING
              if (role == 'admin') {
                return const AdminScreen(); // 🔥 Admin Panel
              }

              // ✅ USER ROUTING
              else {
                return const DashboardScreen(); // 🔥 User Terminal/Market/Journal
              }
            }

            // Fallback (Agar user DB mai nahi mila)
            return const DashboardScreen();
          },
        );
      },
    );
  }
}