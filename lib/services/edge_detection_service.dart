import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class EdgeDetectionService {
  /// Detect edges in an image using the specified algorithm
  Future<Uint8List> detectEdges(
    Uint8List imageBytes, {
    required String algorithm,
    required int lowThreshold,
    required int highThreshold,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    img.Image processedImage;

    switch (algorithm) {
      case 'Canny':
        processedImage = _cannyEdgeDetection(
          image,
          lowThreshold: lowThreshold,
          highThreshold: highThreshold,
        );
        break;
      case 'Sobel':
        processedImage = _sobelEdgeDetection(image);
        break;
      case 'Laplacian':
        processedImage = _laplacianEdgeDetection(image);
        break;
      default:
        processedImage = _cannyEdgeDetection(
          image,
          lowThreshold: lowThreshold,
          highThreshold: highThreshold,
        );
    }

    return Uint8List.fromList(img.encodePng(processedImage));
  }

  /// Canny edge detection algorithm
  img.Image _cannyEdgeDetection(
    img.Image image, {
    required int lowThreshold,
    required int highThreshold,
  }) {
    // Convert to grayscale if needed
    img.Image gray = image.numChannels == 1
        ? image.clone()
        : img.grayscale(image.clone());

    // Apply Gaussian blur to reduce noise
    gray = img.gaussianBlur(gray, radius: 1);

    // Apply Sobel operator to get gradients
    final width = gray.width;
    final height = gray.height;
    final sobelX = List.generate(
      width * height,
      (i) => 0.0,
      growable: false,
    );
    final sobelY = List.generate(
      width * height,
      (i) => 0.0,
      growable: false,
    );
    final magnitude = List.generate(
      width * height,
      (i) => 0.0,
      growable: false,
    );

    // Sobel kernels
    const sobelKernelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    const sobelKernelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double gx = 0, gy = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = gray.getPixel(x + kx, y + ky);
            final grayValue = img.getLuminance(pixel);
            gx += grayValue * sobelKernelX[ky + 1][kx + 1];
            gy += grayValue * sobelKernelY[ky + 1][kx + 1];
          }
        }
        final idx = y * width + x;
        sobelX[idx] = gx;
        sobelY[idx] = gy;
        magnitude[idx] = math.sqrt(gx * gx + gy * gy);
      }
    }

    // Non-maximum suppression
    final suppressed = List.generate(
      width * height,
      (i) => 0.0,
      growable: false,
    );

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;
        final angle = (math.atan2(sobelY[idx], sobelX[idx]) * 180 / 3.14159 + 180) %
            180;
        double neighbor1 = 0, neighbor2 = 0;

        if ((angle >= 0 && angle < 22.5) ||
            (angle >= 157.5 && angle < 180)) {
          neighbor1 = magnitude[(y * width + x) - 1];
          neighbor2 = magnitude[(y * width + x) + 1];
        } else if (angle >= 22.5 && angle < 67.5) {
          neighbor1 = magnitude[((y - 1) * width + (x + 1))];
          neighbor2 = magnitude[((y + 1) * width + (x - 1))];
        } else if (angle >= 67.5 && angle < 112.5) {
          neighbor1 = magnitude[((y - 1) * width + x)];
          neighbor2 = magnitude[((y + 1) * width + x)];
        } else if (angle >= 112.5 && angle < 157.5) {
          neighbor1 = magnitude[((y - 1) * width + (x - 1))];
          neighbor2 = magnitude[((y + 1) * width + (x + 1))];
        }

        if (magnitude[idx] >= neighbor1 && magnitude[idx] >= neighbor2) {
          suppressed[idx] = magnitude[idx];
        }
      }
    }

    // Double threshold and edge tracking
    // Initialize with white background
    final result = img.Image(width: width, height: height);
    // Fill with white
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        result.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }
    
    final visited = List.generate(
      width * height,
      (i) => false,
      growable: false,
    );

    void traceEdge(int x, int y) {
      final idx = y * width + x;
      if (x < 0 || x >= width || y < 0 || y >= height || visited[idx]) {
        return;
      }
      visited[idx] = true;
      if (suppressed[idx] > lowThreshold) {
        // Set edges to black on white background
        result.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx != 0 || dy != 0) {
              traceEdge(x + dx, y + dy);
            }
          }
        }
      }
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (suppressed[idx] >= highThreshold && !visited[idx]) {
          traceEdge(x, y);
        }
        // Background is already white, no need to set non-edges
      }
    }

    return result;
  }

  /// Sobel edge detection
  img.Image _sobelEdgeDetection(img.Image image) {
    img.Image gray = image.numChannels == 1
        ? image.clone()
        : img.grayscale(image.clone());

    final width = gray.width;
    final height = gray.height;
    final result = img.Image(width: width, height: height);
    // Initialize with white background
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        result.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }

    const sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    const sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double gx = 0, gy = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = gray.getPixel(x + kx, y + ky);
            final grayValue = img.getLuminance(pixel);
            gx += grayValue * sobelX[ky + 1][kx + 1];
            gy += grayValue * sobelY[ky + 1][kx + 1];
          }
        }
        final magnitude = math.sqrt(gx * gx + gy * gy);
        // Invert: white background with black edges
        final value = (255 - magnitude.clamp(0.0, 255.0)).toInt();
        result.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }

    return result;
  }

  /// Laplacian edge detection
  img.Image _laplacianEdgeDetection(img.Image image) {
    img.Image gray = image.numChannels == 1
        ? image.clone()
        : img.grayscale(image.clone());

    final width = gray.width;
    final height = gray.height;
    final result = img.Image(width: width, height: height);
    // Initialize with white background
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        result.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }

    const laplacianKernel = [
      [0, -1, 0],
      [-1, 4, -1],
      [0, -1, 0],
    ];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double sum = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = gray.getPixel(x + kx, y + ky);
            final grayValue = img.getLuminance(pixel);
            sum += grayValue * laplacianKernel[ky + 1][kx + 1];
          }
        }
        // Invert: white background with black edges
        final value = (255 - sum.abs().clamp(0.0, 255.0)).toInt();
        result.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }

    return result;
  }
}

