import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/completion.dart';
import '../services/database_helper.dart';
import '../widgets/completion_tile.dart';
import '../utils/design_system.dart';
import 'add_habit_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _habitsWithCompletion = [];
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final today = DateTime.now();
      final habitsData = await _databaseHelper.getHabitsWithCompletionForDate(today);
      
      // Get streaks for each habit
      final habitsWithStreaks = <Map<String, dynamic>>[];
      for (final habitData in habitsData) {
        final streak = await _databaseHelper.getStreakForHabit(habitData['id']);
        final habitWithStreak = Map<String, dynamic>.from(habitData);
        habitWithStreak['streak'] = streak;
        habitsWithStreaks.add(habitWithStreak);
      }

      if (mounted) {
        setState(() {
          _habitsWithCompletion = habitsWithStreaks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading habits: $e')),
        );
      }
    }
  }

  Future<void> _toggleHabitCompletion(int habitId) async {
    try {
      final today = DateTime.now();
      final existingCompletion = await _databaseHelper.getCompletionForDate(habitId, today);

      if (existingCompletion != null) {
        // Remove completion
        await _databaseHelper.deleteCompletion(existingCompletion.id!);
      } else {
        // Add completion
        final completion = Completion(
          habitId: habitId,
          completionDate: today,
          createdAt: DateTime.now(),
        );
        await _databaseHelper.insertCompletion(completion);
      }

      // Reload data
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating habit: $e')),
        );
      }
    }
  }

  Future<void> _addHabit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHabitScreen(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _editHabit(Map<String, dynamic> habitData) async {
    final habit = Habit.fromMap(habitData);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddHabitScreen(habit: habit),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _archiveHabit(Map<String, dynamic> habitData) async {
    final confirmed = await _showArchiveConfirmation(habitData['name']);
    if (confirmed == true) {
      try {
        await _databaseHelper.archiveHabit(habitData['id']);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${habitData['name']} archived')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error archiving habit: $e')),
          );
        }
      }
    }
  }

  Future<bool?> _showArchiveConfirmation(String habitName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Habit'),
        content: Text('Are you sure you want to archive "$habitName"? You can restore it later from Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header with greeting and add button
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignSystem.screenMargin,
                    MediaQuery.of(context).padding.top + DesignSystem.spacingMedium,
                    DesignSystem.screenMargin,
                    DesignSystem.spacingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting text (Large Title - 34pt Bold)
                      Text(
                        _getGreeting(),
                        style: DesignSystem.largeTitle.copyWith(
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacingMicro),
                      // Current date display
                      Text(
                        _getCurrentDate(),
                        style: DesignSystem.body.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Add habit button (+ icon, top-right)
                Padding(
                  padding: EdgeInsets.only(right: DesignSystem.screenMargin),
                  child: IconButton(
                    onPressed: _addHabit,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: DesignSystem.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                ),
              ],
            ),
            
            // Habit cards list
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_habitsWithCompletion.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habitData = _habitsWithCompletion[index];
                    return HabitCard(
                      habitData: habitData,
                      streak: habitData['streak'] ?? 0,
                      onTap: () => _toggleHabitCompletion(habitData['id']),
                      onEdit: () => _editHabit(habitData),
                      onArchive: () => _archiveHabit(habitData),
                    );
                  },
                  childCount: _habitsWithCompletion.length,
                ),
              ),
            
            // Bottom padding for safe area
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + DesignSystem.spacingLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(DesignSystem.spacingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 80,
            color: context.secondaryTextColor.withOpacity(0.5),
          ),
          SizedBox(height: DesignSystem.spacingLarge),
          Text(
            'No habits yet',
            style: DesignSystem.title1.copyWith(
              color: context.textColor,
            ),
          ),
          SizedBox(height: DesignSystem.spacingSmall),
          Text(
            'Start building better habits by creating your first one!',
            textAlign: TextAlign.center,
            style: DesignSystem.body.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          SizedBox(height: DesignSystem.spacingLarge),
          ElevatedButton.icon(
            onPressed: _addHabit,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Habit'),
          ),
        ],
      ),
    );
  }
}