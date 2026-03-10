import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dashboard/admin_dashboard/dashboard.dart';
import '../provider/api_provider.dart';
import 'kyc_screen.dart';
import 'kyc_status_screen.dart';

class KycRouterScreen extends StatefulWidget {
  const KycRouterScreen({super.key});

  @override
  State<KycRouterScreen> createState() => _KycRouterScreenState();
}

class _KycRouterScreenState extends State<KycRouterScreen> {

  @override
  void initState() {
    super.initState();
    checkKyc();
  }

  Future<void> checkKyc() async {

    final api = context.read<ApiProvider>();

    await api.fetchKycStatus();

    if (!mounted) return;

    final status = api.kycStatus;
    final submittedAt = api.submittedAt;

    /// ✅ KYC Approved
    if (status == "APPROVED") {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );

    }

    /// ⏳ KYC Submitted → Under Review
    else if (status == "PENDING" && submittedAt != null) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KycStatusScreen()),
      );

    }

    /// ❌ KYC Rejected
    else if (status == "REJECTED") {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KycStatusScreen()),
      );

    }

    /// 🆕 KYC Not Submitted
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
        child: CircularProgressIndicator(),
      ),
    );
  }
}