// Web-specific photo provider implementation
// This file is used when running on web platform

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_analyzer/models/photo_model.dart';
import 'package:photo_analyzer/utils/constants.dart';

// Mock AssetEntity for web
class MockAssetEntity {
  final String id;
  final String relativePath;
  final DateTime createDateTime;
  final int width;
  final int height;
  final int? fileSize;

  MockAssetEntity({
    required this.id,
    required this.relativePath,
    required this.createDateTime,
    required this.width,
    required this.height,
    this.fileSize,
  });

  Future<Uint8List?> get thumbnailData async {
    // Return null for web demo
    return null;
  }

  Future<bool> delete() async {
    // Mock deletion for web
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

// Web-specific photo provider
class PhotoProvider extends ChangeNotifier {
  List<PhotoModel> _allPhotos = [];
  List<PhotoModel> _badPhotos = [];
  Set<String> _selectedPhotos = {};
  String _currentAnalysisLevel = AnalysisLevel.bad;
  bool _isLoading = false;
  bool _hasPermission = true; // Always true for web
  String? _errorMessage;

  // Getters
  List<PhotoModel> get allPhotos => _allPhotos;
  List<PhotoModel> get badPhotos => _badPhotos;
  String get currentAnalysisLevel => _currentAnalysisLevel;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  int get totalPhotos => _allPhotos.length;
  int get badPhotosCount => _badPhotos.length;
  int get selectedPhotosCount => _selectedPhotos.length;
  int get totalAssetCount => _allPhotos.length;
  int get remainingAssetCount => 0; // No more photos to load in web demo
  bool get hasMorePhotos => false; // Web demo doesn't have infinite photos
  Set<String> get selectedPhotos => _selectedPhotos;

  // Permission handling (always granted for web)
  Future<bool> requestPermission() async {
    _hasPermission = true;
    notifyListeners();
    return true;
  }

  // Load photos from device (mock data for web)
  Future<void> loadPhotos({
    Function(int current, int total)? onLoadingProgress,
    int limit = 300,
  }) async {
    _loadMockPhotos();
  }

  // Load more photos (mock for web)
  Future<void> loadMorePhotos({
    Function(int current, int total)? onLoadingProgress,
    int additionalLimit = 300,
  }) async {
    // For web demo, just add more mock photos
    await Future.delayed(const Duration(milliseconds: 500));
    final additionalPhotos = _generateMockPhotos();
    _allPhotos.addAll(additionalPhotos);
    _updateBadPhotos();
    notifyListeners();
  }

  // Check current permission status (always true for web)
  Future<void> checkCurrentPermissionStatus() async {
    _hasPermission = true;
    notifyListeners();
  }

  // Initialize permission state (always true for web)
  Future<void> initializePermissionState() async {
    _hasPermission = true;
    notifyListeners();
  }

  // Load mock photos for web demo
  void _loadMockPhotos() {
    _setLoading(true);
    
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 2), () {
      _allPhotos = _generateMockPhotos();
      _errorMessage = null;
      _setLoading(false);
    });
  }

  // Generate mock photos for demo
  List<PhotoModel> _generateMockPhotos() {
    final List<PhotoModel> mockPhotos = [];
    final List<String> analysisLevels = [
      AnalysisLevel.bad,
      AnalysisLevel.good,
    ];

    for (int i = 0; i < 50; i++) {
      final analysisLevel = analysisLevels[i % 2];
      final fileSize = 500 * 1024 + (i * 100 * 1024); // 500KB to 5MB
      final width = 800 + (i * 50);
      final height = 600 + (i * 50);
      
      final mockAsset = MockAssetEntity(
        id: 'mock_$i',
        relativePath: '/mock/photo_$i.jpg',
        createDateTime: DateTime.now().subtract(Duration(days: i)),
        width: width,
        height: height,
        fileSize: fileSize,
      );
      
      mockPhotos.add(PhotoModel(
        id: 'mock_$i',
        path: '/mock/photo_$i.jpg',
        createTime: DateTime.now().subtract(Duration(days: i)),
        width: width,
        height: height,
        fileSize: fileSize,
        analysisLevel: analysisLevel,
        qualityScore: -0.5 + (i * 0.02),
        asset: null, // Mock asset for web demo
      ));
    }

    return mockPhotos;
  }

