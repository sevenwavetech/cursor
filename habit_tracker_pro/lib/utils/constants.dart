import 'package:flutter/material.dart';

class AppConstants {
  // App Colors
  static const List<Color> habitColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF6B7280), // Gray
  ];

  static const List<String> habitColorNames = [
    'Indigo',
    'Violet', 
    'Pink',
    'Red',
    'Orange',
    'Yellow',
    'Green',
    'Cyan',
    'Blue',
    'Gray',
  ];

  // Habit Icons
  static const List<IconData> habitIcons = [
    Icons.fitness_center,
    Icons.local_drink,
    Icons.book,
    Icons.bedtime,
    Icons.directions_run,
    Icons.self_improvement,
    Icons.music_note,
    Icons.palette,
    Icons.work,
    Icons.school,
    Icons.restaurant,
    Icons.phone,
    Icons.computer,
    Icons.favorite,
    Icons.lightbulb,
    Icons.nature,
    Icons.pets,
    Icons.home,
    Icons.car_rental,
    Icons.shopping_cart,
  ];

  static const List<String> habitIconNames = [
    'Fitness',
    'Drink Water',
    'Read',
    'Sleep',
    'Run',
    'Meditate',
    'Music',
    'Art',
    'Work',
    'Study',
    'Eat',
    'Call',
    'Computer',
    'Health',
    'Ideas',
    'Nature',
    'Pets',
    'Home',
    'Travel',
    'Shopping',
  ];

  // Frequencies
  static const List<String> frequencies = ['daily', 'weekly', 'monthly'];
  static const List<String> frequencyLabels = ['Daily', 'Weekly', 'Monthly'];

  // App Settings
  static const String appName = 'HabitTracker Pro';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'habit_tracker.db';
  static const int databaseVersion = 1;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Tile Grid Constants
  static const int tilesPerRow = 7; // Days in a week
  static const double tileSize = 32.0;
  static const double tileSpacing = 4.0;

  // Streak Colors
  static const Color streakColor1 = Color(0xFFE5E7EB); // Light gray
  static const Color streakColor2 = Color(0xFFC3F0CA); // Light green
  static const Color streakColor3 = Color(0xFF86EFAC); // Medium green
  static const Color streakColor4 = Color(0xFF4ADE80); // Green
  static const Color streakColor5 = Color(0xFF16A34A); // Dark green

  // Get color by name
  static Color getColorByName(String colorName) {
    final index = habitColorNames.indexOf(colorName);
    return index != -1 ? habitColors[index] : habitColors[0];
  }

  // Get icon by name
  static IconData getIconByName(String iconName) {
    final index = habitIconNames.indexOf(iconName);
    return index != -1 ? habitIcons[index] : habitIcons[0];
  }

  // Get streak color based on completion count
  static Color getStreakColor(int completionCount, int targetCount) {
    if (completionCount == 0) return streakColor1;
    
    final percentage = (completionCount / targetCount).clamp(0.0, 1.0);
    
    if (percentage >= 1.0) return streakColor5;
    if (percentage >= 0.75) return streakColor4;
    if (percentage >= 0.5) return streakColor3;
    if (percentage >= 0.25) return streakColor2;
    
    return streakColor1;
  }
}