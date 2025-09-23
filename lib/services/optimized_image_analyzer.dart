import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';

class OptimizedImageAnalyzer {
  static const int _chunkSize = 1024;
  static const int _parallelThreshold = 10000; // Use parallel processing for large images

  // Optimized aspect ratio analysis
  Future<double> analyzeAspectRatioOptimized(int width, int height) async {
    try {
      double aspectRatio = width / height;
      
      // Standard aspect ratios for photography
      // 4:3, 3:2, 16:9, 1:1 are considered good
      // Very wide (>3:1) or very tall (<1:3) are usually poor
      double aspectScore = 0.0;
      
      if (aspectRatio >= 0.8 && aspectRatio <= 1.2) {
        // Square-ish (1:1, 4:3, 3:4)
        aspectScore = 1.0; // Excellent - standard photography ratio
      } else if (aspectRatio >= 1.2 && aspectRatio <= 1.8) {
        // Landscape (3:2, 4:3, 16:10)
        aspectScore = 0.9; // Very good - standard landscape
      } else if (aspectRatio >= 0.6 && aspectRatio <= 0.8) {
        // Portrait (3:4, 4:5)
        aspectScore = 0.9; // Very good - standard portrait
      } else if (aspectRatio >= 1.8 && aspectRatio <= 2.5) {
        // Wide landscape (16:9, 21:9)
        aspectScore = 0.7; // Good - cinematic but acceptable
      } else if (aspectRatio >= 0.4 && aspectRatio <= 0.6) {
        // Tall portrait (2:3, 3:5)
        aspectScore = 0.7; // Good - tall but acceptable
      } else if (aspectRatio > 2.5) {
        // Very wide (panorama, screenshots)
        aspectScore = 0.2; // Poor - likely panorama or screenshot
      } else if (aspectRatio < 0.4) {
        // Very tall (tall screenshots, documents)
        aspectScore = 0.2; // Poor - likely document or screenshot
      } else {
        aspectScore = 0.5; // Neutral - unusual but not extreme
      }
      
      print('DEBUG: Optimized aspect ratio analysis - Width: $width, Height: $height, Ratio: ${aspectRatio.toStringAsFixed(2)}, Score: ${aspectScore.toStringAsFixed(2)}');
      return aspectScore;
    } catch (e) {
      print('DEBUG: Error in optimized aspect ratio analysis: $e');
      return 0.5; // Default score
    }
  }

  // Optimized blur detection using chunked processing
  Future<double> analyzeBlurOptimized(Uint8List imageData, int width, int height) async {
    if (width * height > _parallelThreshold) {
      return await _analyzeBlurParallel(imageData, width, height);
    } else {
      return await _analyzeBlurSequential(imageData, width, height);
    }
  }

  // Parallel blur analysis for large images
  Future<double> _analyzeBlurParallel(Uint8List imageData, int width, int height) async {
    try {
      // Split image into chunks for parallel processing
      final chunks = _createImageChunks(imageData, width, height);
      
      // Process chunks in parallel
      final futures = chunks.map((chunk) => 
        compute(_processBlurChunk, {
          'chunk': chunk.data,
          'width': chunk.width,
          'height': chunk.height,
          'startX': chunk.startX,
          'startY': chunk.startY,
          'totalWidth': width,
        })
      ).toList();

      final results = await Future.wait(futures);
      
      // Combine results
      final allLaplacianValues = <double>[];
      for (final result in results) {
        allLaplacianValues.addAll(result);
      }

      return _calculateVariance(allLaplacianValues);
    } catch (e) {
      print('DEBUG: Parallel blur analysis failed: $e');
      return await _analyzeBlurSequential(imageData, width, height);
    }
  }

  // Sequential blur analysis for smaller images
  Future<double> _analyzeBlurSequential(Uint8List imageData, int width, int height) async {
    try {
      final grayscaleData = _convertToGrayscaleOptimized(imageData, width, height);
      final laplacianValues = _calculateLaplacianValues(grayscaleData, width, height);
      return _calculateVariance(laplacianValues);
    } catch (e) {
      print('DEBUG: Sequential blur analysis failed: $e');
      return 0.5;
    }
  }

