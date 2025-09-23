import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:photo_analyzer/models/photo_model.dart';
import 'package:photo_analyzer/utils/constants.dart';

class PhotoGrid extends StatelessWidget {
  final List<PhotoModel> photos;
  final Function(PhotoModel)? onPhotoTap;
  final bool showSelection;
  final Function(PhotoModel)? onPhotoSelected;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.onPhotoTap,
    this.showSelection = false,
    this.onPhotoSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Text(
          'No photos to display',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      padding: const EdgeInsets.all(8),
      itemCount: photos.length,
      // Add cache extent to improve scrolling performance
      cacheExtent: 2000,
      // Add physics for better scrolling
      physics: const BouncingScrollPhysics(),
      // Add addAutomaticKeepAlives to prevent unnecessary rebuilds
      addAutomaticKeepAlives: true,
      // Add addRepaintBoundaries to optimize rendering
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return PhotoTile(
          key: ValueKey('${photo.id}_${photo.analysisLevel}'), // More specific key
          photo: photo,
          onTap: () => onPhotoTap?.call(photo),
          showSelection: showSelection,
          onSelected: () => onPhotoSelected?.call(photo),
        );
      },
    );
  }
}

class PhotoTile extends StatefulWidget {
  final PhotoModel photo;
  final VoidCallback? onTap;
  final bool showSelection;
  final VoidCallback? onSelected;

  const PhotoTile({
    super.key,
    required this.photo,
    this.onTap,
    this.showSelection = false,
    this.onSelected,
  });

  @override
  State<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(PhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the photo ID changed
    if (oldWidget.photo.id != widget.photo.id) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.photo.asset == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    try {
      final thumbnailData = await widget.photo.asset!.thumbnailData;
      if (mounted) {
        setState(() {
          _thumbnailData = thumbnailData;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // Minimal shadow for Apple style
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Photo Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImage(),
            ),

            // Selection Overlay
            if (widget.showSelection)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onSelected,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: widget.photo.isSelected
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.transparent,
                      border: widget.photo.isSelected
                          ? Border.all(
                              color: AppColors.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: widget.photo.isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                ),
              ),

            // Analysis Level Badge
            if (widget.photo.analysisLevel != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AnalysisLevel.colors[widget.photo.analysisLevel!]?.withOpacity(0.9) ?? AppColors.accent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    AnalysisLevel.icons[widget.photo.analysisLevel!] ?? Icons.info,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),

            // File Size Badge
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.photo.fileSizeFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoading) {
      return Container(
        height: 120,
        color: AppColors.border,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_hasError || _thumbnailData == null) {
      return Container(
        height: 120,
        color: AppColors.border,
        child: const Center(
          child: Icon(
            Icons.broken_image,
            color: AppColors.textSecondary,
            size: 32,
          ),
        ),
      );
    }

    return Image.memory(
      _thumbnailData!,
      fit: BoxFit.cover,
      width: double.infinity,
      // Add cache key to prevent unnecessary rebuilds
      gaplessPlayback: true,
    );
  }
}
