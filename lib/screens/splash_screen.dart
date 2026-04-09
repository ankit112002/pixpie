import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixpie/dashboard/admin_dashboard/dashboard.dart';
import 'package:pixpie/screens/admin_login.dart';

import '../app_preferences.dart';
import '../others/kyc_screen.dart';
import '../others/kyc_status_screen.dart';
import '../provider/api_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }
  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = await AppPreferences.getToken();

    if (!mounted) return;

    /// ❌ No token → Login
    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLogin()),
      );
      return;
    }

    /// ✅ Token exists → Navigate directly to Dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Pixpie",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}