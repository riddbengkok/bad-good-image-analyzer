import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_analyzer/models/photo_model.dart';

class AnalysisCacheService {
  static const String _cacheKey = 'photo_analysis_cache';
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(days: 7);

  static final AnalysisCacheService _instance = AnalysisCacheService._internal();
  factory AnalysisCacheService() => _instance;
  AnalysisCacheService._internal();

  Map<String, CachedAnalysisResult> _memoryCache = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadFromStorage();
      _isInitialized = true;
      print('DEBUG: Analysis cache service initialized');
    } catch (e) {
      print('DEBUG: Error initializing cache service: $e');
    }
  }

  Future<CachedAnalysisResult?> getCachedAnalysis(String photoId) async {
    if (!_isInitialized) await initialize();

    // Check memory cache first
    if (_memoryCache.containsKey(photoId)) {
      final cached = _memoryCache[photoId]!;
      if (!_isExpired(cached)) {
        print('DEBUG: Cache hit for photo $photoId');
        return cached;
      } else {
        // Remove expired entry
        _memoryCache.remove(photoId);
      }
    }

    return null;
  }

  Future<void> cacheAnalysisResult(String photoId, CachedAnalysisResult result) async {
    if (!_isInitialized) await initialize();

    // Add to memory cache
    _memoryCache[photoId] = result;

    // Ensure cache doesn't exceed max size
    if (_memoryCache.length > _maxCacheSize) {
      _cleanupCache();
    }

    // Save to persistent storage
    await _saveToStorage();
    
    print('DEBUG: Cached analysis result for photo $photoId');
  }

  Future<void> cacheBatchResults(Map<String, CachedAnalysisResult> results) async {
    if (!_isInitialized) await initialize();

    // Add all results to memory cache
    _memoryCache.addAll(results);

    // Cleanup if needed
    if (_memoryCache.length > _maxCacheSize) {
      _cleanupCache();
    }

    // Save to persistent storage
    await _saveToStorage();
    
    print('DEBUG: Cached ${results.length} analysis results');
  }

  Future<void> invalidateCache(String photoId) async {
    if (!_isInitialized) await initialize();

    _memoryCache.remove(photoId);
    await _saveToStorage();
    
    print('DEBUG: Invalidated cache for photo $photoId');
  }

  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();

    _memoryCache.clear();
    await _saveToStorage();
    
    print('DEBUG: Cache cleared');
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in _memoryCache.entries) {
      if (_isExpired(entry.value)) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return {
      'total_cached': _memoryCache.length,
      'valid_entries': validCount,
      'expired_entries': expiredCount,
      'memory_usage_mb': _estimateMemoryUsage(),
      'cache_hit_rate': await _calculateCacheHitRate(),
    };
  }

  bool _isExpired(CachedAnalysisResult result) {
    return DateTime.now().difference(result.timestamp) > _cacheExpiry;
  }

  void _cleanupCache() {
    // Remove expired entries first
    final expiredKeys = _memoryCache.keys
        .where((key) => _isExpired(_memoryCache[key]!))
        .toList();
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    // If still over limit, remove oldest entries
    if (_memoryCache.length > _maxCacheSize) {
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = _memoryCache.length - _maxCacheSize;
      for (int i = 0; i < toRemove; i++) {
        _memoryCache.remove(sortedEntries[i].key);
      }
    }

    print('DEBUG: Cache cleaned up. Current size: ${_memoryCache.length}');
  }

  double _estimateMemoryUsage() {
    // Rough estimation of memory usage in MB
    int totalBytes = 0;
    for (final entry in _memoryCache.entries) {
      totalBytes += entry.value.estimatedSize;
    }
    return totalBytes / (1024 * 1024); // Convert to MB
  }

  Future<double> _calculateCacheHitRate() async {
    // This would require tracking cache hits/misses over time
    // For now, return a placeholder
    return 0.0;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = <String, dynamic>{};

      for (final entry in _memoryCache.entries) {
        cacheData[entry.key] = entry.value.toJson();
      }

      final jsonString = jsonEncode(cacheData);
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      print('DEBUG: Error saving cache to storage: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString != null) {
        final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
        
        for (final entry in cacheData.entries) {
          try {
            final result = CachedAnalysisResult.fromJson(entry.value);
            // Only load non-expired entries
            if (!_isExpired(result)) {
              _memoryCache[entry.key] = result;
            }
          } catch (e) {
            print('DEBUG: Error parsing cached result for ${entry.key}: $e');
          }
        }
        
        print('DEBUG: Loaded ${_memoryCache.length} cached results from storage');
      }
    } catch (e) {
      print('DEBUG: Error loading cache from storage: $e');
    }
  }
}

class CachedAnalysisResult {
  final String analysisLevel;
  final double qualityScore;
  final Map<String, dynamic> mlKitResults;
  final Map<String, dynamic> traditionalResults;
  final DateTime timestamp;
  final String analysisMethod;

  CachedAnalysisResult({
    required this.analysisLevel,
    required this.qualityScore,
    required this.mlKitResults,
    required this.traditionalResults,
    required this.timestamp,
    required this.analysisMethod,
  });

  int get estimatedSize {
    // Rough estimation of memory usage
    return analysisLevel.length * 2 + // String
           8 + // double
           mlKitResults.toString().length * 2 + // Map
           traditionalResults.toString().length * 2 + // Map
           8 + // DateTime
           analysisMethod.length * 2; // String
  }

  Map<String, dynamic> toJson() {
    return {
      'analysisLevel': analysisLevel,
      'qualityScore': qualityScore,
      'mlKitResults': mlKitResults,
      'traditionalResults': traditionalResults,
      'timestamp': timestamp.toIso8601String(),
      'analysisMethod': analysisMethod,
    };
  }

  factory CachedAnalysisResult.fromJson(Map<String, dynamic> json) {
    return CachedAnalysisResult(
      analysisLevel: json['analysisLevel'] ?? 'unknown',
      qualityScore: (json['qualityScore'] ?? 0.0).toDouble(),
      mlKitResults: Map<String, dynamic>.from(json['mlKitResults'] ?? {}),
      traditionalResults: Map<String, dynamic>.from(json['traditionalResults'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      analysisMethod: json['analysisMethod'] ?? 'unknown',
    );
  }

  @override
  String toString() {
    return 'CachedAnalysisResult(level: $analysisLevel, score: $qualityScore, method: $analysisMethod)';
  }
}
