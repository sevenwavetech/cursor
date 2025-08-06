import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';

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
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        frequency TEXT NOT NULL DEFAULT 'daily',
        targetCount INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create habit_entries table
    await db.execute('''
      CREATE TABLE habit_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date INTEGER NOT NULL,
        completionCount INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE,
        UNIQUE(habitId, date)
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_habit_entries_date ON habit_entries(date)');
    await db.execute('CREATE INDEX idx_habit_entries_habit_id ON habit_entries(habitId)');
  }

  // Habit CRUD operations
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

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

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.update(
      'habits',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // HabitEntry CRUD operations
  Future<int> insertHabitEntry(HabitEntry entry) async {
    final db = await database;
    return await db.insert(
      'habit_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HabitEntry>> getHabitEntries(int habitId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = 'habitId = ?';
    List<dynamic> whereArgs = [habitId];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'habit_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => HabitEntry.fromMap(maps[i]));
  }

  Future<HabitEntry?> getHabitEntryForDate(int habitId, DateTime date) async {
    final db = await database;
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'habit_entries',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, dateOnly.millisecondsSinceEpoch],
    );

    if (maps.isNotEmpty) {
      return HabitEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateHabitEntry(HabitEntry entry) async {
    final db = await database;
    return await db.update(
      'habit_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteHabitEntry(int id) async {
    final db = await database;
    return await db.delete(
      'habit_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Analytics and statistics
  Future<int> getStreakCount(int habitId) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get habit to check target count
    final habit = await getHabit(habitId);
    if (habit == null) return 0;

    int streakCount = 0;
    DateTime checkDate = today;

    while (true) {
      final entry = await getHabitEntryForDate(habitId, checkDate);
      if (entry != null && entry.isCompleted(habit.targetCount)) {
        streakCount++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streakCount;
  }

  Future<Map<String, dynamic>> getHabitStats(int habitId, {int days = 30}) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final endDate = DateTime(now.year, now.month, now.day);

    final entries = await getHabitEntries(habitId, startDate: startDate, endDate: endDate);
    final habit = await getHabit(habitId);
    
    if (habit == null) {
      return {'completionRate': 0.0, 'totalCompletions': 0, 'streak': 0};
    }

    int completedDays = 0;
    int totalCompletions = 0;

    for (final entry in entries) {
      if (entry.isCompleted(habit.targetCount)) {
        completedDays++;
      }
      totalCompletions += entry.completionCount;
    }

    final completionRate = (completedDays / days) * 100;
    final streak = await getStreakCount(habitId);

    return {
      'completionRate': completionRate,
      'totalCompletions': totalCompletions,
      'streak': streak,
      'completedDays': completedDays,
    };
  }

  // Get all entries for a specific date (for calendar view)
  Future<List<Map<String, dynamic>>> getEntriesForDate(DateTime date) async {
    final db = await database;
    final dateOnly = DateTime(date.year, date.month, date.day);

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT h.*, e.completionCount, e.notes, e.id as entryId
      FROM habits h
      LEFT JOIN habit_entries e ON h.id = e.habitId AND e.date = ?
      WHERE h.isActive = 1
      ORDER BY h.createdAt DESC
    ''', [dateOnly.millisecondsSinceEpoch]);

    return result;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}