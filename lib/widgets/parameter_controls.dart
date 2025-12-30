import 'package:flutter/material.dart';

class ParameterControls extends StatelessWidget {
  final double lowThreshold;
  final double highThreshold;
  final String algorithm;
  final Function({
    double? lowThreshold,
    double? highThreshold,
    String? algorithm,
  }) onChanged;

  const ParameterControls({
    super.key,
    required this.lowThreshold,
    required this.highThreshold,
    required this.algorithm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edge Detection Parameters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Algorithm selection
          DropdownButtonFormField<String>(
            value: algorithm,
            decoration: const InputDecoration(
              labelText: 'Algorithm',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Canny', child: Text('Canny')),
              DropdownMenuItem(value: 'Sobel', child: Text('Sobel')),
              DropdownMenuItem(value: 'Laplacian', child: Text('Laplacian')),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(algorithm: value);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Low threshold slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Low Threshold:'),
                  Text('${lowThreshold.toInt()}'),
                ],
              ),
              Slider(
                value: lowThreshold,
                min: 0,
                max: 255,
                divisions: 255,
                label: lowThreshold.toInt().toString(),
                onChanged: (value) {
                  onChanged(lowThreshold: value);
                },
              ),
            ],
          ),
          
          // High threshold slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('High Threshold:'),
                  Text('${highThreshold.toInt()}'),
                ],
              ),
              Slider(
                value: highThreshold,
                min: 0,
                max: 255,
                divisions: 255,
                label: highThreshold.toInt().toString(),
                onChanged: (value) {
                  onChanged(highThreshold: value);
                },
              ),
            ],
          ),
          
          if (algorithm != 'Canny')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Note: Threshold parameters only apply to Canny algorithm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

