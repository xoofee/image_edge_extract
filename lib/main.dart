import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_edge_extractor/services/edge_detection_service.dart';
import 'package:image_edge_extractor/widgets/image_viewer.dart';
import 'package:image_edge_extractor/widgets/parameter_controls.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pasteboard/pasteboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Edge Extractor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EdgeExtractorPage(),
    );
  }
}

class EdgeExtractorPage extends StatefulWidget {
  const EdgeExtractorPage({super.key});

  @override
  State<EdgeExtractorPage> createState() => _EdgeExtractorPageState();
}

class _EdgeExtractorPageState extends State<EdgeExtractorPage> {
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  bool _isProcessing = false;
  
  // Edge detection parameters
  double _lowThreshold = 50.0;
  double _highThreshold = 150.0;
  String _algorithm = 'Canny';
  
  final EdgeDetectionService _edgeDetectionService = EdgeDetectionService();

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        setState(() {
          _originalImageBytes = bytes;
          _processedImageBytes = null;
        });
        _processImage();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pasteImage() async {
    try {
      final imageData = await Pasteboard.image;
      
      if (imageData != null) {
        setState(() {
          _originalImageBytes = imageData;
          _processedImageBytes = null;
        });
        _processImage();
      } else {
        _showError('No image found in clipboard');
      }
    } catch (e) {
      _showError('Failed to paste image: $e');
    }
  }

  Future<void> _processImage() async {
    if (_originalImageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final processedBytes = await _edgeDetectionService.detectEdges(
        _originalImageBytes!,
        algorithm: _algorithm,
        lowThreshold: _lowThreshold.toInt(),
        highThreshold: _highThreshold.toInt(),
      );

      setState(() {
        _processedImageBytes = processedBytes;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to process image: $e');
    }
  }

  Future<void> _printImage() async {
    if (_processedImageBytes == null) {
      _showError('No processed image to print');
      return;
    }

    try {
      final image = img.decodeImage(_processedImageBytes!);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              pageFormat: format,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(_processedImageBytes!),
                    fit: pw.BoxFit.contain,
                  ),
                );
              },
            ),
          );
          return pdf.save();
        },
      );
    } catch (e) {
      _showError('Failed to print: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onParametersChanged({
    double? lowThreshold,
    double? highThreshold,
    String? algorithm,
  }) {
    setState(() {
      if (lowThreshold != null) _lowThreshold = lowThreshold;
      if (highThreshold != null) _highThreshold = highThreshold;
      if (algorithm != null) _algorithm = algorithm;
    });
    _processImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Image Edge Extractor'),
        actions: [
          if (_processedImageBytes != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printImage,
              tooltip: 'Print',
            ),
        ],
      ),
      body: Column(
        children: [
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Image'),
                ),
                ElevatedButton.icon(
                  onPressed: _pasteImage,
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste Image'),
                ),
              ],
            ),
          ),
          
          // Parameter controls
          if (_originalImageBytes != null)
            ParameterControls(
              lowThreshold: _lowThreshold,
              highThreshold: _highThreshold,
              algorithm: _algorithm,
              onChanged: _onParametersChanged,
            ),
          
          // Image viewer
          Expanded(
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ImageViewer(
                    originalImage: _originalImageBytes,
                    processedImage: _processedImageBytes,
                  ),
          ),
        ],
      ),
    );
  }
}

