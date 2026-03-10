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

    /// ✅ Token exists → Check KYC
    final apiProvider = context.read<ApiProvider>();

    await apiProvider.fetchKycStatus();

    if (!mounted) return;

    final status = apiProvider.kycStatus;
    final submittedAt = apiProvider.submittedAt;

    /// ✅ Approved
    if (status == "APPROVED") {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );

    }

    /// ⏳ Under review
    else if (status == "PENDING" && submittedAt != null) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KycStatusScreen()),
      );

    }

    /// ❌ Rejected
    else if (status == "REJECTED") {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KycStatusScreen()),
      );

    }

    /// 🆕 Not submitted
    else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KycScreen()),
      );

    }
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