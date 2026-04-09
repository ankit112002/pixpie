import 'package:flutter/material.dart';
import 'package:pixpie/others/profile_stat_card.dart';
import 'package:provider/provider.dart';
import '../provider/profile_provider.dart';
import 'kyc_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool pushNotification = true;
  bool locationServices = true;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    Future.microtask(() async {
      await profileProvider.fetchProfile();
      final profile = profileProvider.profile;
      _nameController = TextEditingController(text: profile?['name'] ?? '');
      _emailController = TextEditingController(text: profile?['email'] ?? '');
      _phoneController = TextEditingController(text: profile?['phone'] ?? '');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 Profile Header Card
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final profile = provider.profile;
                if (profile == null) return const Text("No profile data found");

                final name = profile["name"] ?? "";
                final email = profile["email"] ?? "";
                final role = profile["role"]?["title"] ?? "";
                final profilePhoto = profile["profile_photo"];
                final kycStatus = profile["kyc_status"] ?? "";

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _boxDecoration(),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blue,
                        backgroundImage:
                        profilePhoto != null ? NetworkImage(profilePhoto) : null,
                        child: profilePhoto == null
                            ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "U",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(role, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: () {
                          _showEditProfileDialog(context, profile);
                        },
                        child: const Text("Edit",style: TextStyle(color: Colors.white),),
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// 🔹 Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ProfileStatCard(title: "Surveys", value: "156", icon: Icons.assignment),
                ProfileStatCard(title: "Total Earnings", value: "₹12,450", icon: Icons.wallet),
                ProfileStatCard(title: "Approval Rate", value: "95%", icon: Icons.check_circle),
                ProfileStatCard(title: "Current Streak", value: "12 days", icon: Icons.local_fire_department),
              ],
            ),

            /// 🔹 KYC Verification Card
            /// 🔹 KYC Verification Card
            _sectionTitle("KYC Verification"),
            const SizedBox(height: 10),
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                final profile = provider.profile;
                final kycStatus = profile?["kyc_status"] ?? "PENDING";
                final rejectedReason = profile?["kyc_rejected_reason"];

                IconData icon;
                Color statusColor;
                String message;
                String buttonText;
                bool buttonEnabled;

                switch (kycStatus) {
                  case "APPROVED":
                    icon = Icons.verified;
                    statusColor = Colors.green;
                    message = "Your KYC is approved";
                    buttonText = "Submitted";
                    buttonEnabled = false;
                    break;
                  case "REJECTED":
                    icon = Icons.cancel;
                    statusColor = Colors.red;
                    message = rejectedReason ?? "Your KYC was rejected";
                    buttonText = "ReSubmit";
                    buttonEnabled = true; // enable for resubmit
                    break;
                  case "SUBMITTED":
                    icon = Icons.hourglass_top;
                    statusColor = Colors.orange;
                    message = "KYC under review";
                    buttonText = "Submitted";
                    buttonEnabled = false; // disable while under review
                    break;
                  default: // PENDING / Not submitted
                    icon = Icons.info;
                    statusColor = Colors.blue;
                    message = "KYC not submitted";
                    buttonText = "Submit";
                    buttonEnabled = true;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _boxDecoration(),
                  child: Row(
                    children: [
                      Icon(icon, size: 40, color: statusColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Identity Verification",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: TextStyle(color: statusColor),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: buttonEnabled
                            ? () async {
                          // Navigate to KYC screen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KycScreen()),
                          );

                          // Refresh profile after returning
                          await provider.fetchProfile();
                          setState(() {}); // rebuild to show updated KYC status
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonEnabled ? statusColor : Colors.grey,
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// 🔹 Achievements Card
            _sectionTitle("Achievements"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _boxDecoration(),
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.emoji_events, color: Colors.orange),
                    title: Text("Top Performer"),
                    subtitle: Text("Ranked #5 this month"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: Colors.blue),
                    title: Text("Quality Expert"),
                    subtitle: Text("95% photo approval rate"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),



            /// 🔹 Settings Card
            _sectionTitle("Settings"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Push Notifications"),
                    value: pushNotification,
                    onChanged: (val) {
                      setState(() {
                        pushNotification = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Location Services"),
                    value: locationServices,
                    onChanged: (val) {
                      setState(() {
                        locationServices = val;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text("Data Privacy"),
                    trailing:
                    const Text("Manage", style: TextStyle(color: Colors.blue)),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🔹 Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Sign Out",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: const Offset(0, 3),
        )
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> profile) {
    _nameController.text = profile['name'] ?? '';
    _emailController.text = profile['email'] ?? '';
    _phoneController.text = profile['phone'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            Consumer<ProfileProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                    await provider.updateProfile(
                      name: _nameController.text.trim(),
                      email: _emailController.text.trim(),
                      phone: _phoneController.text.trim(),
                    );

                    if (provider.error == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Profile updated successfully")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.error!)),
                      );
                    }
                  },
                  child: provider.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Save"),
                );
              },
            ),
          ],
        );
      },
    );
  }
}