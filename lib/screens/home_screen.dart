import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_analyzer/providers/photo_provider.dart';
import 'package:photo_analyzer/services/auth_service_simple.dart';
import 'package:photo_analyzer/utils/constants.dart';
import 'package:photo_analyzer/widgets/stat_card.dart';
import 'package:photo_analyzer/widgets/gradient_button.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasShownPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Check permission status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoProvider>().checkCurrentPermissionStatus();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      final authService = context.read<AuthServiceSimple>();
      await authService.signOut();
      // Navigation will be handled by AuthWrapper
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed out!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(AppStrings.appName),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          Consumer<AuthServiceSimple>(
            builder: (context, authService, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'signout') {
                    _signOut();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: AppColors.error),
                        const SizedBox(width: 8),
                        const Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: authService.userPhotoURL != null
                        ? ClipOval(
                            child: Image.network(
                              authService.userPhotoURL!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 20,
                                  color: AppColors.primary,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.primary,
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PhotoProvider>(
          builder: (context, photoProvider, child) {
            return CustomScrollView(
              slivers: [
                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // User Welcome Section
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Consumer<AuthServiceSimple>(
                            builder: (context, authService, child) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          child: authService.userPhotoURL != null
                                              ? ClipOval(
                                                  child: Image.network(
                                                    authService.userPhotoURL!,
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.person,
                                                        size: 24,
                                                        color: Colors.white,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  size: 24,
                                                  color: Colors.white,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Welcome back!',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                authService.userDisplayName ?? 'User',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Smart Photo Management',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Analyze and organize your photos automatically. Free up storage space by removing low-quality images.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                       const SizedBox(height: 24),

                      // IL-NIQE Analysis Option
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Advanced Analysis',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Consumer<PhotoProvider>(
                                      builder: (context, photoProvider, child) {
                                        return Row(
                                          children: [
                                            if (photoProvider.isILNIQEServerHealthy)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.success,
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            else
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.error,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: photoProvider.useILNIQE,
                                              onChanged: (value) {
                                                photoProvider.toggleILNIQE(value);
                                              },
                                              activeColor: AppColors.primary,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Consumer<PhotoProvider>(
                                  builder: (context, photoProvider, child) {
                                    return Text(
                                      'Using IL-NIQE AI for advanced image quality analysis',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                                if (!photoProvider.isILNIQEServerHealthy) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: AppColors.warning,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'IL-NIQE server not available. Analysis will fail.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                       const SizedBox(height: 16),

                      // Action Buttons
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Actions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GradientButton(
                                onPressed: () async {
                                  // Use bypass permission functionality as default
                                  await photoProvider.bypassPermissionCheck();
                                  if (mounted) {
                                    Navigator.pushNamed(context, '/analysis');
                                  }
                                },
                                text: 'Start Photo Assessment',
                                icon: Icons.analytics_outlined,
                                backgroundColor: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              if (photoProvider.badPhotosCount > 0)
                                GradientButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/review');
                                  },
                                  text: 'Review Assessment Results',
                                  icon: Icons.visibility_outlined,
                                  backgroundColor: AppColors.warning,
                                ),
                            ],
                          ),
                        ),
                      ),


                      const SizedBox(height: 24),

                      // Statistics Section
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Photo Statistics',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Total Photos',
                                      value: photoProvider.totalPhotos.toString(),
                                      icon: Icons.photo_library,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Good Images',
                                      value: photoProvider.totalPhotos > 0 
                                        ? (photoProvider.totalPhotos - photoProvider.badPhotosCount).toString()
                                        : '0',
                                      icon: Icons.check_circle,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Bad Images',
                                      value: photoProvider.badPhotosCount.toString(),
                                      icon: Icons.delete_outline,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Good Quality %',
                                      value: photoProvider.totalPhotos > 0 
                                        ? '${((photoProvider.totalPhotos - photoProvider.badPhotosCount) / photoProvider.totalPhotos * 100).toStringAsFixed(1)}%'
                                        : '0%',
                                      icon: Icons.analytics,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                     
                     
                      const SizedBox(height: 24),

                      // Analysis Level Selector
                      if (photoProvider.totalPhotos > 0)
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Analysis Level',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border, width: 0.5),
                                  ),
                                  child: Column(
                                    children: AnalysisLevel.labels.entries.map((entry) {
                                      final isSelected = photoProvider.currentAnalysisLevel == entry.key;
                                      return RadioListTile<String>(
                                        title: Row(
                                          children: [
                                            Icon(
                                              AnalysisLevel.icons[entry.key],
                                              color: AnalysisLevel.colors[entry.key],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        value: entry.key,
                                        groupValue: photoProvider.currentAnalysisLevel,
                                        onChanged: (value) {
                                          if (value != null) {
                                            photoProvider.setAnalysisLevel(value);
                                          }
                                        },
                                        activeColor: AppColors.primary,
                                        contentPadding: EdgeInsets.zero,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PermissionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
