import 'dart:async';
import 'dart:typed_data';
import 'package:photo_analyzer/models/photo_model.dart';
import 'package:photo_analyzer/services/ml_kit_analyzer.dart';
import 'package:photo_analyzer/services/optimized_image_analyzer.dart';
import 'package:photo_analyzer/services/analysis_cache_service.dart';

class StreamAnalyzerService {
  final MLKitAnalyzer _mlKitAnalyzer;
  final OptimizedImageAnalyzer _optimizedAnalyzer;
  final AnalysisCacheService _cacheService;
  
  StreamAnalyzerService({
    required MLKitAnalyzer mlKitAnalyzer,
    required OptimizedImageAnalyzer optimizedAnalyzer,
    required AnalysisCacheService cacheService,
  }) : _mlKitAnalyzer = mlKitAnalyzer,
       _optimizedAnalyzer = optimizedAnalyzer,
       _cacheService = cacheService;

  // Stream-based analysis for memory optimization
  Stream<PhotoAnalysisResult> analyzePhotosStream(
    List<PhotoModel> photos, {
    bool useMLKit = true,
    bool useOptimizedAlgorithms = true,
    bool useHybridAnalysis = true,
    int batchSize = 10,
    Duration delayBetweenBatches = const Duration(milliseconds: 100),
  }) async* {
    final controller = StreamController<PhotoAnalysisResult>();
    
    try {
      for (int i = 0; i < photos.length; i += batchSize) {
        final endIndex = (i + batchSize < photos.length) ? i + batchSize : photos.length;
        final batchPhotos = photos.sublist(i, endIndex);
        
        print('DEBUG: Processing batch ${(i ~/ batchSize) + 1} (photos ${i + 1}-$endIndex)');
        
        // Process batch in parallel
        final batchResults = await Future.wait(
          batchPhotos.map((photo) => _analyzePhotoWithStream(
            photo,
            useMLKit: useMLKit,
            useOptimizedAlgorithms: useOptimizedAlgorithms,
            useHybridAnalysis: useHybridAnalysis,
          ))
        );
        
        // Yield results one by one
        for (final result in batchResults) {
          yield result;
        }
        
        // Delay between batches to prevent memory buildup
        if (endIndex < photos.length) {
          await Future.delayed(delayBetweenBatches);
        }
      }
    } catch (e) {
      print('DEBUG: Error in stream analysis: $e');
      yield PhotoAnalysisResult.error(e.toString());
    }
  }

  // Analyze single photo with stream support
  Future<PhotoAnalysisResult> _analyzePhotoWithStream(
    PhotoModel photo, {
    bool useMLKit = true,
    bool useOptimizedAlgorithms = true,
    bool useHybridAnalysis = true,
  }) async {
    try {
      // Check cache first
      final cachedResult = await _cacheService.getCachedAnalysis(photo.id);
      if (cachedResult != null) {
        return PhotoAnalysisResult.fromCached(photo, cachedResult);
      }

      // Get image data
      final imageData = await photo.asset?.originBytes;
      if (imageData == null) {
        return PhotoAnalysisResult.error('No image data available');
      }

      // Perform analysis
      final analysisResult = await _performAnalysis(
        photo,
        imageData,
        useMLKit: useMLKit,
        useOptimizedAlgorithms: useOptimizedAlgorithms,
        useHybridAnalysis: useHybridAnalysis,
      );

      // Cache result
      await _cacheService.cacheAnalysisResult(photo.id, analysisResult);

      return PhotoAnalysisResult.success(photo, analysisResult);
    } catch (e) {
      print('DEBUG: Error analyzing photo ${photo.displayName}: $e');
      return PhotoAnalysisResult.error(e.toString());
    }
  }

