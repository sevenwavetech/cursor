import 'package:flutter/material.dart';

/// HabitTracker Pro Design System
/// iOS-inspired design language with consistent colors, typography, and spacing
class DesignSystem {
  // MARK: - Color Palette
  
  /// Primary system colors (iOS-inspired)
  static const Color primary = Color(0xFF007AFF);     // iOS Blue
  static const Color success = Color(0xFF34C759);     // iOS Green
  static const Color warning = Color(0xFFFF9500);     // iOS Orange
  static const Color destructive = Color(0xFFFF3B30); // iOS Red
  
  /// Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1C1C1E);
  static const Color surfaceLight = Color(0xFFF1F3F4);
  static const Color surfaceDark = Color(0xFF2C2C2E);
  
  /// Text colors
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFF6E6E73);
  static const Color textSecondaryDark = Color(0xFFAEAEB2);
  
  /// Habit color palette (16 options)
  static const List<Color> habitColors = [
    // Warm colors
    Color(0xFFFF6B6B), // Coral Red
    Color(0xFFFF8E53), // Orange
    Color(0xFFFF6B35), // Red Orange
    Color(0xFFFFA726), // Amber
    
    // Cool colors
    Color(0xFF4ECDC4), // Turquoise
    Color(0xFF45B7D1), // Sky Blue
    Color(0xFF5DADE2), // Light Blue
    Color(0xFF6C63FF), // Purple Blue
    
    // Natural colors
    Color(0xFF26A69A), // Teal
    Color(0xFF66BB6A), // Light Green
    Color(0xFF9CCC65), // Lime Green
    Color(0xFFD4AC0D), // Gold
    
    // Bold colors
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF795548), // Brown
  ];
  
  static const List<String> habitColorNames = [
    'Coral Red', 'Orange', 'Red Orange', 'Amber',
    'Turquoise', 'Sky Blue', 'Light Blue', 'Purple Blue',
    'Teal', 'Light Green', 'Lime Green', 'Gold',
    'Pink', 'Purple', 'Deep Purple', 'Brown',
  ];
  
  // MARK: - Typography (iOS San Francisco inspired)
  
  /// Large Title - 34pt Bold (screen headers)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  /// Title 1 - 28pt Bold (modal titles)
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  /// Headline - 18pt Semibold (habit names)
  static const TextStyle headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  /// Body - 16pt Regular (standard content)
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  /// Caption - 12pt Regular (streak counters)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
  
  // MARK: - Spacing System (8pt grid)
  
  static const double spacingMicro = 4.0;   // 4pt
  static const double spacingSmall = 8.0;   // 8pt
  static const double spacingMedium = 16.0; // 16pt
  static const double spacingLarge = 24.0;  // 24pt
  static const double spacingXL = 32.0;     // 32pt
  
  /// Screen margins
  static const double screenMargin = 16.0;
  
  /// Minimum touch target size
  static const double minTouchTarget = 44.0;
  
  // MARK: - Component Specifications
  
  /// Completion tiles
  static const double tileSize = 32.0;
  static const double tileBorderRadius = 6.0;
  
  /// Cards
  static const double cardHeight = 80.0;
  static const double cardSpacing = 16.0;
  static const double cardBorderRadius = 16.0;
  
  /// Buttons
  static const double buttonHeight = 50.0;
  static const double buttonBorderRadius = 12.0;
  
  /// Form inputs
  static const double inputHeight = 50.0;
  static const double inputPadding = 16.0;
  
  /// Habit icons
  static const double habitIconSize = 40.0;
  
  // MARK: - Animation Durations
  
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // MARK: - Helper Methods
  
  /// Get habit color by name
  static Color getHabitColor(String colorName) {
    final index = habitColorNames.indexOf(colorName);
    return index != -1 ? habitColors[index] : habitColors[0];
  }
  
  /// Get habit color by index
  static Color getHabitColorByIndex(int index) {
    return habitColors[index.clamp(0, habitColors.length - 1)];
  }
  
  /// Get text color for background
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textPrimaryLight
        : textPrimaryDark;
  }
  
  /// Get secondary text color
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textSecondaryLight
        : textSecondaryDark;
  }
  
  /// Get surface color
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : surfaceDark;
  }
  
  /// Create theme data
  static ThemeData createTheme({required bool isDark}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      secondary: primary.withOpacity(0.7),
      surface: isDark ? surfaceDark : surfaceLight,
      error: destructive,
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'SF Pro Display', // iOS San Francisco
      
      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? textPrimaryDark : textPrimaryLight,
        titleTextStyle: largeTitle.copyWith(
          color: isDark ? textPrimaryDark : textPrimaryLight,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
        color: isDark ? surfaceDark : surfaceLight,
        margin: const EdgeInsets.symmetric(vertical: spacingSmall),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: body.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceDark : surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: inputPadding,
          vertical: spacingMedium,
        ),
        hintStyle: body.copyWith(
          color: isDark ? textSecondaryDark : textSecondaryLight,
        ),
      ),
      
      // Text themes
      textTheme: TextTheme(
        displayLarge: largeTitle.copyWith(
          color: isDark ? textPrimaryDark : textPrimaryLight,
        ),
        displayMedium: title1.copyWith(
          color: isDark ? textPrimaryDark : textPrimaryLight,
        ),
        headlineSmall: headline.copyWith(
          color: isDark ? textPrimaryDark : textPrimaryLight,
        ),
        bodyLarge: body.copyWith(
          color: isDark ? textPrimaryDark : textPrimaryLight,
        ),
        bodyMedium: body.copyWith(
          color: isDark ? textSecondaryDark : textSecondaryLight,
        ),
        bodySmall: caption.copyWith(
          color: isDark ? textSecondaryDark : textSecondaryLight,
        ),
      ),
    );
  }
}

/// Extension for easier access to design system values
extension DesignSystemContext on BuildContext {
  /// Get design system colors
  Color get primaryColor => DesignSystem.primary;
  Color get successColor => DesignSystem.success;
  Color get warningColor => DesignSystem.warning;
  Color get destructiveColor => DesignSystem.destructive;
  
  /// Get context-aware colors
  Color get textColor => DesignSystem.getTextColor(this);
  Color get secondaryTextColor => DesignSystem.getSecondaryTextColor(this);
  Color get surfaceColor => DesignSystem.getSurfaceColor(this);
  
  /// Get spacing values
  double get spacingMicro => DesignSystem.spacingMicro;
  double get spacingSmall => DesignSystem.spacingSmall;
  double get spacingMedium => DesignSystem.spacingMedium;
  double get spacingLarge => DesignSystem.spacingLarge;
  double get spacingXL => DesignSystem.spacingXL;
}