import 'package:flutter/material.dart';

class AppColors {
  // Apple-style system colors
  static const Color primary = Color(0xFF007AFF); // Apple Blue
  static const Color secondary = Color(0xFF5856D6); // Apple Purple
  static const Color accent = Color(0xFF34C759); // Apple Green
  static const Color success = Color(0xFF34C759); // Apple Green
  static const Color warning = Color(0xFFFF9500); // Apple Orange
  static const Color error = Color(0xFFFF3B30); // Apple Red
  static const Color textPrimary = Color(0xFF000000); // Pure black for iOS
  static const Color textSecondary = Color(0xFF8E8E93); // Apple Gray
  static const Color background = Color(0xFFF2F2F7); // Apple Light Gray
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color border = Color(0xFFC6C6C8); // Apple Border Gray
  static const Color cardBackground = Color(0xFFFFFFFF); // Clean white
}

class AnalysisLevel {
  static const String good = 'good';
  static const String bad = 'bad';
  
  static const Map<String, String> labels = {
    good: 'Good Images',
    bad: 'Bad Images',
  };
  
  static const Map<String, Color> colors = {
    good: AppColors.success,
    bad: AppColors.error,
  };
  
  static const Map<String, IconData> icons = {
    good: Icons.check_circle,
    bad: Icons.cancel,
  };
}

class AppStrings {
  static const String appName = 'Photo Analyzer';
  static const String analyzePhotos = 'Analyze Photos';
  static const String reviewPhotos = 'Review Photos';
  static const String deleteAll = 'Delete All Bad Photos';
  static const String selectLevel = 'Select Analysis Level';
  static const String analyzing = 'Analyzing Photos...';
  static const String noPhotos = 'No photos found';
  static const String permissionRequired = 'Photo permission required';
  static const String permissionDenied = 'Permission denied';
  static const String deleteConfirmation = 'Are you sure you want to delete all bad photos?';
  static const String deleteSuccess = 'Photos deleted successfully';
  static const String deleteError = 'Error deleting photos';
}
