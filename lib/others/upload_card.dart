import 'dart:io';
import 'package:flutter/material.dart';

class UploadCard extends StatelessWidget {

  final String title;
  final File? image;
  final VoidCallback onTap;

  const UploadCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),

        child: image == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 32),
            const SizedBox(height: 6),
            Text(title),
          ],
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}