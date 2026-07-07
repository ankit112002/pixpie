import 'package:PixPe/others/profile_screen.dart';
import 'package:PixPe/others/unassigned_aoi_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_preferences.dart';
import '../provider/profile_provider.dart';
import '../screens/admin_login.dart';
import 'aoi_screen.dart';
import 'earning_screen.dart';

/// Same palette used across the app (dashboard, drawer, etc.) so every
/// screen reads as one cohesive, professional design system.
class _Palette {
  static const primary = Color(0xFF4B2FBF);
  static const primaryDark = Color(0xFF37217F);
  static const background = Color(0xFFF5F6FA);
  static const cardBorder = Color(0xFFEDEDF3);
  static const textPrimary = Color(0xFF1D1B2E);
  static const textSecondary = Color(0xFF6E6B80);
  static const danger = Color(0xFFD7263D);
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  void initState() {
    super.initState();
    // Fetch profile once the drawer is built
    Future.microtask(
            () => Provider.of<ProfileProvider>(context, listen: false).fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            /// Drawer Header with professional styling
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                final profile = provider.profile;

                final name = profile?["name"] ?? "User";
                final email = profile?["email"] ?? "";
                final profilePhoto = profile?["profile_photo"];

                return Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_Palette.primary, _Palette.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white,
                          backgroundImage: profilePhoto != null
                              ? NetworkImage(profilePhoto)
                              : null,
                          child: profilePhoto == null
                              ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "U",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _Palette.primary,
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            /// Menu Items with ripple effects
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _drawerItem(
                    icon: Icons.home_outlined,
                    title: "Home",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.map_outlined,
                    title: "Assigned AOIs",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AOIScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.map_outlined,
                    title: "UnAssigned AOIs",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UnassignedAoiScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "PixPoint",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EarningsScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.person_outline,
                    title: "Profile",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1, height: 1, color: _Palette.cardBorder),

            /// Logout Button with accent color
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _drawerItem(
                icon: Icons.logout_rounded,
                title: "Sign Out",
                color: _Palette.danger,
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "Confirm Logout",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text("Are you sure you want to sign out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: _Palette.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                              color: _Palette.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await _logoutAndNavigate();
                  }
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _logoutAndNavigate() async {
    try {
      // Example async logout operation
      await AppPreferences.clearToken();

      if (!mounted) return; // <-- ADD THIS CHECK

      // Navigate safely
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLogin()),
      );
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = _Palette.textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          hoverColor: _Palette.primary.withOpacity(0.06),
          splashColor: _Palette.primary.withOpacity(0.10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      ),
    );
  }
}