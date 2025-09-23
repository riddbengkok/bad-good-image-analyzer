import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_analyzer/providers/photo_provider_mobile.dart';
import 'package:photo_analyzer/utils/constants.dart';

class AnalysisSettingsScreen extends StatefulWidget {
  const AnalysisSettingsScreen({super.key});

  @override
  State<AnalysisSettingsScreen> createState() => _AnalysisSettingsScreenState();
}

class _AnalysisSettingsScreenState extends State<AnalysisSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Settings'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Analysis Methods'),
                _buildAnalysisMethodSettings(photoProvider),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Performance Options'),
                _buildPerformanceSettings(photoProvider),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Cache Management'),
                _buildCacheSettings(photoProvider),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Image Classification'),
                _buildImageClassificationInfo(),
                
                const SizedBox(height: 32),
                _buildActionButtons(photoProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAnalysisMethodSettings(PhotoProvider photoProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSwitchTile(
              title: 'Use ML Kit',
              subtitle: 'Advanced AI-powered image analysis using Google ML Kit',
              value: photoProvider.useMLKit,
              onChanged: (value) {
                photoProvider.toggleMLKit(value);
              },
              icon: Icons.psychology,
            ),
            
            const Divider(),
            
            _buildInfoTile(
              title: 'IL-NIQE Analysis',
              subtitle: 'Advanced learning-based image quality assessment using AI',
              icon: Icons.auto_awesome,
              trailing: _buildILNIQEStatusIndicator(photoProvider),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSettings(PhotoProvider photoProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoTile(
              title: 'Batch Size',
              subtitle: 'Process photos in batches of 50 for optimal performance',
              icon: Icons.batch_prediction,
            ),
            
            const Divider(),
            
            _buildInfoTile(
              title: 'Memory Management',
              subtitle: 'Automatic memory cleanup and optimized image processing',
              icon: Icons.memory,
            ),
            
            const Divider(),
            
            _buildInfoTile(
              title: 'Parallel Processing',
              subtitle: 'Use multiple CPU cores for faster analysis',
              icon: Icons.speed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSettings(PhotoProvider photoProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoTile(
              title: 'Cache Size',
              subtitle: 'Store up to 1000 analysis results for instant access',
              icon: Icons.storage,
            ),
            
            const Divider(),
            
            _buildInfoTile(
              title: 'Cache Expiry',
              subtitle: 'Results expire after 7 days to save storage',
              icon: Icons.schedule,
            ),
            
            const Divider(),
            
            _buildButtonTile(
              title: 'View Cache Statistics',
              subtitle: 'See cache hit rates and memory usage',
              icon: Icons.analytics,
              onTap: () => _showCacheStats(photoProvider),
            ),
            
            const Divider(),
            
            _buildButtonTile(
              title: 'Clear Cache',
              subtitle: 'Remove all cached analysis results',
              icon: Icons.clear_all,
              onTap: () => _showClearCacheDialog(photoProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageClassificationInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoTile(
              title: 'Good Image Assessment',
              subtitle: 'Photos must score ≥ 0.7 to meet quality standards',
              icon: Icons.check_circle,
            ),
            
            const Divider(),
            
            _buildInfoTile(
              title: 'Bad Image Assessment',
              subtitle: 'Photos scoring < 0.7 automatically fail quality standards',
              icon: Icons.cancel,
            ),
            
            const Divider(),
            
            _buildInfoTile(
              title: 'Assessment Method',
              subtitle: 'Start with Good Image criteria first, then mark failures as Bad',
              icon: Icons.assessment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(PhotoProvider photoProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _resetToDefaults(photoProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reset to Defaults',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _exportSettings(photoProvider),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Export Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    Widget? trailing,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 36.0),
        child: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      secondary: trailing,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildButtonTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.warning),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Future<void> _showCacheStats(PhotoProvider photoProvider) async {
    final stats = await photoProvider.getCacheStats();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Cached: ${stats['total_cached']}'),
            Text('Valid Entries: ${stats['valid_entries']}'),
            Text('Expired Entries: ${stats['expired_entries']}'),
            Text('Memory Usage: ${(stats['memory_usage_mb'] as double).toStringAsFixed(2)} MB'),
            Text('Cache Hit Rate: ${(stats['cache_hit_rate'] as double * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearCacheDialog(PhotoProvider photoProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached analysis results? This will require re-analyzing photos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await photoProvider.clearAnalysisCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  void _resetToDefaults(PhotoProvider photoProvider) {
    photoProvider.toggleMLKit(true);
    photoProvider.toggleHybridAnalysis(true);
    photoProvider.toggleOptimizedAlgorithms(true);
    photoProvider.setAnalysisLevel(AnalysisLevel.standard);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to defaults')),
    );
  }

  void _exportSettings(PhotoProvider photoProvider) {
    final settings = {
      'ml_kit_enabled': photoProvider.useMLKit,
      'il_niqe_enabled': photoProvider.useILNIQE,
      'il_niqe_server_healthy': photoProvider.isILNIQEServerHealthy,
      'hybrid_analysis': photoProvider.useHybridAnalysis,
      'optimized_algorithms': photoProvider.useOptimizedAlgorithms,
      'analysis_level': photoProvider.currentAnalysisLevel,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // In a real app, you would export this to a file or share it
    print('DEBUG: Settings to export: $settings');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings exported (check console)')),
    );
  }

  Widget _buildILNIQEStatusIndicator(PhotoProvider photoProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          photoProvider.isILNIQEServerHealthy ? Icons.check_circle : Icons.error,
          color: photoProvider.isILNIQEServerHealthy ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          photoProvider.isILNIQEServerHealthy ? 'Connected' : 'Disconnected',
          style: TextStyle(
            color: photoProvider.isILNIQEServerHealthy ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, size: 16),
          onPressed: () {
            photoProvider.checkILNIQEServerHealth();
          },
          tooltip: 'Check server status',
        ),
      ],
    );
  }
}
