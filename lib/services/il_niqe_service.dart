import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

/// IL-NIQE Image Quality Analysis Service
/// Provides advanced image quality assessment using the IL-NIQE algorithm
class ILNIQEService {
  // Use Vercel API endpoint
  static const String _baseUrl = 'https://api-image-analyze.vercel.app';
  
  /// Check if the IL-NIQE API server is healthy
  static Future<bool> isServerHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('IL-NIQE Server health check failed: $e');
      return false;
    }
  }

  /// Convert AssetEntity to base64 string with compression
  static Future<String> assetToBase64(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) {
        throw Exception('Could not access asset file');
      }
      
      final bytes = await file.readAsBytes();
      print('DEBUG: 📏 Original image size: ${bytes.length} bytes');
      
      // Compress the image before converting to base64
      final compressedBytes = await _compressImage(bytes);
      print('DEBUG: 📏 Compressed image size: ${compressedBytes.length} bytes');
      print('DEBUG: 📊 Compression ratio: ${((bytes.length - compressedBytes.length) / bytes.length * 100).toStringAsFixed(1)}%');
      
      return base64Encode(compressedBytes);
    } catch (e) {
      throw Exception('Failed to convert asset to base64: $e');
    }
  }

  /// Compress image to reduce payload size
  static Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Calculate target dimensions (max 1024px on longest side)
      int targetWidth = image.width;
      int targetHeight = image.height;
      const int maxDimension = 1024;
      
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          targetWidth = maxDimension;
          targetHeight = (image.height * maxDimension / image.width).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (image.width * maxDimension / image.height).round();
        }
      }

      // Resize image if needed
      img.Image resizedImage = image;
      if (targetWidth != image.width || targetHeight != image.height) {
        resizedImage = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );
        print('DEBUG: 🔄 Resized image from ${image.width}x${image.height} to ${targetWidth}x${targetHeight}');
      }

      // Encode as JPEG with quality 85 (good balance between quality and size)
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      print('DEBUG: ⚠️ Image compression failed, using original: $e');
      // If compression fails, return original bytes
      return imageBytes;
    }
  }

  /// Convert File to base64 string with compression
  static Future<String> fileToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      print('DEBUG: 📏 Original image size: ${bytes.length} bytes');
      
      // Compress the image before converting to base64
      final compressedBytes = await _compressImage(bytes);
      print('DEBUG: 📏 Compressed image size: ${compressedBytes.length} bytes');
      print('DEBUG: 📊 Compression ratio: ${((bytes.length - compressedBytes.length) / bytes.length * 100).toStringAsFixed(1)}%');
      
      return base64Encode(compressedBytes);
    } catch (e) {
      throw Exception('Failed to convert file to base64: $e');
    }
  }

  /// Analyze single image quality using IL-NIQE
  static Future<ILNIQEResult> analyzeSingleImage(AssetEntity asset) async {
    try {
      print('DEBUG: 🚀 Starting IL-NIQE analysis for asset: ${asset.id}');
      print('DEBUG: 📁 Asset filename: ${asset.title ?? 'unknown'}');
      print('DEBUG: 📏 Asset dimensions: ${asset.width}x${asset.height}');
      print('DEBUG: 📅 Asset date: ${asset.createDateTime}');
      
      final base64Image = await assetToBase64(asset);
      if (base64Image == null) {
        print('DEBUG: ❌ Failed to convert asset to base64');
        return ILNIQEResult(
          qualityScore: 0.0,
          category: 'Error',
          processingTime: 0.0,
          success: false,
          error: 'Failed to convert image to base64',
        );
      }
      
      print('DEBUG: ✅ Image converted to base64, size: ${base64Image.length} characters');
      print('DEBUG: 🌐 Sending request to: $_baseUrl/analyze-single');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-single'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(Duration(seconds: 30));

      print('DEBUG: 📡 IL-NIQE API response status: ${response.statusCode}');
      print('DEBUG: 📄 IL-NIQE API response headers: ${response.headers}');
      print('DEBUG: 📝 IL-NIQE API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: 🎯 IL-NIQE API parsed data: $data');
        print('DEBUG: 📊 Quality Score: ${data['quality_score']}');
        print('DEBUG: 🏷️ Category: ${data['category']}');
        print('DEBUG: ⏱️ Processing Time: ${data['processing_time']}ms');
        
        final result = ILNIQEResult.fromJson(data);
        print('DEBUG: ✅ IL-NIQE analysis completed successfully');
        print('DEBUG: 🎯 Final result - Score: ${result.qualityScore}, Category: ${result.category}');
        
        return result;
      } else {
        print('DEBUG: ❌ IL-NIQE API error: ${response.statusCode}');
        print('DEBUG: 📄 Error response body: ${response.body}');
        final errorData = jsonDecode(response.body);
        return ILNIQEResult(
          qualityScore: 0.0,
          category: 'Error',
          processingTime: 0.0,
          success: false,
          error: errorData['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      print('DEBUG: 💥 IL-NIQE analysis exception: $e');
      print('DEBUG: 📍 Exception type: ${e.runtimeType}');
      return ILNIQEResult(
        qualityScore: 0.0,
        category: 'Error',
        processingTime: 0.0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Analyze single image from File using IL-NIQE
  static Future<ILNIQEResult> analyzeSingleFile(File imageFile) async {
    try {
      final base64Image = await fileToBase64(imageFile);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-single'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ILNIQEResult.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        return ILNIQEResult(
          qualityScore: 0.0,
          category: 'Error',
          processingTime: 0.0,
          success: false,
          error: errorData['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      return ILNIQEResult(
        qualityScore: 0.0,
        category: 'Error',
        processingTime: 0.0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Analyze multiple images in batch using IL-NIQE
  static Future<ILNIQEBatchResult> analyzeBatchImages(List<AssetEntity> assets) async {
    try {
      if (assets.isEmpty) {
        return ILNIQEBatchResult(
          results: [],
          summary: ILNIQEBatchSummary(
            totalImages: 0,
            successfulAnalyses: 0,
            failedAnalyses: 0,
            averageScore: 0.0,
            bestScore: 0.0,
            worstScore: 0.0,
            categoryDistribution: {},
            totalProcessingTime: 0.0,
          ),
          success: false,
          error: 'No images provided',
        );
      }

      // Convert all images to base64
      List<String> base64Images = [];
      for (AssetEntity asset in assets) {
        final base64Image = await assetToBase64(asset);
        base64Images.add(base64Image);
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'images': base64Images}),
      ).timeout(Duration(seconds: 30)); // Shorter timeout for batch processing

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ILNIQEBatchResult.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        return ILNIQEBatchResult(
          results: [],
          summary: ILNIQEBatchSummary(
            totalImages: 0,
            successfulAnalyses: 0,
            failedAnalyses: 0,
            averageScore: 0.0,
            bestScore: 0.0,
            worstScore: 0.0,
            categoryDistribution: {},
            totalProcessingTime: 0.0,
          ),
          success: false,
          error: errorData['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      return ILNIQEBatchResult(
        results: [],
        summary: ILNIQEBatchSummary(
          totalImages: 0,
          successfulAnalyses: 0,
          failedAnalyses: 0,
          averageScore: 0.0,
          bestScore: 0.0,
          worstScore: 0.0,
          categoryDistribution: {},
          totalProcessingTime: 0.0,
        ),
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get category color for UI display
  static String getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'good':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'moderate':
        return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'bad':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  }

  /// Get category icon for UI display
  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'good':
        return '✓';
      case 'moderate':
        return '⚠';
      case 'bad':
        return '✗';
      default:
        return '?';
    }
  }

  /// Get quality description based on score and category
  static String getQualityDescription(double score, String category) {
    switch (category.toLowerCase()) {
      case 'good':
        return '✅ Excellent quality (Score: ${score.toStringAsFixed(1)})';
      case 'moderate':
        return '⚠️ Decent quality (Score: ${score.toStringAsFixed(1)})';
      case 'bad':
        return '❌ Poor quality (Score: ${score.toStringAsFixed(1)})';
      default:
        return '❓ Unknown quality (Score: ${score.toStringAsFixed(1)})';
    }
  }

  /// Check if image quality is good based on new API specification
  static bool isGoodQuality(String category) {
    return category.toLowerCase() == 'good';
  }

  /// Check if image quality is acceptable (good or moderate)
  static bool isAcceptableQuality(String category) {
    final lowerCategory = category.toLowerCase();
    return lowerCategory == 'good' || lowerCategory == 'moderate';
  }
}

/// IL-NIQE Analysis Result for a single image
class ILNIQEResult {
  final double qualityScore;
  final String category;
  final double processingTime;
  final bool success;
  final String? error;

  ILNIQEResult({
    required this.qualityScore,
    required this.category,
    required this.processingTime,
    required this.success,
    this.error,
  });

  factory ILNIQEResult.fromJson(Map<String, dynamic> json) {
    return ILNIQEResult(
      qualityScore: json['quality_score']?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Unknown',
      processingTime: json['processing_time']?.toDouble() ?? 0.0,
      success: json['success'] ?? false,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality_score': qualityScore,
      'category': category,
      'processing_time': processingTime,
      'success': success,
      'error': error,
    };
  }
}

/// IL-NIQE Batch Analysis Result
class ILNIQEBatchResult {
  final List<ILNIQEResult> results;
  final ILNIQEBatchSummary summary;
  final bool success;
  final String? error;

  ILNIQEBatchResult({
    required this.results,
    required this.summary,
    required this.success,
    this.error,
  });

  factory ILNIQEBatchResult.fromJson(Map<String, dynamic> json) {
    List<ILNIQEResult> results = [];
    if (json['results'] != null) {
      results = (json['results'] as List)
          .map((item) => ILNIQEResult.fromJson(item))
          .toList();
    }

    return ILNIQEBatchResult(
      results: results,
      summary: ILNIQEBatchSummary.fromJson(json['summary'] ?? {}),
      success: json['success'] ?? false,
      error: json['error'],
    );
  }
}

/// IL-NIQE Batch Analysis Summary
class ILNIQEBatchSummary {
  final int totalImages;
  final int successfulAnalyses;
  final int failedAnalyses;
  final double averageScore;
  final double bestScore;
  final double worstScore;
  final Map<String, int> categoryDistribution;
  final double totalProcessingTime;

  ILNIQEBatchSummary({
    required this.totalImages,
    required this.successfulAnalyses,
    required this.failedAnalyses,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
    required this.categoryDistribution,
    required this.totalProcessingTime,
  });

  factory ILNIQEBatchSummary.fromJson(Map<String, dynamic> json) {
    return ILNIQEBatchSummary(
      totalImages: json['total_images'] ?? 0,
      successfulAnalyses: json['successful_analyses'] ?? 0,
      failedAnalyses: json['failed_analyses'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
      bestScore: (json['best_score'] ?? 0.0).toDouble(),
      worstScore: (json['worst_score'] ?? 0.0).toDouble(),
      categoryDistribution: Map<String, int>.from(json['category_distribution'] ?? {}),
      totalProcessingTime: (json['total_processing_time'] ?? 0.0).toDouble(),
    );
  }
}