  // Optimized grayscale conversion
  List<int> _convertToGrayscaleOptimized(Uint8List imageData, int width, int height) {
    final grayscale = List<int>.filled(width * height, 0);
    
    // Process pixels in chunks for better cache performance
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIndex = y * width + x;
        final dataIndex = pixelIndex * 4;
        
        if (dataIndex + 2 < imageData.length) {
          final r = imageData[dataIndex];
          final g = imageData[dataIndex + 1];
          final b = imageData[dataIndex + 2];
          
          // Use optimized luminance formula
          grayscale[pixelIndex] = ((r * 299 + g * 587 + b * 114) / 1000).round();
        }
      }
    }
    
    return grayscale;
  }

  // Calculate Laplacian values with boundary checking
  List<double> _calculateLaplacianValues(List<int> grayscale, int width, int height) {
    final laplacianValues = <double>[];
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final index = y * width + x;
        
        // Laplacian kernel: [[0,1,0],[1,-4,1],[0,1,0]]
        final left = grayscale[index - 1].toDouble();
        final right = grayscale[index + 1].toDouble();
        final top = grayscale[index - width].toDouble();
        final bottom = grayscale[index + width].toDouble();
        final center = grayscale[index].toDouble();
        
        final laplacian = left + right + top + bottom - 4.0 * center;
        laplacianValues.add(laplacian * laplacian); // Square for variance
      }
    }
    
    return laplacianValues;
  }

  // Optimized exposure analysis with histogram optimization
  Future<double> analyzeExposureOptimized(Uint8List imageData, int width, int height) async {
    try {
      final grayscaleData = _convertToGrayscaleOptimized(imageData, width, height);
      
      // Use optimized histogram calculation
      final histogram = _calculateHistogramOptimized(grayscaleData);
      
      // Calculate statistics efficiently
      final stats = _calculateHistogramStats(histogram);
      
      return _calculateExposureScore(stats);
    } catch (e) {
      print('DEBUG: Optimized exposure analysis failed: $e');
      return 0.5;
    }
  }

  // Optimized histogram calculation
  List<int> _calculateHistogramOptimized(List<int> grayscaleData) {
    final histogram = List<int>.filled(256, 0);
    
    // Use batch processing for better performance
    for (int i = 0; i < grayscaleData.length; i += _chunkSize) {
      final endIndex = (i + _chunkSize < grayscaleData.length) 
          ? i + _chunkSize 
          : grayscaleData.length;
      
      for (int j = i; j < endIndex; j++) {
        final pixel = grayscaleData[j];
        if (pixel >= 0 && pixel < 256) {
          histogram[pixel]++;
        }
      }
    }
    
    return histogram;
  }

  // Calculate histogram statistics efficiently
  Map<String, double> _calculateHistogramStats(List<int> histogram) {
    int totalPixels = 0;
    int sum = 0;
    int sumSquared = 0;
    
    for (int i = 0; i < 256; i++) {
      final count = histogram[i];
      totalPixels += count;
      sum += i * count;
      sumSquared += i * i * count;
    }
    
    if (totalPixels == 0) {
      return {'mean': 0.0, 'stdDev': 0.0, 'totalPixels': 0.0};
    }
    
    final mean = sum / totalPixels;
    final variance = (sumSquared / totalPixels) - (mean * mean);
    final stdDev = sqrt(variance);
    
    return {
      'mean': mean,
      'stdDev': stdDev,
      'totalPixels': totalPixels.toDouble(),
    };
  }

  // Calculate exposure score based on statistics
  double _calculateExposureScore(Map<String, double> stats) {
    final mean = stats['mean'] ?? 0.0;
    final stdDev = stats['stdDev'] ?? 0.0;
    
    double exposureScore = 0.0;
    
    // Check for exposure issues
    if (mean < 20) {
      exposureScore = 0.0; // Too dark
    } else if (mean > 235) {
      exposureScore = 0.0; // Too bright
    } else if (mean < 40) {
      exposureScore = 0.2; // Very dark
    } else if (mean > 200) {
      exposureScore = 0.2; // Very bright
    } else if (mean < 60) {
      exposureScore = 0.4; // Dark
    } else if (mean > 180) {
      exposureScore = 0.4; // Bright
    } else if (mean >= 80 && mean <= 150) {
      exposureScore = 1.0; // Good exposure
    } else {
      exposureScore = 0.6; // Acceptable
    }
    
    // Adjust based on contrast
    if (stdDev < 15) {
      exposureScore *= 0.3; // Very low contrast
    } else if (stdDev < 30) {
      exposureScore *= 0.6; // Low contrast
    } else if (stdDev > 60) {
      exposureScore *= 1.0; // Good contrast
    }
    
    return exposureScore.clamp(0.0, 1.0);
  }

  // Create image chunks for parallel processing
  List<ImageChunk> _createImageChunks(Uint8List imageData, int width, int height) {
    final chunks = <ImageChunk>[];
    final chunkWidth = (width / 2).round();
    final chunkHeight = (height / 2).round();
    
    for (int y = 0; y < 2; y++) {
      for (int x = 0; x < 2; x++) {
        final startX = x * chunkWidth;
        final startY = y * chunkHeight;
        final endX = (x == 1) ? width : startX + chunkWidth;
        final endY = (y == 1) ? height : startY + chunkHeight;
        
        final chunkData = _extractChunkData(imageData, width, startX, startY, endX, endY);
        
        chunks.add(ImageChunk(
          data: chunkData,
          width: endX - startX,
          height: endY - startY,
          startX: startX,
          startY: startY,
        ));
      }
    }
    
    return chunks;
  }

  // Extract chunk data from full image
  Uint8List _extractChunkData(Uint8List imageData, int totalWidth, int startX, int startY, int endX, int endY) {
    final chunkWidth = endX - startX;
    final chunkHeight = endY - startY;
    final chunkData = Uint8List(chunkWidth * chunkHeight * 4);
    
    int chunkIndex = 0;
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final sourceIndex = (y * totalWidth + x) * 4;
        if (sourceIndex + 3 < imageData.length) {
          chunkData[chunkIndex++] = imageData[sourceIndex];
          chunkData[chunkIndex++] = imageData[sourceIndex + 1];
          chunkData[chunkIndex++] = imageData[sourceIndex + 2];
          chunkData[chunkIndex++] = imageData[sourceIndex + 3];
        }
      }
    }
    
    return chunkData;
  }

  // Calculate variance from list of values
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    
    return variance;
  }
}

// Data class for image chunks
class ImageChunk {
  final Uint8List data;
  final int width;
  final int height;
  final int startX;
  final int startY;

  ImageChunk({
    required this.data,
    required this.width,
    required this.height,
    required this.startX,
    required this.startY,
  });
}

// Top-level function for compute()
List<double> _processBlurChunk(Map<String, dynamic> params) {
  final chunk = params['chunk'] as Uint8List;
  final width = params['width'] as int;
  final height = params['height'] as int;
  final startX = params['startX'] as int;
  final startY = params['startY'] as int;
  final totalWidth = params['totalWidth'] as int;

  final analyzer = OptimizedImageAnalyzer();
  final grayscaleData = analyzer._convertToGrayscaleOptimized(chunk, width, height);
  return analyzer._calculateLaplacianValues(grayscaleData, width, height);
}