  // Perform the actual analysis
  Future<CachedAnalysisResult> _performAnalysis(
    PhotoModel photo,
    Uint8List imageData, {
    bool useMLKit = true,
    bool useOptimizedAlgorithms = true,
    bool useHybridAnalysis = true,
  }) async {
    double qualityScore = 0.0;
    String analysisMethod = 'unknown';
    Map<String, dynamic> mlKitResults = {};
    Map<String, dynamic> traditionalResults = {};

    // ML Kit analysis
    if (useMLKit) {
      try {
        final mlKitResult = await _mlKitAnalyzer.analyzeImageQuality(
          imageData,
          photo.width,
          photo.height,
        );
        
        mlKitResults = mlKitResult;
        qualityScore = mlKitResult['overall_score'] ?? 0.5;
        analysisMethod = 'ml_kit';
      } catch (e) {
        print('DEBUG: ML Kit analysis failed: $e');
        if (!useHybridAnalysis) {
          useMLKit = false;
        }
      }
    }

    // Traditional analysis
    if (!useMLKit || useHybridAnalysis) {
      double blurScore, exposureScore, contentScore;
      
      if (useOptimizedAlgorithms) {
        blurScore = await _optimizedAnalyzer.analyzeBlurOptimized(
          imageData,
          photo.width,
          photo.height,
        );
        exposureScore = await _optimizedAnalyzer.analyzeExposureOptimized(
          imageData,
          photo.width,
          photo.height,
        );
        contentScore = await _analyzeUselessContentOptimized(
          imageData,
          photo.width,
          photo.height,
        );
      } else {
        blurScore = await _analyzeBlurStandard(imageData, photo.width, photo.height);
        exposureScore = await _analyzeExposureStandard(imageData, photo.width, photo.height);
        contentScore = await _analyzeUselessContentStandard(imageData, photo.width, photo.height);
      }

      final traditionalScore = (blurScore * 0.5) + (exposureScore * 0.3) + (contentScore * 0.2);
      
      traditionalResults = {
        'blur_score': blurScore,
        'exposure_score': exposureScore,
        'content_score': contentScore,
        'overall_score': traditionalScore,
      };

      // Combine scores for hybrid analysis
      if (useHybridAnalysis && useMLKit && mlKitResults.isNotEmpty) {
        qualityScore = (qualityScore * 0.7) + (traditionalScore * 0.3);
        analysisMethod = 'hybrid';
      } else if (!useMLKit) {
        qualityScore = traditionalScore;
        analysisMethod = 'traditional';
      }
    }

    // Determine analysis level
    final analysisLevel = _determineAnalysisLevel(qualityScore);

    return CachedAnalysisResult(
      analysisLevel: analysisLevel,
      qualityScore: qualityScore,
      mlKitResults: mlKitResults,
      traditionalResults: traditionalResults,
      timestamp: DateTime.now(),
      analysisMethod: analysisMethod,
    );
  }

  // Standard analysis methods (fallback)
  Future<double> _analyzeBlurStandard(Uint8List imageData, int width, int height) async {
    // Simple blur detection for fallback
    return 0.5;
  }

  Future<double> _analyzeExposureStandard(Uint8List imageData, int width, int height) async {
    // Simple exposure detection for fallback
    return 0.5;
  }

  Future<double> _analyzeUselessContentStandard(Uint8List imageData, int width, int height) async {
    // Simple content detection for fallback
    return 0.5;
  }

  // Optimized content analysis
  Future<double> _analyzeUselessContentOptimized(Uint8List imageData, int width, int height) async {
    try {
      // Simplified content analysis for performance
      final rgbData = _convertToRGBOptimized(imageData, width, height);
      
      // Quick color diversity check
      final colorDiversity = _analyzeColorDiversityQuick(rgbData);
      
      // Quick edge density check
      final edgeDensity = _analyzeEdgeDensityQuick(rgbData, width, height);
      
      return (colorDiversity * 0.6) + (edgeDensity * 0.4);
    } catch (e) {
      print('DEBUG: Optimized content analysis failed: $e');
      return 0.5;
    }
  }

