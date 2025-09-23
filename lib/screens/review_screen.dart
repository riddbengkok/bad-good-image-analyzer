import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_analyzer/providers/photo_provider.dart';
import 'package:photo_analyzer/models/photo_model.dart';
import 'package:photo_analyzer/utils/constants.dart';
import 'package:photo_analyzer/widgets/photo_grid.dart';
import 'package:photo_analyzer/widgets/gradient_button.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with TickerProviderStateMixin {
  bool _isSelectionMode = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize with all bad photos selected for deletion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final photoProvider = context.read<PhotoProvider>();
      if (photoProvider.badPhotos.isNotEmpty) {
        _isSelectionMode = true;
        // Select all bad photos by default
        for (final photo in photoProvider.badPhotos) {
          photoProvider.togglePhotoSelection(photo.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Assessment Results'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<PhotoProvider>(
            builder: (context, photoProvider, child) {
              if (photoProvider.badPhotos.isEmpty && photoProvider.goodPhotosCount == 0) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) {
                      photoProvider.deselectAllPhotos();
                    }
                  });
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                return Tab(
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  text: 'Bad (${photoProvider.badPhotosCount})',
                );
              },
            ),
            Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                return Tab(
                  icon: const Icon(Icons.check_circle, color: AppColors.success),
                  text: 'Good (${photoProvider.goodPhotosCount})',
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bad Images Tab
          Consumer<PhotoProvider>(
            builder: (context, photoProvider, child) {
              if (photoProvider.badPhotos.isEmpty) {
                return _buildEmptyView('No bad images found', 'All your photos meet the quality standards!');
              }
              return Column(
                children: [
                  // Simple header for bad photos
                  _buildBadPhotosHeader(photoProvider),
                  
                  // Selection controls
                  if (_isSelectionMode) _buildSelectionControls(photoProvider),
                  
                  // Photos grid
                  Expanded(
                    child: PhotoGrid(
                      photos: photoProvider.badPhotos,
                      showSelection: _isSelectionMode,
                      onPhotoSelected: (photo) {
                        photoProvider.togglePhotoSelection(photo.id);
                      },
                      onPhotoTap: (photo) {
                        if (_isSelectionMode) {
                          photoProvider.togglePhotoSelection(photo.id);
                        } else {
                          _showPhotoDetails(photo);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          // Good Images Tab
          Consumer<PhotoProvider>(
            builder: (context, photoProvider, child) {
              final goodPhotos = photoProvider.allPhotos.where((photo) => 
                photo.analysisLevel == AnalysisLevel.good).toList();
              
              if (goodPhotos.isEmpty) {
                return _buildEmptyView('No good images found', 'All analyzed photos were marked as low quality.');
              }
              return Column(
                children: [
                  // Header with stats for good photos
                  _buildGoodPhotosHeader(photoProvider, goodPhotos),
                  
                  // Photos grid
                  Expanded(
                    child: PhotoGrid(
                      photos: goodPhotos,
                      showSelection: false, // No selection for good photos
                      onPhotoSelected: (photo) {
                        // No selection for good photos
                      },
                      onPhotoTap: (photo) {
                        _showPhotoDetails(photo);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          // Show instant delete button only on bad photos tab and when in selection mode
          if (_tabController.index != 0 || !_isSelectionMode || photoProvider.selectedPhotosCount == 0) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _instantDeleteSelected(photoProvider),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.delete_forever),
            label: Text('Delete ${photoProvider.selectedPhotosCount}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView([String? title, String? subtitle]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title?.contains('good') == true ? Icons.check_circle_outline : Icons.photo_library_outlined,
              size: 64,
              color: title?.contains('good') == true ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'No Photos Found',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? 'No photos have been analyzed yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () => Navigator.pop(context),
              text: 'Back to Home',
              icon: Icons.home,
              backgroundColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoodPhotosHeader(PhotoProvider photoProvider, List<PhotoModel> goodPhotos) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Good Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Good',
                goodPhotos.length.toString(),
                AppColors.success,
              ),
              _buildStatItem(
                'Quality Score',
                goodPhotos.isNotEmpty 
                  ? (goodPhotos.map((p) => p.qualityScore ?? 0.0).reduce((a, b) => a + b) / goodPhotos.length).toStringAsFixed(2)
                  : '0.00',
                AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(PhotoProvider photoProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Classification Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                const Text(
                  'Photo Assessment Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildClassificationCard(
                        'Good Images',
                        photoProvider.totalPhotos > 0 
                          ? (photoProvider.totalPhotos - photoProvider.badPhotosCount).toString()
                          : '0',
                        Icons.check_circle,
                        AppColors.success,
                        'High quality images\n(Score ≥ 60)',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClassificationCard(
                        'Bad Images',
                        photoProvider.badPhotosCount.toString(),
                        Icons.cancel,
                        AppColors.error,
                        'Low quality images\n(Score < 60)',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Selected',
                  photoProvider.selectedPhotosCount.toString(),
                  Icons.check_circle,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Space to Save',
                  _calculateSpaceToSave(photoProvider),
                  Icons.storage,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationCard(String title, String value, IconData icon, Color color, String description) {
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildSelectionControls(PhotoProvider photoProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                photoProvider.selectAllBadPhotos();
              },
              icon: const Icon(Icons.select_all),
              label: const Text('Select All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                photoProvider.deselectAllPhotos();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateSpaceToSave(PhotoProvider photoProvider) {
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

  void _showPhotoDetails(PhotoModel photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo preview
                    Center(
                      child: photo.asset != null
                          ? FutureBuilder<Uint8List?>(
                              future: photo.asset!.thumbnailData,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }

                                if (snapshot.hasError || !snapshot.hasData) {
                                  return const Icon(Icons.broken_image, size: 100);
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    snapshot.data!,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.photo,
                                size: 80,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Photo details
                    _buildDetailRow('Resolution', '${photo.width} × ${photo.height}'),
                    _buildDetailRow('File Size', photo.fileSizeFormatted),
                    _buildDetailRow('Created', photo.createTime.toString().substring(0, 10)),
                    if (photo.analysisLevel != null)
                      _buildDetailRow('Assessment Result', photo.analysisLevel == 'good' ? 'Good Image' : 'Bad Image'),
                    if (photo.qualityScore != null)
                      _buildDetailRow('Quality Score', photo.qualityScore!.toStringAsFixed(2)),
                    
                    // IL-NIQE Analysis Information
                    if (photo.analysisMethod == 'il_niqe' && photo.traditionalResults != null)
                      _buildDetailRow('Analysis Method', 'IL-NIQE (Advanced)'),
                    if (photo.analysisMethod == 'il_niqe' && photo.traditionalResults != null && photo.traditionalResults!['il_niqe_category'] != null)
                      _buildDetailRow('IL-NIQE Category', photo.traditionalResults!['il_niqe_category']),
                    if (photo.analysisMethod == 'il_niqe' && photo.traditionalResults != null && photo.traditionalResults!['il_niqe_processing_time'] != null)
                      _buildDetailRow('Processing Time', '${(photo.traditionalResults!['il_niqe_processing_time'] as double).toStringAsFixed(3)}s'),
                    
                    _buildDetailRow('Assessment Details', photo.analysisLevel == 'good' 
                      ? 'High quality image (Score ≥ 60)' 
                      : 'Low quality image (Score < 60)'),

                    
                    const SizedBox(height: 20),
                    
                    // Action buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<PhotoProvider>().togglePhotoSelection(photo.id);
                              setState(() {
                                _isSelectionMode = true;
                              });
                            },
                            icon: const Icon(Icons.select_all),
                            label: const Text('Select for Deletion'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Keep Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadPhotosHeader(PhotoProvider photoProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Bad Images',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${photoProvider.badPhotosCount} photos',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap photos to deselect them from deletion. All bad photos are selected by default.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _instantDeleteSelected(PhotoProvider photoProvider) async {
    // Show a quick confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Photos'),
        content: Text(
          'Delete ${photoProvider.selectedPhotosCount} selected photos? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await photoProvider.deleteSelectedPhotos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photos deleted successfully from your device'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _isSelectionMode = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete photos: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showDeleteConfirmation(PhotoProvider photoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Photos'),
        content: Text(
          'Are you sure you want to delete ${photoProvider.selectedPhotosCount} selected photos? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await photoProvider.deleteSelectedPhotos();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.deleteSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
                setState(() {
                  _isSelectionMode = false;
                });
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