  // Convert AssetEntity to PhotoModel (not used in web)
  PhotoModel _convertToPhotoModel(dynamic asset) {
    return PhotoModel(
      id: asset.id,
      path: asset.relativePath ?? '',
      createTime: asset.createDateTime,
      width: asset.width,
      height: asset.height,
      fileSize: asset.fileSize ?? 0,
      asset: null,
    );
  }

  // Analyze photos based on current level
  Future<void> analyzePhotos() async {
    if (_allPhotos.isEmpty) return;

    _setLoading(true);
    try {
      final List<PhotoModel> analyzedPhotos = [];
      
      for (final photo in _allPhotos) {
        final analysisResult = await _analyzePhoto(photo);
        analyzedPhotos.add(analysisResult);
      }

      _allPhotos = analyzedPhotos;
      _updateBadPhotos();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error analyzing photos: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Batch analysis for web compatibility
  Future<void> analyzePhotosInBatches({
    required Function(int current, int total) onProgress,
    required Function(String message) onStatusUpdate,
    required Function(List<PhotoModel> batchPhotos, int batchNumber, int totalBatches) onBatchComplete,
  }) async {
    if (_allPhotos.isEmpty) return;

    _setLoading(true);
    onStatusUpdate('Starting batch analysis...');

    try {
      final int totalPhotos = _allPhotos.length;
      final int batchSize = 10; // Smaller batches for web demo
      final int totalBatches = (totalPhotos / batchSize).ceil();

      for (int i = 0; i < totalPhotos; i += batchSize) {
        final int endIndex = (i + batchSize < totalPhotos) ? i + batchSize : totalPhotos;
        final int currentBatch = (i ~/ batchSize) + 1;
        
        onStatusUpdate('Analyzing batch $currentBatch of $totalBatches');
        
        final List<PhotoModel> batchPhotos = _allPhotos.sublist(i, endIndex);
        final List<PhotoModel> analyzedBatch = [];

        for (int j = 0; j < batchPhotos.length; j++) {
          final photo = batchPhotos[j];
          final analyzedPhoto = await _analyzePhoto(photo);
          analyzedBatch.add(analyzedPhoto);
          
          onProgress(i + j + 1, totalPhotos);
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Update photos list
        _allPhotos.setRange(i, endIndex, analyzedBatch);
        _updateBadPhotos();
        notifyListeners();

        // Notify batch completion
        onBatchComplete(analyzedBatch, currentBatch, totalBatches);
        
        if (endIndex < totalPhotos) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      onStatusUpdate('Analysis complete!');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error during batch analysis: $e';
      onStatusUpdate('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Continue to next batch
  Future<void> continueToNextBatch({
    required Function(int current, int total) onProgress,
    required Function(String message) onStatusUpdate,
    required Function(List<PhotoModel> batchPhotos, int batchNumber, int totalBatches) onBatchComplete,
  }) async {
    // For web demo, just start a new analysis
    await analyzePhotosInBatches(
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
      onBatchComplete: onBatchComplete,
    );
  }

  // Simple photo analysis algorithm
  Future<PhotoModel> _analyzePhoto(PhotoModel photo) async {
    // Simulate analysis delay
    await Future.delayed(const Duration(milliseconds: 10));
    
    double qualityScore = 0.0;
    String analysisLevel = AnalysisLevel.good;

    // Analyze based on file size (larger files might be better quality)
    if (photo.fileSize > 5 * 1024 * 1024) { // > 5MB
      qualityScore += 0.3;
    } else if (photo.fileSize < 100 * 1024) { // < 100KB
      qualityScore -= 0.3;
    }

    // Analyze based on resolution
    final aspectRatio = photo.width / photo.height;
    if (photo.width >= 1920 && photo.height >= 1080) {
      qualityScore += 0.4;
    } else if (photo.width < 800 || photo.height < 600) {
      qualityScore -= 0.4;
    }

    // Analyze based on aspect ratio (avoid extreme ratios)
    if (aspectRatio < 0.5 || aspectRatio > 2.0) {
      qualityScore -= 0.2;
    }

    // Random factor for demo purposes
    qualityScore += (DateTime.now().millisecondsSinceEpoch % 100 - 50) / 100;

    // Determine analysis level
    if (qualityScore < -0.3) {
      analysisLevel = AnalysisLevel.bad;
    } else if (qualityScore < 0.0) {
      analysisLevel = AnalysisLevel.bad;
    } else {
      analysisLevel = AnalysisLevel.good;
    }

    return photo.copyWith(
      analysisLevel: analysisLevel,
      qualityScore: qualityScore,
    );
  }

  // Update bad photos list based on current analysis level
  // SIMPLIFIED: Only 2 categories - Good vs Bad
  void _updateBadPhotos() {
    _badPhotos = _allPhotos.where((photo) {
      // Simply check if photo is marked as 'bad'
      return photo.analysisLevel == 'bad';
    }).toList();
  }

  // Set analysis level
  void setAnalysisLevel(String level) {
    _currentAnalysisLevel = level;
    _updateBadPhotos();
    _selectedPhotos.clear();
    notifyListeners();
  }

  // Toggle photo selection
  void togglePhotoSelection(String photoId) {
    final photoIndex = _badPhotos.indexWhere((photo) => photo.id == photoId);
    if (photoIndex != -1) {
      final photo = _badPhotos[photoIndex];
      final updatedPhoto = photo.copyWith(isSelected: !photo.isSelected);
      _badPhotos[photoIndex] = updatedPhoto;
      
      if (updatedPhoto.isSelected) {
        _selectedPhotos.add(photoId);
      } else {
        _selectedPhotos.remove(photoId);
      }
      
      notifyListeners();
    }
  }

  // Select all bad photos
  void selectAllBadPhotos() {
    _badPhotos = _badPhotos.map((photo) => photo.copyWith(isSelected: true)).toList();
    _selectedPhotos = _badPhotos.where((photo) => photo.isSelected).map((p) => p.id).toSet();
    notifyListeners();
  }

  // Deselect all photos
  void deselectAllPhotos() {
    _badPhotos = _badPhotos.map((photo) => photo.copyWith(isSelected: false)).toList();
    _selectedPhotos.clear();
    notifyListeners();
  }

  // Delete selected photos (mock for web)
  Future<bool> deleteSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return false;

    _setLoading(true);
    try {
      // For web demo, just remove from lists
      await Future.delayed(const Duration(seconds: 1)); // Simulate deletion

      // Remove deleted photos from lists
      final selectedIds = _selectedPhotos.toSet();
      _allPhotos.removeWhere((photo) => selectedIds.contains(photo.id));
      _badPhotos.removeWhere((photo) => selectedIds.contains(photo.id));
      _selectedPhotos.clear();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting photos: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete all bad photos (mock for web)
  Future<bool> deleteAllBadPhotos() async {
    if (_badPhotos.isEmpty) return false;

    _setLoading(true);
    try {
      // For web demo, just remove from lists
      await Future.delayed(const Duration(seconds: 1)); // Simulate deletion

      // Remove deleted photos from all photos list
      final badPhotoIds = _badPhotos.map((p) => p.id).toSet();
      _allPhotos.removeWhere((photo) => badPhotoIds.contains(photo.id));
      _badPhotos.clear();
      _selectedPhotos.clear();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting photos: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Keep selected photos (mock for web)
  Future<bool> keepSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return false;

    _setLoading(true);
    try {
      // For web demo, just mark as good and remove from bad photos
      final selectedIds = _selectedPhotos.toSet();
      
      for (int i = 0; i < _allPhotos.length; i++) {
        if (selectedIds.contains(_allPhotos[i].id)) {
          _allPhotos[i] = _allPhotos[i].copyWith(
            analysisLevel: 'good',
            qualityScore: 0.8,
          );
        }
      }

      // Remove kept photos from bad photos list
      _badPhotos.removeWhere((photo) => selectedIds.contains(photo.id));
      _selectedPhotos.clear();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error keeping photos: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ML Kit compatibility methods (mock for web)
  bool get useMLKit => false;
  bool get useHybridAnalysis => false;
  bool get useOptimizedAlgorithms => false;

  void toggleMLKit(bool useMLKit) {
    // No-op for web
  }

  void toggleHybridAnalysis(bool useHybrid) {
    // No-op for web
  }

  void toggleOptimizedAlgorithms(bool useOptimized) {
    // No-op for web
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'total_cached': 0,
      'valid_entries': 0,
      'expired_entries': 0,
      'memory_usage_mb': 0.0,
      'cache_hit_rate': 0.0,
    };
  }

  Future<void> clearAnalysisCache() async {
    // No-op for web
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
