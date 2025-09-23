// Mobile-specific photo provider implementation
// This file is used when running on iOS/Android platforms

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_analyzer/models/photo_model.dart';
import 'package:photo_analyzer/utils/constants.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:photo_analyzer/services/ml_kit_analyzer.dart';
import 'package:photo_analyzer/services/analysis_cache_service.dart';
import 'package:photo_analyzer/services/il_niqe_service.dart';

// Mobile-specific photo provider
class PhotoProvider extends ChangeNotifier {
  List<PhotoModel> _allPhotos = [];
  List<PhotoModel> _badPhotos = [];
  List<String> _selectedPhotos = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  int _totalAssetCount = 0; // To store the total count of assets found
  
  // ML Kit and caching services
  // late final MLKitAnalyzer _mlKitAnalyzer;
  late final AnalysisCacheService _cacheService;
  bool _useMLKit = false; // Toggle between ML Kit and traditional analysis
  bool _useHybridAnalysis = false; // Use both methods for better accuracy
  bool _useILNIQE = true; // Use IL-NIQE for advanced image quality analysis
  bool _isILNIQEServerHealthy = false; // Track IL-NIQE server status

  PhotoProvider() {
    // _mlKitAnalyzer = MLKitAnalyzer();
    _cacheService = AnalysisCacheService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // await _mlKitAnalyzer.initialize();
      await _cacheService.initialize();
      print('DEBUG: Cache service initialized');
      
      // Set permission as granted by default (bypass mode)
      _hasPermission = true;
      print('DEBUG: Permission set to granted by default (bypass mode)');
      
      // Check IL-NIQE server health asynchronously to avoid blocking app startup
      _checkILNIQEServerHealthAsync();
    } catch (e) {
      print('DEBUG: Error initializing services: $e');
    }
  }

  // Check current permission status
  Future<void> _checkPermissionStatus() async {
    try {
      final status = await Permission.photos.status;
      print('DEBUG: Initial permission status: $status');
      
      // On iOS, check for various permission states
      if (status == PermissionStatus.granted || 
          status == PermissionStatus.limited ||
          status == PermissionStatus.restricted) {
        _hasPermission = true;
        print('DEBUG: Permission granted/limited/restricted - can access photos');
      } else if (status == PermissionStatus.permanentlyDenied) {
        _hasPermission = false;
        print('DEBUG: Permission permanently denied');
      } else {
        _hasPermission = false;
        print('DEBUG: Permission not granted: $status');
      }
    } catch (e) {
      print('DEBUG: Error checking permission status: $e');
      _hasPermission = false;
    }
  }

  // Check IL-NIQE server health asynchronously
  void _checkILNIQEServerHealthAsync() async {
    try {
      _isILNIQEServerHealthy = await ILNIQEService.isServerHealthy();
      print('DEBUG: IL-NIQE server health: $_isILNIQEServerHealthy');
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error checking IL-NIQE server health: $e');
      _isILNIQEServerHealthy = false;
      notifyListeners();
    }
  }

  // Getters
  List<PhotoModel> get allPhotos => _allPhotos;
  List<PhotoModel> get badPhotos => _badPhotos;
  List<String> get selectedPhotos => _selectedPhotos;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  int get totalPhotos => _allPhotos.length;
  int get badPhotosCount => _badPhotos.length;
  int get goodPhotosCount => _allPhotos.length - _badPhotos.length;
  int get totalAssetCount => _totalAssetCount;
  int get remainingAssetCount => _totalAssetCount - _allPhotos.length;
  bool get hasMorePhotos => remainingAssetCount > 0;
  bool get useMLKit => _useMLKit;
  bool get useHybridAnalysis => _useHybridAnalysis;
  bool get useILNIQE => _useILNIQE;
  bool get isILNIQEServerHealthy => _isILNIQEServerHealthy;

  // Request photo library permission with full access
  Future<bool> requestPermission() async {
    try {
      print('DEBUG: Requesting photo library permission...');
      
      // Check current status first
      final currentStatus = await Permission.photos.status;
      print('DEBUG: Current permission status: $currentStatus');
      
      if (currentStatus == PermissionStatus.permanentlyDenied) {
        print('DEBUG: Permission permanently denied, need to open settings');
        _hasPermission = false;
        return false;
      }
      
      // Request permission
      final status = await Permission.photos.request();
      print('DEBUG: Permission status after request: $status');
      
      if (status == PermissionStatus.granted || 
          status == PermissionStatus.limited ||
          status == PermissionStatus.restricted) {
        _hasPermission = true;
        print('DEBUG: Permission granted/limited/restricted');
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        print('DEBUG: Permission permanently denied');
        _hasPermission = false;
        return false;
      } else {
        print('DEBUG: Permission denied');
        _hasPermission = false;
        return false;
      }
    } catch (e) {
      print('DEBUG: Error requesting permission: $e');
      _hasPermission = false;
      return false;
    }
  }

  // Check if we have full access to photo library
  Future<bool> checkFullAccess() async {
    try {
      print('DEBUG: Checking full access...');
      
      // Check if we have permission
      final status = await Permission.photos.status;
      print('DEBUG: Current permission status: $status');
      
      if (status == PermissionStatus.granted || 
          status == PermissionStatus.limited ||
          status == PermissionStatus.restricted) {
        _hasPermission = true;
        print('DEBUG: Full access confirmed - permission granted/limited/restricted');
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        print('DEBUG: Permission permanently denied');
        _hasPermission = false;
        return false;
      } else {
        print('DEBUG: No permission, requesting...');
        return await requestPermission();
      }
    } catch (e) {
      print('DEBUG: Full access check error: $e');
      _hasPermission = false;
      return false;
    }
  }

  // Load photos from device using PhotoKit with limit
  Future<void> loadPhotos({
    Function(int current, int total)? onLoadingProgress,
    int limit = 50,
  }) async {
    print('DEBUG: loadPhotos() called with limit: $limit');
    
    if (!_hasPermission) {
      print('DEBUG: No permission, requesting...');
      final granted = await requestPermission();
      if (!granted) {
        print('DEBUG: Permission denied, cannot load photos');
        return;
      }
    }

    _setLoading(true);
    try {
      print('DEBUG: Getting photo albums...');
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      
      if (albums.isEmpty) {
        print('DEBUG: No albums found');
        return;
      }

      final album = albums.first;
      print('DEBUG: Found album: ${album.name}');
      
      // Get total count first
      _totalAssetCount = await album.assetCountAsync;
      print('DEBUG: Total assets in album: $_totalAssetCount');
      
      // Load photos with limit
      final assets = await album.getAssetListRange(start: 0, end: limit);
      print('DEBUG: Loaded ${assets.length} assets');
      
      _allPhotos = assets.map((asset) => _createPhotoModelFromAsset(asset)).toList();
      
      print('DEBUG: Converted to ${_allPhotos.length} PhotoModel objects');
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading photos: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Continue loading more photos
  Future<void> loadMorePhotos({
    Function(int current, int total)? onLoadingProgress,
    int additionalLimit = 50,
  }) async {
    print('DEBUG: loadMorePhotos() called with additional limit: $additionalLimit');
    
    if (_totalAssetCount == 0) {
      print('DEBUG: No total asset count available');
      return;
    }

    if (_allPhotos.length >= _totalAssetCount) {
      print('DEBUG: All photos already loaded');
      return;
    }

    _setLoading(true);
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      
      if (albums.isEmpty) {
        print('DEBUG: No albums found');
        return;
      }

      final album = albums.first;
      final startIndex = _allPhotos.length;
      final endIndex = (startIndex + additionalLimit).clamp(0, _totalAssetCount);
      
      print('DEBUG: Loading photos from $startIndex to $endIndex');
      
      final assets = await album.getAssetListRange(start: startIndex, end: endIndex);
      print('DEBUG: Loaded ${assets.length} additional assets');
      
      final newPhotos = assets.map((asset) => _createPhotoModelFromAsset(asset)).toList();
      _allPhotos.addAll(newPhotos);
      
      print('DEBUG: Total photos now: ${_allPhotos.length}');
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading more photos: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Analyze a single photo
  Future<PhotoModel> _analyzePhoto(PhotoModel photo) async {
    print('DEBUG: _analyzePhoto() called for photo: ${photo.displayName}');
    
    try {
      // Check cache first (but skip cache for IL-NIQE to see fresh results)
      if (!_useILNIQE) {
        final cachedResult = await _cacheService.getCachedAnalysis(photo.id);
        if (cachedResult != null) {
          print('DEBUG: Using cached analysis for photo ${photo.displayName}');
          return photo.copyWith(
            analysisLevel: cachedResult.analysisLevel,
            qualityScore: cachedResult.qualityScore,
            mlKitResults: cachedResult.mlKitResults,
            traditionalResults: cachedResult.traditionalResults,
            analysisMethod: cachedResult.analysisMethod,
            analysisTimestamp: cachedResult.timestamp,
          );
        }
      } else {
        print('DEBUG: 🔄 Skipping cache for IL-NIQE analysis of ${photo.displayName}');
      }

      print('DEBUG: Getting image data for analysis...');
      final imageData = await photo.asset!.originBytes;
      if (imageData == null) {
        print('DEBUG: Could not get image data for ${photo.displayName}');
        return photo.copyWith(
          analysisLevel: AnalysisLevel.bad,
          qualityScore: 0.0,
          analysisMethod: 'failed',
          analysisTimestamp: DateTime.now(),
        );
      }
      
      print('DEBUG: Got image data, analyzing...');
      
      double qualityScore = 0.0;
      String analysisMethod = 'failed';
      Map<String, dynamic> traditionalResults = {};

      // IL-NIQE Analysis (if enabled and server is healthy)
      double ilNiqeScore = 0.0;
      String ilNiqeCategory = 'Unknown';
      if (_useILNIQE && photo.asset != null) {
        try {
          // Check server health first
          final isServerHealthy = await ILNIQEService.isServerHealthy();
          if (isServerHealthy) {
            print('DEBUG: 🚀 Running IL-NIQE analysis for ${photo.displayName}...');
            final ilNiqeResult = await ILNIQEService.analyzeSingleImage(photo.asset!);
            
            if (ilNiqeResult.success) {
              ilNiqeScore = ilNiqeResult.qualityScore;
              ilNiqeCategory = ilNiqeResult.category;
              
              // Use IL-NIQE as primary analysis method
              // IL-NIQE returns scores as percentages (0-100), convert to decimal (0-1) for consistency
              qualityScore = ilNiqeScore / 100.0;
              analysisMethod = 'il_niqe';
              
              // Add IL-NIQE results to traditional results
              traditionalResults = {
                'il_niqe_score': ilNiqeScore,
                'il_niqe_category': ilNiqeCategory,
                'il_niqe_processing_time': ilNiqeResult.processingTime,
                'il_niqe_timestamp': DateTime.now().millisecondsSinceEpoch,
              };
              
              print('DEBUG: ✅ IL-NIQE analysis complete - Raw Score: ${ilNiqeScore.toStringAsFixed(2)}, Converted Score: ${qualityScore.toStringAsFixed(2)}, Category: $ilNiqeCategory');
            } else {
              print('DEBUG: ❌ IL-NIQE analysis failed: ${ilNiqeResult.error}');
              // Fall back to traditional analysis
              qualityScore = 0.0;
              analysisMethod = 'failed';
              traditionalResults = {
                'il_niqe_error': ilNiqeResult.error,
                'fallback_used': 'traditional',
              };
            }
          } else {
            print('DEBUG: 🏥 IL-NIQE server not healthy, using traditional analysis');
            qualityScore = 0.0;
            analysisMethod = 'failed';
            traditionalResults = {
              'il_niqe_server_unhealthy': true,
              'fallback_used': 'traditional',
            };
          }
        } catch (e) {
          print('DEBUG: 💥 IL-NIQE analysis exception: $e');
          print('DEBUG: 📍 Exception type: ${e.runtimeType}');
          print('DEBUG: ❌ IL-NIQE analysis failed: $e');
          qualityScore = 0.0;
          analysisMethod = 'failed';
          traditionalResults = {
            'il_niqe_exception': e.toString(),
            'fallback_used': 'traditional',
          };
        }
      } else {
        // No traditional analysis - IL-NIQE only
        print('DEBUG: IL-NIQE failed, no fallback analysis available');
        qualityScore = 0.0;
        analysisMethod = 'failed';
        traditionalResults = {
          'error': 'IL-NIQE analysis failed and no traditional analysis available',
        };
      }

              // Determine analysis level based on IL-NIQE category or quality score
        String analysisLevel;
        if (analysisMethod == 'il_niqe' && traditionalResults.containsKey('il_niqe_category')) {
          // Use IL-NIQE category directly based on new API specification
          final ilNiqeCategory = traditionalResults['il_niqe_category'] as String;
          if (ilNiqeCategory.toLowerCase() == 'good') {
            analysisLevel = AnalysisLevel.good;
          } else {
            // Both "Moderate" and "Bad" are considered "bad" for our app
            analysisLevel = AnalysisLevel.bad;
          }
          print('DEBUG: Using IL-NIQE category: $ilNiqeCategory -> $analysisLevel');
        } else {
          // Fallback to quality score threshold based on new API specification
          // Good: Score ≥ 60, Moderate: Score 30-59, Bad: Score < 30
          if (qualityScore >= 0.6) { // 60/100 = 0.6
            analysisLevel = AnalysisLevel.good;
          } else {
            analysisLevel = AnalysisLevel.bad;
          }
          print('DEBUG: Using quality score threshold: $qualityScore -> $analysisLevel');
        }

      final analyzedPhoto = photo.copyWith(
        analysisLevel: analysisLevel,
        qualityScore: qualityScore,
        traditionalResults: traditionalResults,
        analysisMethod: analysisMethod,
        analysisTimestamp: DateTime.now(),
      );

      // Cache the result
      final cachedResult = CachedAnalysisResult(
        analysisLevel: analyzedPhoto.analysisLevel ?? AnalysisLevel.bad,
        qualityScore: analyzedPhoto.qualityScore ?? 0.0,
        mlKitResults: analyzedPhoto.mlKitResults ?? {},
        traditionalResults: analyzedPhoto.traditionalResults ?? {},
        analysisMethod: analyzedPhoto.analysisMethod ?? 'unknown',
        timestamp: analyzedPhoto.analysisTimestamp ?? DateTime.now(),
      );
      await _cacheService.cacheAnalysisResult(analyzedPhoto.id, cachedResult);
      print('DEBUG: Cached analysis result for photo ${photo.id}');
      print('DEBUG: Analysis complete - Method: $analysisMethod, Score: ${qualityScore.toStringAsFixed(2)}, Level: $analysisLevel');

      return analyzedPhoto;
      } catch (e) {
      print('DEBUG: Error analyzing photo ${photo.displayName}: $e');
      return photo.copyWith(
        analysisLevel: AnalysisLevel.bad,
        qualityScore: 0.0,
        analysisMethod: 'error',
        analysisTimestamp: DateTime.now(),
      );
    }
  }

  // Analyze all photos
  Future<void> analyzeAllPhotos({
    Function(int current, int total)? onProgress,
    Function(String message)? onStatusUpdate,
  }) async {
    if (_allPhotos.isEmpty) {
      print('DEBUG: No photos to analyze');
      return;
    }

    _setLoading(true);
    onStatusUpdate?.call('Starting analysis...');

    try {
      final totalPhotos = _allPhotos.length;
      print('DEBUG: Analyzing $totalPhotos photos...');

      for (int i = 0; i < totalPhotos; i++) {
        final photo = _allPhotos[i];
        print('DEBUG: Analyzing photo ${i + 1} of $totalPhotos: ${photo.displayName}');
        
        onStatusUpdate?.call('Analyzing photo ${i + 1} of $totalPhotos...');
        onProgress?.call(i + 1, totalPhotos);

          final analyzedPhoto = await _analyzePhoto(photo);
        _allPhotos[i] = analyzedPhoto;
        
        // Update bad photos list
        if (analyzedPhoto.analysisLevel == AnalysisLevel.bad) {
          final existingIndex = _badPhotos.indexWhere((p) => p.id == analyzedPhoto.id);
          if (existingIndex == -1) {
            _badPhotos.add(analyzedPhoto);
          } else {
            _badPhotos[existingIndex] = analyzedPhoto;
          }
        }
        
        // Notify listeners of progress update
      notifyListeners();
      }

      print('DEBUG: Analysis complete. Found ${_badPhotos.length} bad photos out of $totalPhotos total photos');
      onStatusUpdate?.call('Analysis complete!');
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error during analysis: $e');
      onStatusUpdate?.call('Analysis failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Batch analysis with user review (50 photos per batch)
  Future<void> analyzePhotosInBatches({
    required Function(int current, int total) onProgress,
    required Function(String message) onStatusUpdate,
    required Function(List<PhotoModel> batchPhotos, int batchNumber, int totalBatches) onBatchComplete,
  }) async {
    print('DEBUG: analyzePhotosInBatches() called');
    
    if (_allPhotos.isEmpty) {
      print('DEBUG: No photos to analyze');
      onStatusUpdate('No photos to analyze');
      return;
    }

    _setLoading(true);
    onStatusUpdate('Starting batch analysis...');

    try {
      final int totalPhotos = _allPhotos.length;
      final int batchSize = 50; // 50 photos per batch
      final int totalBatches = (totalPhotos / batchSize).ceil();
      
      // Find the next batch to process (skip already analyzed photos)
      int nextBatch = 1;
      int startIndex = 0;
      
      // Find first unanalyzed photo
      for (int i = 0; i < _allPhotos.length; i++) {
        if (!_allPhotos[i].isAnalyzed) {
          startIndex = i;
          nextBatch = (i / batchSize).floor() + 1;
          break;
        }
      }
      
      if (startIndex >= _allPhotos.length) {
        onStatusUpdate('All photos have been analyzed!');
        _setLoading(false);
        return;
      }
      
      final endIndex = (startIndex + batchSize).clamp(0, totalPhotos);
      final batchPhotos = _allPhotos.sublist(startIndex, endIndex);
      
      onStatusUpdate('Processing batch $nextBatch of $totalBatches...');
      onProgress(startIndex, totalPhotos);
      
      // Analyze batch photos
        for (int i = 0; i < batchPhotos.length; i++) {
          final photo = batchPhotos[i];
          final currentPhotoNumber = startIndex + i + 1;
          print('DEBUG: Analyzing photo $currentPhotoNumber of $totalPhotos: ${photo.displayName}');
          
          onStatusUpdate('Analyzing photo $currentPhotoNumber of $totalPhotos...');
          final analyzedPhoto = await _analyzePhoto(photo);
          batchPhotos[i] = analyzedPhoto;
        
          // Update in main list
          _allPhotos[startIndex + i] = analyzedPhoto;
        
          // Update bad photos list
          if (analyzedPhoto.analysisLevel == AnalysisLevel.bad) {
            final existingIndex = _badPhotos.indexWhere((p) => p.id == analyzedPhoto.id);
            if (existingIndex == -1) {
              _badPhotos.add(analyzedPhoto);
            } else {
              _badPhotos[existingIndex] = analyzedPhoto;
            }
          } else {
            _badPhotos.removeWhere((p) => p.id == analyzedPhoto.id);
          }
        
          // Update progress after each photo
          onProgress(currentPhotoNumber, totalPhotos);
        notifyListeners();
        }

        print('DEBUG: Batch $nextBatch analysis complete');
      onBatchComplete(batchPhotos, nextBatch, totalBatches);
      
    } catch (e) {
      print('DEBUG: Error in batch analysis: $e');
      onStatusUpdate('Batch analysis failed: $e');
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
    print('DEBUG: continueToNextBatch() called');
    
    _setLoading(true);
    
    try {
      // Check if we need to load more photos
      final int currentPhotoCount = _allPhotos.length;
      final int analyzedCount = _allPhotos.where((p) => p.isAnalyzed).length;
      
      print('DEBUG: Current photos: $currentPhotoCount, Analyzed: $analyzedCount');
      
      // If we've analyzed most of our current photos, load more
      if (analyzedCount >= currentPhotoCount - 10 && _totalAssetCount > currentPhotoCount) {
        onStatusUpdate('Loading more photos...');
        await loadMorePhotos(additionalLimit: 50);
        print('DEBUG: Loaded more photos, now have ${_allPhotos.length} total');
      }
    
    final int totalPhotos = _allPhotos.length;
      final int batchSize = 50;
    final int totalBatches = (totalPhotos / batchSize).ceil();
    
    // Find the next batch to process
    int nextBatch = 1;
    int startIndex = 0;
    
      // Find first unanalyzed photo
      for (int i = 0; i < _allPhotos.length; i++) {
        if (!_allPhotos[i].isAnalyzed) {
        startIndex = i;
          nextBatch = (i / batchSize).floor() + 1;
        break;
      }
    }
    
      if (startIndex >= _allPhotos.length) {
        onStatusUpdate('All photos have been analyzed!');
        _setLoading(false);
        return;
      }
      
      final endIndex = (startIndex + batchSize).clamp(0, totalPhotos);
      final batchPhotos = _allPhotos.sublist(startIndex, endIndex);
      
      onStatusUpdate('Processing batch $nextBatch of $totalBatches...');
      onProgress(startIndex, totalPhotos);
      
      // Analyze batch photos
      for (int i = 0; i < batchPhotos.length; i++) {
        final photo = batchPhotos[i];
        final currentPhotoNumber = startIndex + i + 1;
        print('DEBUG: Analyzing photo $currentPhotoNumber of $totalPhotos: ${photo.displayName}');
        
        onStatusUpdate('Analyzing photo $currentPhotoNumber of $totalPhotos...');
        final analyzedPhoto = await _analyzePhoto(photo);
        batchPhotos[i] = analyzedPhoto;
        
        // Update in main list
        _allPhotos[startIndex + i] = analyzedPhoto;
        
        // Update bad photos list
        if (analyzedPhoto.analysisLevel == AnalysisLevel.bad) {
          final existingIndex = _badPhotos.indexWhere((p) => p.id == analyzedPhoto.id);
          if (existingIndex == -1) {
            _badPhotos.add(analyzedPhoto);
      } else {
            _badPhotos[existingIndex] = analyzedPhoto;
          }
        } else {
          _badPhotos.removeWhere((p) => p.id == analyzedPhoto.id);
        }
        
        // Update progress after each photo
        onProgress(currentPhotoNumber, totalPhotos);
        notifyListeners();
      }
      
      print('DEBUG: Batch $nextBatch analysis complete');
      onBatchComplete(batchPhotos, nextBatch, totalBatches);
    } catch (e) {
      print('DEBUG: Error in continueToNextBatch: $e');
      onStatusUpdate('Error processing batch: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Toggle ML Kit usage
  void toggleMLKit(bool useMLKit) {
    _useMLKit = useMLKit;
    notifyListeners();
  }

  // Toggle hybrid analysis
  void toggleHybridAnalysis(bool useHybrid) {
    _useHybridAnalysis = useHybrid;
    notifyListeners();
  }

  // Toggle IL-NIQE usage
  void toggleILNIQE(bool useILNIQE) {
    _useILNIQE = useILNIQE;
    print('DEBUG: IL-NIQE toggled to: $useILNIQE');
    notifyListeners();
  }

  // Clear analysis cache to force fresh analysis
  Future<void> clearAnalysisCache() async {
    try {
      await _cacheService.clearCache();
      // Reset all photos to unanalyzed state
      for (int i = 0; i < _allPhotos.length; i++) {
        _allPhotos[i] = _allPhotos[i].copyWith(
          analysisLevel: null,
          qualityScore: null,
          analysisMethod: null,
          analysisTimestamp: null,
          traditionalResults: null,
        );
      }
      _badPhotos.clear();
      print('DEBUG: 🗑️ Analysis cache cleared and photos reset');
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error clearing cache: $e');
    }
  }

  // Check IL-NIQE server health
  Future<void> checkILNIQEServerHealth() async {
    _isILNIQEServerHealthy = await ILNIQEService.isServerHealthy();
    notifyListeners();
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
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

  // Select all photos
  void selectAllPhotos() {
    _selectedPhotos.clear();
    for (final photo in _badPhotos) {
      _selectedPhotos.add(photo.id);
      final photoIndex = _badPhotos.indexWhere((p) => p.id == photo.id);
      if (photoIndex != -1) {
        _badPhotos[photoIndex] = photo.copyWith(isSelected: true);
      }
    }
    notifyListeners();
  }

  // Deselect all photos
  void deselectAllPhotos() {
    _selectedPhotos.clear();
    for (int i = 0; i < _badPhotos.length; i++) {
      _badPhotos[i] = _badPhotos[i].copyWith(isSelected: false);
    }
    notifyListeners();
  }

  // Delete selected photos
  Future<void> deleteSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return;
    
    try {
      print('DEBUG: Starting deletion of ${_selectedPhotos.length} photos');
      
      // Check if we have permission to delete photos
      final permission = await PhotoManager.requestPermissionExtend();
      print('DEBUG: Current permission: $permission');
      
      if (permission != PermissionState.authorized) {
        print('DEBUG: Permission not granted for deletion');
        throw Exception('Permission not granted to delete photos. Please grant full access to photo library in Settings.');
      }
      
      // Get the assets to delete
      final assetsToDelete = <AssetEntity>[];
      for (final photoId in _selectedPhotos) {
        final photo = _badPhotos.firstWhere((p) => p.id == photoId);
        if (photo.asset != null) {
          assetsToDelete.add(photo.asset!);
          print('DEBUG: Adding asset to delete: ${photo.asset!.id}');
        }
      }
      
      if (assetsToDelete.isNotEmpty) {
        // Use PhotoManager to delete assets
        final deleteResult = await PhotoManager.editor.deleteWithIds(
          assetsToDelete.map((asset) => asset.id).toList(),
        );
        
        print('DEBUG: Delete result: $deleteResult');
        
        if (deleteResult.isNotEmpty) {
          // Remove deleted photos from lists
          _badPhotos.removeWhere((photo) => _selectedPhotos.contains(photo.id));
          _allPhotos.removeWhere((photo) => _selectedPhotos.contains(photo.id));
          
          _selectedPhotos.clear();
          notifyListeners();
          
          print('DEBUG: Successfully deleted ${deleteResult.length} photos');
    } else {
          print('DEBUG: No photos were actually deleted');
          throw Exception('Failed to delete photos from device. Please check your photo library permissions.');
        }
      }
    } catch (e) {
      print('DEBUG: Error deleting photos: $e');
      // Still remove from app lists even if device deletion fails
      _badPhotos.removeWhere((photo) => _selectedPhotos.contains(photo.id));
      _allPhotos.removeWhere((photo) => _selectedPhotos.contains(photo.id));
    _selectedPhotos.clear();
    notifyListeners();
      rethrow;
    }
  }

  // Create PhotoModel from AssetEntity
  PhotoModel _createPhotoModelFromAsset(AssetEntity asset) {
    return PhotoModel(
      id: asset.id,
      path: asset.relativePath ?? '',
      createTime: asset.createDateTime,
      width: asset.width,
      height: asset.height,
      fileSize: asset.size is int ? asset.size as int : 0,
      title: asset.title,
      asset: asset,
    );
  }

  // Missing methods for UI compatibility
  Future<void> checkCurrentPermissionStatus() async {
    await _checkPermissionStatus();
    notifyListeners();
  }

  // Refresh permission status
  Future<void> refreshPermissionStatus() async {
    await _checkPermissionStatus();
    notifyListeners();
  }

  String get currentAnalysisLevel => AnalysisLevel.good;
  
  void setAnalysisLevel(String level) {
    // Not used in IL-NIQE only mode
  }

  String? get errorMessage => null;
  
  void clearError() {
    // Not used in IL-NIQE only mode
  }

  Future<bool> deleteAllBadPhotos() async {
    try {
      for (final photo in _badPhotos) {
          if (photo.asset != null) {
              await photo.asset!.delete();
          }
        }
      _badPhotos.clear();
      _allPhotos.removeWhere((photo) => photo.analysisLevel == AnalysisLevel.bad);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting all bad photos: $e');
      return false;
    }
  }

  int get selectedPhotosCount => _selectedPhotos.length;

  void selectAllBadPhotos() {
    selectAllPhotos();
  }

  // Open app settings for permission management
  Future<void> openAppSettings() async {
    try {
      print('DEBUG: Opening app settings...');
      await Permission.photos.request();
      // If still denied, open settings
      final status = await Permission.photos.status;
      print('DEBUG: Permission status after request: $status');
      
      if (status == PermissionStatus.permanentlyDenied) {
        print('DEBUG: Opening system settings...');
        await openAppSettings();
      }
    } catch (e) {
      print('DEBUG: Error opening app settings: $e');
    }
  }

  // Open iOS app settings directly
  Future<void> openIOSAppSettings() async {
    try {
      print('DEBUG: Opening iOS app settings...');
      await openAppSettings();
    } catch (e) {
      print('DEBUG: Error opening iOS app settings: $e');
    }
  }

  // Force refresh permission status
  Future<void> forceRefreshPermission() async {
    try {
      print('DEBUG: Force refreshing permission status...');
      final status = await Permission.photos.status;
      print('DEBUG: Force refresh - permission status: $status');
      
      if (status == PermissionStatus.granted || 
          status == PermissionStatus.limited ||
          status == PermissionStatus.restricted) {
        _hasPermission = true;
        print('DEBUG: Permission is now granted/limited/restricted!');
      } else {
        _hasPermission = false;
        print('DEBUG: Permission still not granted: $status');
      }
      
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error force refreshing permission: $e');
    }
  }

  // Check if permission is permanently denied
  bool get isPermissionPermanentlyDenied {
    return _hasPermission == false; // This will be updated based on permission status
  }

  // Temporary method to bypass permission check for testing
  Future<void> bypassPermissionCheck() async {
    print('DEBUG: Bypassing permission check for testing...');
    _hasPermission = true;
    notifyListeners();
    
    // Try to load photos
    await loadPhotos();
  }
}
