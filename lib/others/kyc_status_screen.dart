// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pixpie/dashboard/admin_dashboard/dashboard.dart';
//
// import '../provider/api_provider.dart';
// import 'kyc_screen.dart';
//
// class KycStatusScreen extends StatefulWidget {
//   const KycStatusScreen({super.key});
//
//   @override
//   State<KycStatusScreen> createState() => _KycStatusScreenState();
// }
//
// class _KycStatusScreenState extends State<KycStatusScreen> {
//
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _startCheckingStatus();
//     });
//   }
//
//   /// 🔄 Auto check every 5 seconds
//   void _startCheckingStatus() {
//
//     final api = context.read<ApiProvider>();
//
//     _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
//
//       await api.fetchKycStatus();
//
//       if (!mounted) return;
//
//       /// If approved → Dashboard
//       if (api.kycStatus == "APPROVED") {
//
//         _timer?.cancel();
//
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const DashboardScreen(),
//           ),
//         );
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("KYC Status")),
//
//       body: Consumer<ApiProvider>(
//         builder: (context, api, child) {
//
//           if (api.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final status = api.kycStatus ?? "PENDING";
//           final submittedAt = api.submittedAt;
//
//           IconData icon;
//           Color color;
//           String text;
//
//           /// ✅ Approved
//           if (status == "APPROVED") {
//             icon = Icons.verified;
//             color = Colors.green;
//             text = "KYC Approved";
//           }
//
//           /// ❌ Rejected
//           else if (status == "REJECTED") {
//             icon = Icons.cancel;
//             color = Colors.red;
//             text = "KYC Rejected";
//           }
//
//           /// ⏳ Under review
//           else if (status == "SUBMITTED" && submittedAt != null) {
//             icon = Icons.hourglass_top;
//             color = Colors.orange;
//             text = "KYC Under Review";
//           }
//
//           /// 🆕 Not submitted
//           else {
//             icon = Icons.info;
//             color = Colors.blue;
//             text = "KYC Not Submitted";
//           }
//
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//
//                   Icon(icon, size: 90, color: color),
//
//                   const SizedBox(height: 20),
//
//                   Text(
//                     text,
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   /// ⏳ Under review message
//                   if (status == "PENDING" && submittedAt != null)
//                     const Text(
//                       "Your KYC is being reviewed.\nPlease wait for approval.",
//                       textAlign: TextAlign.center,
//                     ),
//
//                   /// ❌ Rejected
//                   if (status == "REJECTED") ...[
//
//                     const SizedBox(height: 10),
//
//                     Text(
//                       api.rejectionReason ?? "Your KYC was rejected.",
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.red),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     ElevatedButton(
//                       onPressed: () {
//
//                         /// Navigate to KYC form again
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const KycScreen(),
//                           ),
//                         );
//
//                       },
//                       child: const Text("Submit Again"),
//                     ),
//
//                   ],
//
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }