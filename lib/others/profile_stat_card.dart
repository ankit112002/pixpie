import 'package:flutter/material.dart';

class ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  const ProfileStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          /// 🔹 Accent Bar on top
          if (accentColor != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null)
                  Icon(icon, color: accentColor ?? Colors.blue, size: 28),
                if (icon != null) const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}