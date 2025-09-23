import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_analyzer/providers/photo_provider.dart';
import 'package:photo_analyzer/utils/constants.dart';
import 'package:photo_analyzer/widgets/photo_grid.dart';
import 'package:photo_analyzer/widgets/gradient_button.dart';
import 'package:photo_analyzer/models/photo_model.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Progress tracking
  int _currentProgress = 0;
  int _totalPhotos = 0;
  String _statusMessage = 'Preparing analysis...';
  bool _isAnalyzing = false;
  
  // Batch tracking
  List<PhotoModel> _currentBatch = [];
  int _currentBatchNumber = 0;
  int _totalBatches = 0;
  bool _showBatchReview = false;
  
  // Loading tracking
  int _loadingProgress = 0;
  int _totalAssets = 0;
  bool _isLoadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Start analysis when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen to PhotoProvider changes for real-time updates
      final photoProvider = context.read<PhotoProvider>();
      photoProvider.addListener(_onPhotoProviderChanged);
      _startAnalysis();
    });
  }

  void _onPhotoProviderChanged() {
    if (mounted) {
      setState(() {
        // Update progress based on current state
        final photoProvider = context.read<PhotoProvider>();
        _currentProgress = photoProvider.allPhotos.where((p) => p.isAnalyzed).length;
        _totalPhotos = photoProvider.totalPhotos;
      });
    }
  }

  @override
  void dispose() {
    final photoProvider = context.read<PhotoProvider>();
    photoProvider.removeListener(_onPhotoProviderChanged);
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final photoProvider = context.read<PhotoProvider>();
    
    if (photoProvider.totalPhotos == 0) {
      setState(() {
        _isLoadingPhotos = true;
        _statusMessage = 'Loading photos...';
      });
      await photoProvider.loadPhotos(
        limit: 50, // Start with 50 photos
        onLoadingProgress: (current, total) {
          setState(() {
            _loadingProgress = current;
            _totalAssets = total;
            _statusMessage = 'Loading thumbnail $current of $total...';
          });
        },
      );
      setState(() {
        _isLoadingPhotos = false;
      });
    }

    if (photoProvider.totalPhotos > 0) {
      setState(() {
        _isAnalyzing = true;
        _totalPhotos = photoProvider.totalPhotos;
        _currentProgress = 0;
        _statusMessage = 'Starting analysis...';
        _showBatchReview = false;
      });
      
      _progressController.forward();
      
      // Start batch analysis
      await photoProvider.analyzePhotosInBatches(
        onProgress: (current, total) {
          setState(() {
            _currentProgress = current;
            _totalPhotos = total;
          });
        },
        onStatusUpdate: (message) {
          if (mounted) {
            setState(() {
              _statusMessage = message;
            });
          }
        },
        onBatchComplete: (batchPhotos, batchNumber, totalBatches) {
          if (mounted) {
            setState(() {
              _currentBatch = batchPhotos;
              _currentBatchNumber = batchNumber;
              _totalBatches = totalBatches;
              _showBatchReview = true;
              _isAnalyzing = false;
            });
          }
        },
      );
    }
  }

  // Load more photos
  Future<void> _loadMorePhotos() async {
    final photoProvider = context.read<PhotoProvider>();
    
    setState(() {
      _isLoadingPhotos = true;
      _statusMessage = 'Loading more photos...';
    });
    
    await photoProvider.loadMorePhotos(
      additionalLimit: 50, // Load 50 more photos
      onLoadingProgress: (current, total) {
        setState(() {
          _loadingProgress = current;
          _totalAssets = total;
          _statusMessage = 'Loading thumbnail $current of $total...';
        });
      },
    );
    
    setState(() {
      _isLoadingPhotos = false;
    });
  }

  // Manual analysis trigger
  Future<void> _startManualAnalysis() async {
    final photoProvider = context.read<PhotoProvider>();
    
    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Loading photos...';
      _showBatchReview = false;
    });
    
    // First ensure photos are loaded
    if (photoProvider.totalPhotos == 0) {
      setState(() {
        _isLoadingPhotos = true;
      });
      await photoProvider.loadPhotos(
        onLoadingProgress: (current, total) {
          setState(() {
            _loadingProgress = current;
            _totalAssets = total;
            _statusMessage = 'Loading thumbnail $current of $total...';
          });
        },
      );
      setState(() {
        _isLoadingPhotos = false;
      });
    }

    if (photoProvider.totalPhotos > 0) {
      setState(() {
        _totalPhotos = photoProvider.totalPhotos;
        _currentProgress = 0;
        _statusMessage = 'Starting analysis...';
      });
      
      _progressController.forward();
      
      // Start batch analysis
      await photoProvider.analyzePhotosInBatches(
        onProgress: (current, total) {
          setState(() {
            _currentProgress = current;
            _totalPhotos = total;
          });
        },
        onStatusUpdate: (message) {
          if (mounted) {
            setState(() {
              _statusMessage = message;
            });
          }
        },
        onBatchComplete: (batchPhotos, batchNumber, totalBatches) {
          if (mounted) {
            setState(() {
              _currentBatch = batchPhotos;
              _currentBatchNumber = batchNumber;
              _totalBatches = totalBatches;
              _showBatchReview = true;
              _isAnalyzing = false;
            });
          }
        },
      );
    } else {
      setState(() {
        _statusMessage = 'No photos found to analyze';
        _isAnalyzing = false;
      });
    }
  }

  // Continue to next batch
  Future<void> _continueToNextBatch() async {
    final photoProvider = context.read<PhotoProvider>();
    
    setState(() {
      _isAnalyzing = true;
      _showBatchReview = false;
      _statusMessage = 'Continuing to next batch...';
    });
    
    await photoProvider.continueToNextBatch(
      onProgress: (current, total) {
        setState(() {
          _currentProgress = current;
          _totalPhotos = total;
        });
      },
      onStatusUpdate: (message) {
        setState(() {
          _statusMessage = message;
        });
      },
      onBatchComplete: (batchPhotos, batchNumber, totalBatches) {
        setState(() {
          _currentBatch = batchPhotos;
          _currentBatchNumber = batchNumber;
          _totalBatches = totalBatches;
          _showBatchReview = true;
          _isAnalyzing = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Photo Analysis'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isLoading) {
            return _buildLoadingView();
          }

          if (photoProvider.errorMessage != null) {
            return _buildErrorView(photoProvider);
          }

          if (photoProvider.totalPhotos == 0) {
            return _buildEmptyView();
          }

          return _buildResultsView(photoProvider);
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress indicator
          if (_isAnalyzing) ...[
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _totalPhotos > 0 ? _currentProgress / _totalPhotos : 0.0,
                    strokeWidth: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  if (_totalPhotos > 0)
                    Text(
                      '${((_currentProgress / _totalPhotos) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_totalPhotos > 0)
              Text(
                'Analyzed $_currentProgress of $_totalPhotos photos',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 16),
            // Progress bar
            if (_totalPhotos > 0)
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentProgress / _totalPhotos,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Batch information
            if (_totalBatches > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Batch ${_currentBatchNumber > 0 ? _currentBatchNumber : 1} of $_totalBatches',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '50 photos per batch',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ] else if (_isLoadingPhotos) ...[
            // Loading photos view
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _totalAssets > 0 ? _loadingProgress / _totalAssets : 0.0,
                    strokeWidth: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  if (_totalAssets > 0)
                    Text(
                      '${((_loadingProgress / _totalAssets) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_totalAssets > 0)
              Text(
                'Processing $_loadingProgress of $_totalAssets photos',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 16),
            // Progress bar for loading
            if (_totalAssets > 0)
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _loadingProgress / _totalAssets,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Loading Thumbnails',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Processing photos in batches of 50',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progressAnimation.value,
                    strokeWidth: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Preparing Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Getting ready to analyze your photos...',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(PhotoProvider photoProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              photoProvider.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () {
                photoProvider.clearError();
                _startAnalysis();
              },
              text: 'Retry',
              icon: Icons.refresh,
              backgroundColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noPhotos,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No photos found on your device. Please make sure you have granted photo permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () {
                context.read<PhotoProvider>().loadPhotos();
              },
              text: 'Load Photos',
              icon: Icons.photo_library,
              backgroundColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(PhotoProvider photoProvider) {
    return Column(
      children: [
        // Analyze Button at the top
        
        
        // Header with stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Photo Loading Status
              if (photoProvider.hasMorePhotos) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Photo Loading Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loaded ${photoProvider.totalPhotos} of ${photoProvider.totalAssetCount} photos',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${photoProvider.remainingAssetCount} more photos available',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingPhotos ? null : _loadMorePhotos,
                          icon: _isLoadingPhotos 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_photo_alternate),
                          label: Text(_isLoadingPhotos ? 'Loading...' : 'Load 50 More Photos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                       SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onPressed: _isAnalyzing ? null : _startManualAnalysis,
                          text: _isAnalyzing ? 'Analyzing...' : 'Analyze Loaded ${photoProvider.totalPhotos} Photos',
                          icon: _isAnalyzing ? Icons.hourglass_empty : Icons.analytics_outlined,
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

              ],

              // Batch Review Section
              if (_showBatchReview) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Batch $_currentBatchNumber of $_totalBatches Complete',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentBatch.length} photos analyzed in this batch',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Found ${_currentBatch.where((photo) => photo.isBadPhoto).length} low-quality photos',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Review the analyzed photos below. You can select photos to delete or keep. Focus on blurry, over/under exposed, and useless photos.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              onPressed: () {
                                // Navigate to review screen for this batch
                                Navigator.pushNamed(context, '/review');
                              },
                              text: 'Review Photos',
                              icon: Icons.visibility_outlined,
                              backgroundColor: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              onPressed: _continueToNextBatch,
                              text: 'Continue Next Batch',
                              icon: Icons.arrow_forward,
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildResultCard(
                      'Total Photos',
                      '${photoProvider.totalPhotos}',
                      Icons.photo_library,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultCard(
                      'Bad Photos',
                      '${photoProvider.badPhotosCount}',
                      Icons.delete_outline,
                      AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildResultCard(
                      'Analysis Level',
                      AnalysisLevel.labels[photoProvider.currentAnalysisLevel] ?? '',
                      AnalysisLevel.icons[photoProvider.currentAnalysisLevel] ?? Icons.info,
                      AnalysisLevel.colors[photoProvider.currentAnalysisLevel] ?? AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultCard(
                      'Space Saved',
                      _calculateSpaceSaved(photoProvider),
                      Icons.storage,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Container(
        //   padding: const EdgeInsets.all(20),
        //   child: Column(
        //     children: [
        //       SizedBox(
        //         width: double.infinity,
        //         child: GradientButton(
        //           onPressed: _isAnalyzing ? null : _startManualAnalysis,
        //           text: _isAnalyzing ? 'Analyzing...' : 'Analyze All Photos',
        //           icon: _isAnalyzing ? Icons.hourglass_empty : Icons.analytics_outlined,
        //           backgroundColor: AppColors.primary,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (photoProvider.badPhotosCount > 0) ...[
                const SizedBox(height: 12),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/review');
                        },
                        text: 'Review Bad Photos',
                        icon: Icons.visibility_outlined,
                        backgroundColor: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: () => _showDeleteConfirmation(photoProvider),
                        text: 'Delete All Bad',
                        icon: Icons.delete_forever,
                        backgroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Photos Grid
        Expanded(
          child: _showBatchReview
              ? PhotoGrid(
                  photos: _currentBatch,
                  onPhotoTap: (photo) {
                    // Handle photo tap - could show full screen view
                  },
                )
              : photoProvider.badPhotos.isNotEmpty
                  ? PhotoGrid(
                      photos: photoProvider.badPhotos,
                      onPhotoTap: (photo) {
                        // Handle photo tap - could show full screen view
                      },
                    )
                  : const Center(
                      child: Text(
                        'No bad photos found with current analysis level',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _calculateSpaceSaved(PhotoProvider photoProvider) {
    int totalSize = 0;
    for (final photo in photoProvider.badPhotos) {
      totalSize += photo.fileSize;
    }
    
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  void _showDeleteConfirmation(PhotoProvider photoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Bad Photos'),
        content: Text(
          'Are you sure you want to delete all ${photoProvider.badPhotosCount} bad photos? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await photoProvider.deleteAllBadPhotos();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.deleteSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
