import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';
import '../utils/date_helper.dart';
import '../widgets/progress_grid.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  List<Habit> _habits = [];
  Map<String, dynamic> _dayData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadHabits();
    await _loadDayData();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _databaseHelper.getAllHabits();
      if (mounted) {
        setState(() {
          _habits = habits;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading habits: $e')),
        );
      }
    }
  }

  Future<void> _loadDayData() async {
    try {
      final entries = await _databaseHelper.getEntriesForDate(_selectedDate);
      if (mounted) {
        setState(() {
          _dayData = {};
          for (final entry in entries) {
            _dayData[entry['id'].toString()] = entry;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleHabitForDate(Habit habit) async {
    try {
      final existingEntry = await _databaseHelper.getHabitEntryForDate(
        habit.id!,
        _selectedDate,
      );

      if (existingEntry != null) {
        // Increment completion count
        final newCount = existingEntry.completionCount + 1;
        final updatedEntry = existingEntry.copyWith(
          completionCount: newCount,
        );
        await _databaseHelper.updateHabitEntry(updatedEntry);
      } else {
        // Create new entry
        final newEntry = HabitEntry(
          habitId: habit.id!,
          date: _selectedDate,
          completionCount: 1,
          createdAt: DateTime.now(),
        );
        await _databaseHelper.insertHabitEntry(newEntry);
      }

      await _loadDayData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating habit: $e')),
        );
      }
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateHelper.dateOnly(date);
      _isLoading = true;
    });
    _loadDayData();
  }

  void _changeMonth(int monthOffset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + monthOffset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _selectedDate = DateHelper.dateOnly(today);
                _currentMonth = DateTime(today.year, today.month, 1);
                _isLoading = true;
              });
              _loadDayData();
            },
            tooltip: 'Go to today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Header
          _buildCalendarHeader(),
          
          // Calendar Grid
          _buildCalendarGrid(),
          
          // Selected Date Info
          _buildSelectedDateInfo(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${DateHelper.getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final weeks = DateHelper.getWeeksInMonth(_currentMonth);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Day labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            
            // Calendar days
            ...weeks.map((week) => _buildWeekRow(week)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRow(List<DateTime> week) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: week.map((date) => _buildDayTile(date)).toList(),
      ),
    );
  }

  Widget _buildDayTile(DateTime date) {
    final isCurrentMonth = date.month == _currentMonth.month;
    final isSelected = DateHelper.isSameDay(date, _selectedDate);
    final isToday = DateHelper.isToday(date);
    final isFuture = date.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () => _selectDate(date),
      child: FutureBuilder<int>(
        future: _getCompletedHabitsForDate(date),
        builder: (context, snapshot) {
          final completedCount = snapshot.data ?? 0;
          final hasData = completedCount > 0;
          
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : hasData && isCurrentMonth
                      ? Colors.green.withOpacity(0.2)
                      : null,
              border: isToday
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isCurrentMonth
                              ? (isFuture ? Colors.grey : Colors.black)
                              : Colors.grey[400],
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasData && isCurrentMonth && !isSelected)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDateInfo() {
    return Expanded(
      child: Column(
        children: [
          // Selected date header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  DateHelper.formatDateReadable(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Habits for selected date
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _habits.isEmpty
                    ? const Center(
                        child: Text('No habits to track'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                        itemCount: _habits.length,
                        itemBuilder: (context, index) {
                          final habit = _habits[index];
                          return _buildHabitCard(habit);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final habitData = _dayData[habit.id.toString()];
    final completionCount = habitData?['completionCount'] ?? 0;
    final isCompleted = completionCount >= habit.targetCount;
    final habitColor = AppConstants.getColorByName(habit.color);
    final habitIcon = AppConstants.getIconByName(habit.icon);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: habitColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
              ),
              child: Icon(
                habitIcon,
                color: habitColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$completionCount / ${habit.targetCount} completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCompleted ? Colors.green : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  // Mini progress grid
                  CompactProgressGrid(
                    habitId: habit.id!,
                    habitColor: habitColor,
                    targetCount: habit.targetCount,
                    days: 7,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _toggleHabitForDate(habit),
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.add_circle_outline,
                color: isCompleted ? Colors.green : habitColor,
              ),
              tooltip: isCompleted ? 'Completed' : 'Mark complete',
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getCompletedHabitsForDate(DateTime date) async {
    if (_habits.isEmpty) return 0;
    
    int completed = 0;
    for (final habit in _habits) {
      final entry = await _databaseHelper.getHabitEntryForDate(habit.id!, date);
      if (entry != null && entry.isCompleted(habit.targetCount)) {
        completed++;
      }
    }
    return completed;
  }
}