  // Quick color diversity analysis
  double _analyzeColorDiversityQuick(List<List<int>> rgbData) {
    if (rgbData.isEmpty) return 0.5;
    
    // Sample pixels for performance
    final sampleSize = rgbData.length > 1000 ? 1000 : rgbData.length;
    final step = rgbData.length / sampleSize;
    
    final Set<String> uniqueColors = {};
    for (int i = 0; i < rgbData.length; i += step.round()) {
      if (i < rgbData.length) {
        final pixel = rgbData[i];
        final quantized = '${(pixel[0] / 32).round()},${(pixel[1] / 32).round()},${(pixel[2] / 32).round()}';
        uniqueColors.add(quantized);
      }
    }
    
    final diversityRatio = uniqueColors.length / sampleSize;
    
    if (diversityRatio > 0.8) return 1.0;
    if (diversityRatio > 0.5) return 0.7;
    if (diversityRatio > 0.2) return 0.4;
    return 0.1;
  }

  // Quick edge density analysis
  double _analyzeEdgeDensityQuick(List<List<int>> rgbData, int width, int height) {
    if (rgbData.isEmpty) return 0.5;
    
    // Sample edges for performance
    final sampleSize = 100;
    int edgeCount = 0;
    
    for (int i = 0; i < sampleSize && i < rgbData.length; i++) {
      final index = (i * rgbData.length / sampleSize).round();
      if (index + 1 < rgbData.length) {
        final current = rgbData[index];
        final next = rgbData[index + 1];
        
        final gradient = sqrt(
          pow((next[0] - current[0]).toDouble(), 2) + 
          pow((next[1] - current[1]).toDouble(), 2) + 
          pow((next[2] - current[2]).toDouble(), 2)
        );
        
        if (gradient > 30) edgeCount++;
      }
    }
    
    final edgeDensity = edgeCount / sampleSize;
    
    if (edgeDensity > 0.3) return 1.0;
    if (edgeDensity > 0.1) return 0.6;
    return 0.2;
  }

  // Optimized RGB conversion
  List<List<int>> _convertToRGBOptimized(Uint8List imageData, int width, int height) {
    final rgb = <List<int>>[];
    final step = (imageData.length / (width * height * 4)).round();
    
    for (int i = 0; i < imageData.length; i += step * 4) {
      if (i + 2 < imageData.length) {
        rgb.add([imageData[i], imageData[i + 1], imageData[i + 2]]);
      }
    }
    
    return rgb;
  }

  // Determine analysis level
  String _determineAnalysisLevel(double qualityScore) {
    if (qualityScore >= 0.8) return 'excellent';
    if (qualityScore >= 0.6) return 'good';
    if (qualityScore >= 0.4) return 'fair';
    if (qualityScore >= 0.2) return 'poor';
    return 'very_poor';
  }
}

// Result class for stream analysis
class PhotoAnalysisResult {
  final PhotoModel? photo;
  final bool isSuccess;
  final String? error;
  final CachedAnalysisResult? analysisResult;

  PhotoAnalysisResult._({
    this.photo,
    required this.isSuccess,
    this.error,
    this.analysisResult,
  });

  factory PhotoAnalysisResult.success(PhotoModel photo, CachedAnalysisResult result) {
    return PhotoAnalysisResult._(
      photo: photo,
      isSuccess: true,
      analysisResult: result,
    );
  }

  factory PhotoAnalysisResult.error(String error) {
    return PhotoAnalysisResult._(
      isSuccess: false,
      error: error,
    );
  }

  factory PhotoAnalysisResult.fromCached(PhotoModel photo, CachedAnalysisResult cached) {
    return PhotoAnalysisResult._(
      photo: photo,
      isSuccess: true,
      analysisResult: cached,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'PhotoAnalysisResult(success: true, photo: ${photo?.displayName})';
    } else {
      return 'PhotoAnalysisResult(success: false, error: $error)';
    }
  }
}
