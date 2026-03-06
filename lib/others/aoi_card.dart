import 'package:flutter/material.dart';

class AOICard extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final String priority;

  const AOICard({
    super.key,
    required this.title,
    required this.location,
    required this.status,
    required this.priority,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(location, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(label: Text(status)),
              const SizedBox(width: 8),
              Chip(label: Text(priority)),
            ],
          )
        ],
      ),
    );
  }
}