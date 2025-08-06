# HabitTracker Pro

A comprehensive habit tracking app built with Flutter, featuring tile-based progress visualization and offline-first architecture.

## Features

🎯 **Habit Management**
- Create and customize habits with colors and icons
- Set custom target counts (1-10 times per day/week/month)
- Edit and delete habits with confirmation dialogs

📊 **Progress Visualization**
- Tile-based progress grids inspired by GitHub's contribution graph
- Color-coded completion levels (5 intensity levels)
- Streak tracking and statistics
- Compact progress views for quick insights

📅 **Calendar View**
- Monthly calendar with habit completion indicators
- Select any date to view and edit habit completions
- Visual indicators for completed vs. partial completions

⚙️ **Settings & Statistics**
- View total habits, entries, and activity statistics
- App information and version details
- Data management options (export/import/reset)

🎨 **Beautiful UI**
- Material Design 3 with modern aesthetics
- Dark/Light theme support (system default)
- Smooth animations and transitions
- iOS-style components integration

💾 **Offline-First**
- Local SQLite database for all data storage
- No internet connection required
- Fast performance and data persistence

## Screenshots

[Screenshots would go here in a real project]

## Architecture

### Project Structure
```
lib/
├── models/          # Data models (Habit, HabitEntry)
├── services/        # Database helper and business logic
├── screens/         # Main app screens
├── widgets/         # Reusable UI components
├── utils/           # Constants, helpers, and utilities
└── main.dart        # App entry point
```

### Key Components

- **DatabaseHelper**: SQLite database management with CRUD operations
- **HabitTile**: Main habit display widget with progress grid
- **ProgressGrid**: Tile-based visualization component
- **Calendar View**: Interactive monthly calendar
- **Material Design 3**: Modern UI with consistent theming

## Technical Details

### Dependencies
- `sqflite: ^2.3.0` - SQLite database
- `path: ^1.8.3` - File path utilities
- `flutter/material.dart` - Material Design components
- `flutter/cupertino.dart` - iOS-style components

### Database Schema

**Habits Table:**
- id (PRIMARY KEY)
- name, description
- color, icon
- frequency (daily/weekly/monthly)
- targetCount
- createdAt, isActive

**HabitEntries Table:**
- id (PRIMARY KEY)
- habitId (FOREIGN KEY)
- date (unique per habit)
- completionCount
- notes, createdAt

### Key Features Implementation

**Tile-based Progress Grid:**
- Shows last 28 days by default
- Color intensity based on completion percentage
- Tooltips with detailed information
- Today indicator with border highlight

**Streak Calculation:**
- Counts consecutive days of habit completion
- Considers target count for completion status
- Real-time updates when habits are marked complete

**Offline-First Design:**
- All data stored locally in SQLite
- Instant app startup and navigation
- No network dependencies

## Getting Started

### Prerequisites
- Flutter SDK (3.1.3 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd habit_tracker_pro
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Usage

### Creating Your First Habit

1. Tap the "Add Habit" floating action button
2. Enter habit name and optional description
3. Choose a color and icon from the selection grid
4. Set frequency (daily/weekly/monthly) and target count
5. Tap "Create Habit" to save

### Tracking Progress

1. **Dashboard**: Mark habits complete with the action button
2. **Calendar**: Select any date to view/edit completions
3. **Progress Grids**: Visual representation of your consistency

### Viewing Statistics

- **Habit Cards**: Show current streak, completion rate, and today's progress
- **Dashboard Overview**: Total habits, completed today, remaining
- **Settings**: Overall app statistics and data management

## Customization

### Adding New Colors
Edit `lib/utils/constants.dart`:
```dart
static const List<Color> habitColors = [
  // Add your custom colors here
  Color(0xFFYourColor),
];
```

### Adding New Icons
Edit `lib/utils/constants.dart`:
```dart
static const List<IconData> habitIcons = [
  // Add your custom icons here
  Icons.your_icon,
];
```

## Testing

Run tests with:
```bash
flutter test
```

## Performance Considerations

- **Lazy Loading**: Habit data loaded on-demand
- **Efficient Queries**: Indexed database queries for fast lookups
- **Memory Management**: Proper disposal of controllers and resources
- **Smooth Animations**: Optimized widget rebuilds

## Future Enhancements

- [ ] Cloud backup and sync
- [ ] Push notifications and reminders
- [ ] Habit templates and categories
- [ ] Advanced analytics and insights
- [ ] Social features and sharing
- [ ] Import/Export functionality
- [ ] Widget support for home screen
- [ ] Apple Watch / Wear OS companion apps

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the excellent framework
- Material Design team for design guidelines
- SQLite team for the reliable database engine
- The open-source community for inspiration and support

---

Built with ❤️ using Flutter
