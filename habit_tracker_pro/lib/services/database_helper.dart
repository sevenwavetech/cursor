import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/completion.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'habit_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create habits table
    await db.execute('''
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
      )
    ''');

    // Create completions table
    await db.execute('''
      CREATE TABLE completions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        completion_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
        UNIQUE(habit_id, completion_date)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_habits_is_archived ON habits(is_archived)');
    await db.execute('CREATE INDEX idx_completions_habit_id ON completions(habit_id)');
    await db.execute('CREATE INDEX idx_completions_date ON completions(completion_date)');
    await db.execute('CREATE INDEX idx_completions_habit_date ON completions(habit_id, completion_date)');
  }

  // HABIT CRUD OPERATIONS

  /// Insert a new habit into the database
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  /// Get all habits (non-archived by default)
  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: includeArchived ? null : 'is_archived = ?',
      whereArgs: includeArchived ? null : [0],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  /// Get a specific habit by ID
  Future<Habit?> getHabit(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  /// Update an existing habit
  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'habits',
      updatedHabit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Permanently delete a habit and all its completions
  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Archive/unarchive a habit
  Future<int> archiveHabit(int id, {bool archive = true}) async {
    final db = await database;
    return await db.update(
      'habits',
      {
        'is_archived': archive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COMPLETION CRUD OPERATIONS

  /// Insert a new completion
  Future<int> insertCompletion(Completion completion) async {
    final db = await database;
    return await db.insert(
      'completions',
      completion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all completions for a specific habit
  Future<List<Completion>> getCompletionsForHabit(
    int habitId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = 'habit_id = ?';
    List<dynamic> whereArgs = [habitId];

    if (startDate != null) {
      whereClause += ' AND completion_date >= ?';
      whereArgs.add(_formatDateOnly(startDate));
    }

    if (endDate != null) {
      whereClause += ' AND completion_date <= ?';
      whereArgs.add(_formatDateOnly(endDate));
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'completions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'completion_date DESC',
    );

    return List.generate(maps.length, (i) => Completion.fromMap(maps[i]));
  }

  /// Get completion for a specific habit on a specific date
  Future<Completion?> getCompletionForDate(int habitId, DateTime date) async {
    final db = await database;
    final dateStr = _formatDateOnly(date);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'completions',
      where: 'habit_id = ? AND completion_date = ?',
      whereArgs: [habitId, dateStr],
    );

    if (maps.isNotEmpty) {
      return Completion.fromMap(maps.first);
    }
    return null;
  }

  /// Delete a specific completion
  Future<int> deleteCompletion(int id) async {
    final db = await database;
    return await db.delete(
      'completions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete completion for a specific habit on a specific date
  Future<int> deleteCompletionForDate(int habitId, DateTime date) async {
    final db = await database;
    final dateStr = _formatDateOnly(date);
    return await db.delete(
      'completions',
      where: 'habit_id = ? AND completion_date = ?',
      whereArgs: [habitId, dateStr],
    );
  }

  // ANALYTICS AND STATISTICS

  /// Calculate current streak for a habit
  Future<int> getStreakForHabit(int habitId) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get all completions for this habit, ordered by date descending
    final completions = await getCompletionsForHabit(habitId);
    
    if (completions.isEmpty) return 0;
    
    int streak = 0;
    DateTime checkDate = today;
    
    // Convert completions to a set of dates for faster lookup
    final completionDates = completions
        .map((c) => DateTime(c.completionDate.year, c.completionDate.month, c.completionDate.day))
        .toSet();
    
    // Count consecutive days from today backwards
    while (completionDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  /// Calculate completion rate for a habit over a specified period
  Future<double> getCompletionRateForHabit(
    int habitId, {
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));
    
    final completions = await getCompletionsForHabit(
      habitId,
      startDate: startDate,
      endDate: endDate,
    );
    
    if (days == 0) return 0.0;
    
    return (completions.length / days) * 100;
  }

  /// Get habit statistics
  Future<Map<String, dynamic>> getHabitStats(int habitId, {int days = 30}) async {
    final completions = await getCompletionsForHabit(habitId);
    final streak = await getStreakForHabit(habitId);
    final completionRate = await getCompletionRateForHabit(habitId, days: days);
    
    return {
      'totalCompletions': completions.length,
      'currentStreak': streak,
      'completionRate': completionRate,
      'completionsInPeriod': completions
          .where((c) => c.completionDate.isAfter(
              DateTime.now().subtract(Duration(days: days))))
          .length,
    };
  }

  /// Get all habits with their completion status for a specific date
  Future<List<Map<String, dynamic>>> getHabitsWithCompletionForDate(DateTime date) async {
    final db = await database;
    final dateStr = _formatDateOnly(date);

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT h.*, 
             c.id as completion_id,
             c.completion_date,
             c.created_at as completion_created_at,
             CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END as is_completed
      FROM habits h
      LEFT JOIN completions c ON h.id = c.habit_id AND c.completion_date = ?
      WHERE h.is_archived = 0
      ORDER BY h.created_at DESC
    ''', [dateStr]);

    return result;
  }

  /// Get completion count for each day in a date range
  Future<Map<String, int>> getCompletionCountsByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final startDateStr = _formatDateOnly(startDate);
    final endDateStr = _formatDateOnly(endDate);

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT completion_date, COUNT(*) as count
      FROM completions c
      JOIN habits h ON c.habit_id = h.id
      WHERE h.is_archived = 0 
        AND completion_date >= ? 
        AND completion_date <= ?
      GROUP BY completion_date
      ORDER BY completion_date
    ''', [startDateStr, endDateStr]);

    final Map<String, int> counts = {};
    for (final row in result) {
      counts[row['completion_date']] = row['count'];
    }
    return counts;
  }

  /// Get overall app statistics
  Future<Map<String, dynamic>> getOverallStats() async {
    final db = await database;
    
    final habitsCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM habits WHERE is_archived = 0'
    )) ?? 0;
    
    final archivedHabitsCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM habits WHERE is_archived = 1'
    )) ?? 0;
    
    final totalCompletions = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM completions c JOIN habits h ON c.habit_id = h.id WHERE h.is_archived = 0'
    )) ?? 0;
    
    final todayCompletions = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM completions c JOIN habits h ON c.habit_id = h.id WHERE h.is_archived = 0 AND c.completion_date = ?',
      [_formatDateOnly(DateTime.now())]
    )) ?? 0;
    
    return {
      'activeHabits': habitsCount,
      'archivedHabits': archivedHabitsCount,
      'totalCompletions': totalCompletions,
      'todayCompletions': todayCompletions,
    };
  }

  // UTILITY METHODS

  /// Format date as YYYY-MM-DD string
  String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Reset database (for testing purposes)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'habit_tracker.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}