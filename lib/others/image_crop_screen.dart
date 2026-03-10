import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class ImageCropScreen extends StatefulWidget {
  final Uint8List imageData;

  const ImageCropScreen({super.key, required this.imageData});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _controller = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _controller.crop();
            },
          )
        ],
      ),
      body: Crop(
        image: widget.imageData,
        controller: _controller,
        onCropped: (image) {
          if (!mounted) return;

          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pop(image);
            }
          });
        },
      ),
    );
  }
}