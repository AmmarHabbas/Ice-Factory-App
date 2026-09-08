import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF003366); // Deep Royal Blue
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF001E40);
  static const Color onPrimaryContainer = Color(0xFF799DD6);

  static const Color secondary = Color(0xFF2E6385);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFA5D8FF); // Ice Blue Accent
  static const Color onSecondaryContainer = Color(0xFF285F80);

  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0D1C2E);
  
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0D1C2E);
  static const Color surfaceVariant = Color(0xFFD5E3FC);
  static const Color onSurfaceVariant = Color(0xFF43474F);

  // Surface Containers (Material 3)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE6EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD5E3FC);

  // Outlines & Borders
  static const Color outline = Color(0xFF737780);
  static const Color outlineVariant = Color(0xFFC3C6D1);

  // Semantic Status Colors
  static const Color paid = Color(0xFF2E7D32); // Emerald Green for Completed/Paid
  static const Color paidContainer = Color(0xFFE8F5E9);
  
  static const Color unpaid = Color(0xFFBA1A1A); // Soft Red for Unpaid/Error
  static const Color unpaidContainer = Color(0xFFFFDAD6);

  static const Color partial = Color(0xFFEF6C00); // Amber for Partial
  static const Color partialContainer = Color(0xFFFFE0B2);
  
  static const Color pending = Color(0xFF737780); // Grey for Pending
  static const Color pendingContainer = Color(0xFFECEFF1);
}
