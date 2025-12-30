import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageViewer extends StatelessWidget {
  final Uint8List? originalImage;
  final Uint8List? processedImage;

  const ImageViewer({
    super.key,
    this.originalImage,
    this.processedImage,
  });

  @override
  Widget build(BuildContext context) {
    if (originalImage == null && processedImage == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No image loaded',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Click "Open Image" or "Paste Image" to get started',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Original image
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  width: double.infinity,
                  child: const Text(
                    'Original',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: originalImage != null
                      ? Image.memory(
                          originalImage!,
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: Text('No original image'),
                        ),
                ),
              ],
            ),
          ),
        ),
        
        // Processed image
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  width: double.infinity,
                  child: const Text(
                    'Edge Detected',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: processedImage != null
                      ? Image.memory(
                          processedImage!,
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: Text('Processing...'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

