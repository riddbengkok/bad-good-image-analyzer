import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class MLKitAnalyzer {
  static final MLKitAnalyzer _instance = MLKitAnalyzer._internal();
  factory MLKitAnalyzer() => _instance;
  MLKitAnalyzer._internal();

  late final ImageLabeler _imageLabeler;
  late final FaceDetector _faceDetector;
  late final ObjectDetector _objectDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _imageLabeler = GoogleMlKit.vision.imageLabeler();
      _faceDetector = GoogleMlKit.vision.faceDetector();
      _objectDetector = GoogleMlKit.vision.objectDetector();
      _isInitialized = true;
      print('DEBUG: ML Kit initialized successfully');
    } catch (e) {
      print('DEBUG: Error initializing ML Kit: $e');
      _isInitialized = false;
    }
  }

  Future<Map<String, dynamic>> analyzeImageQuality(Uint8List imageData, int width, int height) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final results = await Future.wait([
        _analyzeWithImageLabeler(imageData, width, height),
        _analyzeWithFaceDetector(imageData, width, height),
        _analyzeWithObjectDetector(imageData, width, height),
      ]);

      final imageLabels = results[0] as Map<String, dynamic>;
      final faceAnalysis = results[1] as Map<String, dynamic>;
      final objectAnalysis = results[2] as Map<String, dynamic>;

      // Combine all analysis results
      final combinedScore = _calculateCombinedScore(
        imageLabels['score'] ?? 0.0,
        faceAnalysis['score'] ?? 0.0,
        objectAnalysis['score'] ?? 0.0,
      );

      return {
        'overall_score': combinedScore,
        'image_labels': imageLabels,
        'face_analysis': faceAnalysis,
        'object_analysis': objectAnalysis,
        'analysis_method': 'ml_kit',
      };
    } catch (e) {
      print('DEBUG: Error in ML Kit analysis: $e');
      return {
        'overall_score': 0.5,
        'error': e.toString(),
        'analysis_method': 'ml_kit_failed',
      };
    }
  }

  Future<Map<String, dynamic>> _analyzeWithImageLabeler(Uint8List imageData, int width, int height) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageData,
        metadata: InputImageMetadata(
          size: ui.Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);
      
      double qualityScore = 0.5; // Base score
      List<String> detectedLabels = [];
      List<String> qualityIssues = [];

      for (ImageLabel label in labels) {
        detectedLabels.add('${label.label} (${(label.confidence * 100).toStringAsFixed(1)}%)');
        
        final text = label.label.toLowerCase();
        final confidence = label.confidence;

        // Analyze labels for quality assessment
        if (confidence > 0.7) {
          if (text.contains('blur') || text.contains('blurry')) {
            qualityScore -= 0.3;
            qualityIssues.add('Blurry image detected');
          } else if (text.contains('dark') || text.contains('night')) {
            qualityScore -= 0.2;
            qualityIssues.add('Dark image detected');
          } else if (text.contains('bright') || text.contains('overexposed')) {
            qualityScore -= 0.2;
            qualityIssues.add('Overexposed image detected');
          } else if (text.contains('person') || text.contains('face')) {
            qualityScore += 0.1; // People photos are usually valuable
          } else if (text.contains('landscape') || text.contains('nature')) {
            qualityScore += 0.1; // Nature photos are usually valuable
          }
        }
      }

      // Ensure score is between 0 and 1
      qualityScore = qualityScore.clamp(0.0, 1.0);

      return {
        'score': qualityScore,
        'labels': detectedLabels,
        'quality_issues': qualityIssues,
        'confidence': labels.isNotEmpty ? labels.map((l) => l.confidence).reduce((a, b) => a + b) / labels.length : 0.0,
      };
    } catch (e) {
      print('DEBUG: Error in image labeler analysis: $e');
      return {'score': 0.5, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _analyzeWithFaceDetector(Uint8List imageData, int width, int height) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageData,
        metadata: InputImageMetadata(
          size: ui.Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);
      
      double faceScore = 0.5;
      List<String> faceDetails = [];

      if (faces.isNotEmpty) {
        // Multiple faces might indicate group photos (valuable)
        if (faces.length > 1) {
          faceScore += 0.2;
          faceDetails.add('Group photo detected (${faces.length} people)');
        } else {
          faceScore += 0.1;
          faceDetails.add('Single person detected');
        }

        // Analyze face quality
        for (Face face in faces) {
          if (face.trackingId != null) {
            faceDetails.add('Face ID: ${face.trackingId}');
          }
          
          // Check if face is well-positioned
          if (face.boundingBox.width > width * 0.1 && face.boundingBox.height > height * 0.1) {
            faceScore += 0.1; // Face is reasonably sized
            faceDetails.add('Well-sized face');
          }
        }
      } else {
        faceDetails.add('No faces detected');
      }

      return {
        'score': faceScore.clamp(0.0, 1.0),
        'face_count': faces.length,
        'face_details': faceDetails,
      };
    } catch (e) {
      print('DEBUG: Error in face detector analysis: $e');
      return {'score': 0.5, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _analyzeWithObjectDetector(Uint8List imageData, int width, int height) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageData,
        metadata: InputImageMetadata(
          size: ui.Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);
      
      double objectScore = 0.5;
      List<String> objectDetails = [];
      Set<String> uniqueObjects = {};

      for (DetectedObject object in objects) {
        final labels = object.labels;
        for (final label in labels) {
          uniqueObjects.add(label.text);
          
          // Score based on object type
          final text = label.text.toLowerCase();
          if (text.contains('phone') || text.contains('screen') || text.contains('document')) {
            objectScore -= 0.2; // Screenshots/documents are less valuable
            objectDetails.add('Screenshot/document detected: ${label.text}');
          } else if (text.contains('person') || text.contains('car') || text.contains('building')) {
            objectScore += 0.1; // Real-world objects are valuable
            objectDetails.add('Valuable object: ${label.text}');
          }
        }
      }

      if (uniqueObjects.isEmpty) {
        objectDetails.add('No objects detected');
      }

      return {
        'score': objectScore.clamp(0.0, 1.0),
        'object_count': objects.length,
        'unique_objects': uniqueObjects.toList(),
        'object_details': objectDetails,
      };
    } catch (e) {
      print('DEBUG: Error in object detector analysis: $e');
      return {'score': 0.5, 'error': e.toString()};
    }
  }

  double _calculateCombinedScore(double labelScore, double faceScore, double objectScore) {
    // Weighted combination of all analysis methods
    // Image labels: 50%, Face detection: 30%, Object detection: 20%
    final combinedScore = (labelScore * 0.5) + (faceScore * 0.3) + (objectScore * 0.2);
    return combinedScore.clamp(0.0, 1.0);
  }

  void dispose() {
    _imageLabeler.close();
    _faceDetector.close();
    _objectDetector.close();
    _isInitialized = false;
  }
}
