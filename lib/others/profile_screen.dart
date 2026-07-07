import 'package:PixPe/others/profile_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/profile_provider.dart';
import 'kyc_screen.dart';

/// Same palette used across the app (dashboard, drawer, profile, etc.) so
/// every screen reads as one cohesive, professional design system.
class _Palette {
  static const primary = Color(0xFF4B2FBF);
  static const primaryDark = Color(0xFF37217F);
  static const background = Color(0xFFF5F6FA);
  static const cardBorder = Color(0xFFEDEDF3);
  static const textPrimary = Color(0xFF1D1B2E);
  static const textSecondary = Color(0xFF6E6B80);

  static const success = Color(0xFF1FA971);
  static const warning = Color(0xFFE08A2E);
  static const danger = Color(0xFFD7263D);
  static const info = Color(0xFF0EA5A5);
}

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
      backgroundColor: _Palette.background,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _Palette.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Profile Header Card
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: _Palette.primary),
                    ),
                  );
                }

                if (provider.error != null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: _boxDecoration(),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: _Palette.danger, size: 32),
                        const SizedBox(height: 10),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _Palette.danger),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () => provider.fetchProfile(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Palette.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                final profile = provider.profile;
                if (profile == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: _boxDecoration(),
                    child: const Center(
                      child: Text(
                        "No profile data found",
                        style: TextStyle(color: _Palette.textSecondary),
                      ),
                    ),
                  );
                }

                final name = profile["name"] ?? "";
                final email = profile["email"] ?? "";
                final role = profile["role"]?["title"] ?? "";
                final profilePhoto = profile["profile_photo"];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _boxDecoration(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _Palette.primary.withOpacity(0.25),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 33,
                          backgroundColor: _Palette.primary,
                          backgroundImage:
                          profilePhoto != null ? NetworkImage(profilePhoto) : null,
                          child: profilePhoto == null
                              ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "U",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                  color: _Palette.textPrimary,
                                )),
                            if (role.toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(role,
                                  style: const TextStyle(
                                      color: _Palette.textSecondary,
                                      fontSize: 13.5)),
                            ],
                            const SizedBox(height: 4),
                            Text(email,
                                style: const TextStyle(
                                    color: _Palette.textSecondary,
                                    fontSize: 13.5),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          _showEditProfileDialog(context, profile);
                        },
                        child: const Text(
                          "Edit",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ProfileStatCard(title: "Surveys", value: "156", icon: Icons.assignment),
                ProfileStatCard(title: "Total Earnings", value: "12,450", icon: Icons.wallet),
                ProfileStatCard(title: "Approval Rate", value: "95%", icon: Icons.check_circle),
                ProfileStatCard(title: "Current Streak", value: "12 days", icon: Icons.local_fire_department),
              ],
            ),

            const SizedBox(height: 24),

            /// KYC Verification Card
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
                    icon = Icons.verified_rounded;
                    statusColor = _Palette.success;
                    message = "Your KYC is approved";
                    buttonText = "Submitted";
                    buttonEnabled = false;
                    break;
                  case "REJECTED":
                    icon = Icons.cancel_rounded;
                    statusColor = _Palette.danger;
                    message = rejectedReason ?? "Your KYC was rejected";
                    buttonText = "ReSubmit";
                    buttonEnabled = true; // enable for resubmit
                    break;
                  case "SUBMITTED":
                    icon = Icons.hourglass_top_rounded;
                    statusColor = _Palette.warning;
                    message = "KYC under review";
                    buttonText = "Submitted";
                    buttonEnabled = false; // disable while under review
                    break;
                  default: // PENDING / Not submitted
                    icon = Icons.info_rounded;
                    statusColor = _Palette.info;
                    message = "KYC not submitted";
                    buttonText = "Submit";
                    buttonEnabled = true;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _boxDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, size: 26, color: statusColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Identity Verification",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _Palette.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: TextStyle(
                                  color: statusColor, fontSize: 13.5),
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
                          backgroundColor:
                          buttonEnabled ? statusColor : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            color: buttonEnabled
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// Achievements Card
            _sectionTitle("Achievements"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  _achievementTile(
                    icon: Icons.emoji_events_rounded,
                    color: _Palette.warning,
                    title: "Top Performer",
                    subtitle: "Ranked #5 this month",
                  ),
                  Divider(height: 1, color: _Palette.cardBorder, indent: 16, endIndent: 16),
                  _achievementTile(
                    icon: Icons.camera_alt_rounded,
                    color: _Palette.info,
                    title: "Quality Expert",
                    subtitle: "95% photo approval rate",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Settings Card
            _sectionTitle("Settings"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      "Push Notifications",
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: _Palette.textPrimary),
                    ),
                    value: pushNotification,
                    activeColor: _Palette.primary,
                    onChanged: (val) {
                      setState(() {
                        pushNotification = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      "Location Services",
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: _Palette.textPrimary),
                    ),
                    value: locationServices,
                    activeColor: _Palette.primary,
                    onChanged: (val) {
                      setState(() {
                        locationServices = val;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text(
                      "Data Privacy",
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: _Palette.textPrimary),
                    ),
                    trailing: const Text(
                      "Manage",
                      style: TextStyle(
                          color: _Palette.primary, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// Sign Out Button
            // SizedBox(
            //   width: double.infinity,
            //   child: OutlinedButton.icon(
            //     onPressed: () {},
            //     icon: const Icon(Icons.logout, color: Colors.red),
            //     label: const Text(
            //       "Sign Out",
            //       style: TextStyle(color: Colors.red),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _Palette.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: _Palette.textPrimary,
        ),
      ),
    );
  }

  Widget _achievementTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: _Palette.textPrimary, fontSize: 14.5),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _Palette.textSecondary, fontSize: 13),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            "Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold, color: _Palette.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration("Name", Icons.person_outline_rounded),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email", Icons.email_outlined),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  decoration: _inputDecoration("Phone", Icons.phone_outlined),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: _Palette.textSecondary),
              ),
            ),
            Consumer<ProfileProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Save",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: _Palette.textSecondary),
      labelStyle: const TextStyle(color: _Palette.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Palette.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Palette.primary, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}