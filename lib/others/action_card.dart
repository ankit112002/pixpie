import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}