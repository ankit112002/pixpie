import 'package:flutter/material.dart';
import 'package:pixpie/others/unassigned_aoi_screen.dart';
import 'package:provider/provider.dart';
import 'package:pixpie/others/profile_screen.dart';
import 'package:pixpie/screens/admin_login.dart';
import '../app_preferences.dart';
import '../provider/profile_provider.dart';
import 'aoi_screen.dart';
import 'earning_screen.dart';

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
      child: Column(
        children: [

          /// 🔹 Drawer Header with professional styling
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              final profile = provider.profile;

              final name = profile?["name"] ?? "User";
              final email = profile?["email"] ?? "";
              final profilePhoto = profile?["profile_photo"];

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: profilePhoto != null
                          ? NetworkImage(profilePhoto)
                          : null,
                      child: profilePhoto == null
                          ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "U",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          /// 🔹 Menu Items with ripple effects
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
                MaterialPageRoute(builder: (_) => const UnassignedAoiScreen()),
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

          const Spacer(),
          const Divider(thickness: 1, height: 1),

          /// 🔹 Logout Button with accent color
          _drawerItem(
            icon: Icons.logout,
            title: "Sign Out",
            color: Colors.red.shade700,
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to sign out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );

              if (shouldLogout ?? false) {
                await _logoutAndNavigate();
              }
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _logoutAndNavigate() async {
    Navigator.of(context).maybePop();
    await AppPreferences.logout();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLogin()),
          (route) => false,
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          )),
      hoverColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}