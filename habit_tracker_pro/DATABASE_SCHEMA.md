# HabitTracker Pro - Database Schema Documentation

## Overview

HabitTracker Pro uses SQLite as its local database to provide offline-first functionality. The database consists of two main tables: `habits` and `completions`, designed to efficiently store and retrieve habit tracking data.

## Database Schema

### 1. Habits Table

The `habits` table stores the core habit information and configuration.

```sql
CREATE TABLE habits(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL CHECK(length(name) <= 30),
  description TEXT,
  color TEXT NOT NULL,
  icon TEXT NOT NULL,
  frequency TEXT NOT NULL DEFAULT 'daily' CHECK(frequency IN ('daily', 'weekly', 'custom')),
  is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**Fields:**
- `id`: Unique identifier for the habit
- `name`: Habit name (max 30 characters)
- `description`: Optional longer description
- `color`: Hex color code for UI representation
- `icon`: Icon identifier string
- `frequency`: How often the habit should be performed ('daily', 'weekly', 'custom')
- `is_archived`: Boolean flag (0=active, 1=archived)
- `created_at`: ISO8601 timestamp when habit was created
- `updated_at`: ISO8601 timestamp when habit was last modified

**Constraints:**
- Name length must be ≤ 30 characters
- Frequency must be one of: 'daily', 'weekly', 'custom'
- is_archived must be 0 or 1

### 2. Completions Table

The `completions` table tracks when habits are marked as completed.

```sql
CREATE TABLE completions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habit_id INTEGER NOT NULL,
  completion_date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
  UNIQUE(habit_id, completion_date)
);
```

**Fields:**
- `id`: Unique identifier for the completion
- `habit_id`: Foreign key referencing the habit
- `completion_date`: Date in YYYY-MM-DD format
- `created_at`: ISO8601 timestamp when completion was recorded

**Constraints:**
- Foreign key constraint ensures referential integrity
- Unique constraint prevents duplicate completions for the same habit on the same date
- CASCADE delete removes completions when habit is deleted

### 3. Database Indexes

Performance-optimized indexes for common query patterns:

```sql
CREATE INDEX idx_habits_is_archived ON habits(is_archived);
CREATE INDEX idx_completions_habit_id ON completions(habit_id);
CREATE INDEX idx_completions_date ON completions(completion_date);
CREATE INDEX idx_completions_habit_date ON completions(habit_id, completion_date);
```

## Data Models

### Habit Model

```dart
class Habit {
  final int? id;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final String frequency;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Key Methods:**
- `toMap()`: Converts to database-compatible map
- `fromMap()`: Creates instance from database row
- `copyWith()`: Creates modified copy with updated fields

### Completion Model

```dart
class Completion {
  final int? id;
  final int habitId;
  final DateTime completionDate;
  final DateTime createdAt;
}
```

**Key Methods:**
- `toMap()`: Converts to database-compatible map
- `fromMap()`: Creates instance from database row
- `dateOnly`: Returns date without time component
- `isToday`: Checks if completion is for today
- `isYesterday`: Checks if completion is for yesterday

## Database Operations

### Habit Operations

#### Insert Habit
```dart
Future<int> insertHabit(Habit habit)
```
Creates a new habit and returns the generated ID.

#### Get All Habits
```dart
Future<List<Habit>> getAllHabits({bool includeArchived = false})
```
Retrieves all habits, optionally including archived ones.

#### Get Single Habit
```dart
Future<Habit?> getHabit(int id)
```
Retrieves a specific habit by ID.

#### Update Habit
```dart
Future<int> updateHabit(Habit habit)
```
Updates an existing habit and sets updated_at timestamp.

#### Delete Habit
```dart
Future<int> deleteHabit(int id)
```
Permanently deletes a habit and all its completions.

#### Archive/Unarchive Habit
```dart
Future<int> archiveHabit(int id, {bool archive = true})
```
Archives or unarchives a habit without deleting it.

### Completion Operations

#### Insert Completion
```dart
Future<int> insertCompletion(Completion completion)
```
Records a habit completion. Uses REPLACE conflict resolution.

#### Get Completions for Habit
```dart
Future<List<Completion>> getCompletionsForHabit(
  int habitId, {
  DateTime? startDate,
  DateTime? endDate,
})
```
Retrieves completions for a habit within optional date range.

#### Get Completion for Date
```dart
Future<Completion?> getCompletionForDate(int habitId, DateTime date)
```
Checks if a habit was completed on a specific date.

#### Delete Completion
```dart
Future<int> deleteCompletion(int id)
Future<int> deleteCompletionForDate(int habitId, DateTime date)
```
Removes completion records.

### Analytics Operations

#### Calculate Streak
```dart
Future<int> getStreakForHabit(int habitId)
```
Calculates current consecutive completion streak from today backwards.

#### Calculate Completion Rate
```dart
Future<double> getCompletionRateForHabit(int habitId, {int days = 30})
```
Returns completion percentage over specified period.

#### Get Habit Statistics
```dart
Future<Map<String, dynamic>> getHabitStats(int habitId, {int days = 30})
```
Returns comprehensive statistics including:
- Total completions
- Current streak
- Completion rate
- Completions in period

#### Get Overall App Statistics
```dart
Future<Map<String, dynamic>> getOverallStats()
```
Returns app-wide statistics:
- Active habits count
- Archived habits count
- Total completions
- Today's completions

## Query Patterns

### Common Queries

1. **Get today's completions:**
```sql
SELECT COUNT(*) FROM completions c 
JOIN habits h ON c.habit_id = h.id 
WHERE h.is_archived = 0 AND c.completion_date = '2024-01-15'
```

2. **Get habit with completion status for date:**
```sql
SELECT h.*, 
       CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END as is_completed
FROM habits h
LEFT JOIN completions c ON h.id = c.habit_id AND c.completion_date = '2024-01-15'
WHERE h.is_archived = 0
```

3. **Get completion counts by date:**
```sql
SELECT completion_date, COUNT(*) as count
FROM completions c
JOIN habits h ON c.habit_id = h.id
WHERE h.is_archived = 0 
  AND completion_date >= '2024-01-01' 
  AND completion_date <= '2024-01-31'
GROUP BY completion_date
```

## Performance Considerations

### Indexing Strategy
- **Primary indexes**: On frequently queried columns (habit_id, completion_date)
- **Composite indexes**: For multi-column queries (habit_id + completion_date)
- **Filtered indexes**: On is_archived for active habit queries

### Query Optimization
- Use prepared statements for repeated queries
- Limit result sets with date ranges where appropriate
- Leverage foreign key constraints for data integrity
- Use UNIQUE constraints to prevent duplicate data

### Data Types
- **TEXT for dates**: Using ISO8601 format for portability and readability
- **INTEGER for booleans**: 0/1 values with CHECK constraints
- **INTEGER PRIMARY KEY**: Auto-increment for efficient row IDs

## Migration Strategy

### Future Schema Changes
When adding new features, use ALTER TABLE statements:

```sql
-- Example: Adding priority field
ALTER TABLE habits ADD COLUMN priority INTEGER DEFAULT 1;

-- Example: Adding notes to completions
ALTER TABLE completions ADD COLUMN notes TEXT;
```

### Versioning
- Database version stored in SQLite schema
- Incremental migration scripts for each version
- Backward compatibility considerations

## Data Validation

### Application-Level Validation
- Habit name length (≤ 30 characters)
- Valid frequency values
- Color format validation (hex codes)
- Date format consistency

### Database-Level Constraints
- CHECK constraints for data integrity
- FOREIGN KEY constraints for referential integrity
- UNIQUE constraints to prevent duplicates
- NOT NULL constraints for required fields

## Backup and Recovery

### Export Format
```json
{
  "version": "1.0",
  "exported_at": "2024-01-15T10:30:00Z",
  "habits": [...],
  "completions": [...]
}
```

### Import Validation
- Schema version compatibility
- Data format validation
- Conflict resolution strategies
- Progress reporting

## Security Considerations

### Local Storage
- Database file permissions
- No sensitive personal data stored
- Local-only access (no network exposure)

### Data Privacy
- All data remains on device
- No external data transmission
- User controls all data lifecycle

---

## Example Usage

```dart
// Initialize database helper
final dbHelper = DatabaseHelper();

// Create a new habit
final habit = Habit(
  name: 'Daily Exercise',
  description: '30 minutes of physical activity',
  color: '#6366F1',
  icon: 'fitness_center',
  frequency: 'daily',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final habitId = await dbHelper.insertHabit(habit);

// Record completion
final completion = Completion(
  habitId: habitId,
  completionDate: DateTime.now(),
  createdAt: DateTime.now(),
);

await dbHelper.insertCompletion(completion);

// Get statistics
final stats = await dbHelper.getHabitStats(habitId);
print('Current streak: ${stats['currentStreak']} days');
```

This schema provides a solid foundation for the HabitTracker Pro application with efficient querying, data integrity, and room for future enhancements.