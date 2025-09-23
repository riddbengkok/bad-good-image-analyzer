import 'package:flutter/foundation.dart';

class PhotoModel {
  final String id;
  final String path;
  final DateTime createTime;
  final int width;
  final int height;
  final int fileSize;
  final String? title;
  final String? description;
  final String? analysisLevel;
  final double? qualityScore;
  final List<String>? tags;
  final bool isSelected;
  final dynamic? asset;
  
  // New fields for enhanced analysis
  final Map<String, dynamic>? mlKitResults;
  final Map<String, dynamic>? traditionalResults;
  final String? analysisMethod;
  final DateTime? analysisTimestamp;
  final List<String>? qualityIssues;
  final List<String>? detectedLabels;
  final int? faceCount;
  final List<String>? detectedObjects;

  PhotoModel({
    required this.id,
    required this.path,
    required this.createTime,
    required this.width,
    required this.height,
    required this.fileSize,
    this.title,
    this.description,
    this.analysisLevel,
    this.qualityScore,
    this.tags,
    this.isSelected = false,
    this.asset,
    this.mlKitResults,
    this.traditionalResults,
    this.analysisMethod,
    this.analysisTimestamp,
    this.qualityIssues,
    this.detectedLabels,
    this.faceCount,
    this.detectedObjects,
  });

  PhotoModel copyWith({
    String? id,
    String? path,
    DateTime? createTime,
    int? width,
    int? height,
    int? fileSize,
    String? title,
    String? description,
    String? analysisLevel,
    double? qualityScore,
    List<String>? tags,
    bool? isSelected,
    dynamic? asset,
    Map<String, dynamic>? mlKitResults,
    Map<String, dynamic>? traditionalResults,
    String? analysisMethod,
    DateTime? analysisTimestamp,
    List<String>? qualityIssues,
    List<String>? detectedLabels,
    int? faceCount,
    List<String>? detectedObjects,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      path: path ?? this.path,
      createTime: createTime ?? this.createTime,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      title: title ?? this.title,
      description: description ?? this.description,
      analysisLevel: analysisLevel ?? this.analysisLevel,
      qualityScore: qualityScore ?? this.qualityScore,
      tags: tags ?? this.tags,
      isSelected: isSelected ?? this.isSelected,
      asset: asset ?? this.asset,
      mlKitResults: mlKitResults ?? this.mlKitResults,
      traditionalResults: traditionalResults ?? this.traditionalResults,
      analysisMethod: analysisMethod ?? this.analysisMethod,
      analysisTimestamp: analysisTimestamp ?? this.analysisTimestamp,
      qualityIssues: qualityIssues ?? this.qualityIssues,
      detectedLabels: detectedLabels ?? this.detectedLabels,
      faceCount: faceCount ?? this.faceCount,
      detectedObjects: detectedObjects ?? this.detectedObjects,
    );
  }

  bool get isBadPhoto {
    return analysisLevel == 'very_bad' || analysisLevel == 'bad';
  }

  bool get isVeryBadPhoto {
    return analysisLevel == 'very_bad';
  }

  bool get isAnalyzed {
    return analysisLevel != null && qualityScore != null;
  }

  bool get hasMLKitAnalysis {
    return mlKitResults != null && mlKitResults!.isNotEmpty;
  }

  bool get hasTraditionalAnalysis {
    return traditionalResults != null && traditionalResults!.isNotEmpty;
  }

  String get analysisMethodDisplay {
    if (analysisMethod == 'ml_kit') return 'ML Kit';
    if (analysisMethod == 'traditional') return 'Traditional';
    if (analysisMethod == 'hybrid') return 'Hybrid';
    return 'Unknown';
  }

  String get displayName {
    return title ?? 'Photo ${createTime.toString().substring(0, 10)}';
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get qualityScoreFormatted {
    if (qualityScore == null) return 'Not analyzed';
    // IL-NIQE API returns scores in 0-100 range, so we need to convert from 0-1 to 0-100
    return '${(qualityScore! * 100).toStringAsFixed(1)}%';
  }

  String get analysisSummary {
    if (!isAnalyzed) return 'Not analyzed';
    
    final issues = qualityIssues ?? [];
    final labels = detectedLabels ?? [];
    
    String summary = 'Score: $qualityScoreFormatted';
    
    if (issues.isNotEmpty) {
      summary += '\nIssues: ${issues.take(3).join(', ')}';
    }
    
    if (labels.isNotEmpty) {
      summary += '\nLabels: ${labels.take(3).join(', ')}';
    }
    
    if (faceCount != null && faceCount! > 0) {
      summary += '\nFaces: $faceCount';
    }
    
    return summary;
  }

  /// Get IL-NIQE category description if available
  String get ilNiqeCategoryDescription {
    if (traditionalResults != null && traditionalResults!.containsKey('il_niqe_category')) {
      final category = traditionalResults!['il_niqe_category'] as String;
      final score = qualityScore ?? 0.0;
      
      switch (category.toLowerCase()) {
        case 'good':
          return '✅ Excellent quality (Score: ${(score * 100).toStringAsFixed(1)})';
        case 'moderate':
          return '⚠️ Decent quality (Score: ${(score * 100).toStringAsFixed(1)})';
        case 'bad':
          return '❌ Poor quality (Score: ${(score * 100).toStringAsFixed(1)})';
        default:
          return '❓ Unknown quality (Score: ${(score * 100).toStringAsFixed(1)})';
      }
    }
    return 'Not analyzed with IL-NIQE';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PhotoModel(id: $id, path: $path, analysisLevel: $analysisLevel, method: $analysisMethod)';
  }
}
