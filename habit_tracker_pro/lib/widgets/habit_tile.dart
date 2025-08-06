import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';
import '../utils/date_helper.dart';
import 'progress_grid.dart';

class HabitTile extends StatefulWidget {
  final Habit habit;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitTile({
    super.key,
    required this.habit,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  int _currentStreak = 0;
  double _completionRate = 0.0;
  int _todayCompletions = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabitData();
  }

  Future<void> _loadHabitData() async {
    try {
      // Get streak count
      final streak = await _databaseHelper.getStreakCount(widget.habit.id!);
      
      // Get habit stats
      final stats = await _databaseHelper.getHabitStats(widget.habit.id!);
      
      // Get today's completions
      final todayEntry = await _databaseHelper.getHabitEntryForDate(
        widget.habit.id!,
        DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _currentStreak = streak;
          _completionRate = stats['completionRate'] ?? 0.0;
          _todayCompletions = todayEntry?.completionCount ?? 0;
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

  Future<void> _toggleHabit() async {
    try {
      final today = DateHelper.dateOnly(DateTime.now());
      final existingEntry = await _databaseHelper.getHabitEntryForDate(
        widget.habit.id!,
        today,
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
          habitId: widget.habit.id!,
          date: today,
          completionCount: 1,
          createdAt: DateTime.now(),
        );
        await _databaseHelper.insertHabitEntry(newEntry);
      }

      // Reload data
      await _loadHabitData();
      
      // Haptic feedback
      if (mounted && Theme.of(context).platform == TargetPlatform.iOS) {
        // iOS haptic feedback would go here if available
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating habit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = AppConstants.getColorByName(widget.habit.color);
    final habitIcon = AppConstants.getIconByName(widget.habit.icon);
    final isCompleted = _todayCompletions >= widget.habit.targetCount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, title, and menu
              Row(
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
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.habit.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.habit.description.isNotEmpty)
                          Text(
                            widget.habit.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          widget.onEdit?.call();
                          break;
                        case 'delete':
                          widget.onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Progress Grid
              if (!_isLoading)
                ProgressGrid(
                  habitId: widget.habit.id!,
                  habitColor: habitColor,
                  targetCount: widget.habit.targetCount,
                ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    'Streak',
                    '$_currentStreak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Rate',
                    '${_completionRate.toInt()}%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Today',
                    '$_todayCompletions/${widget.habit.targetCount}',
                    Icons.today,
                    habitColor,
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.green : habitColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.add_circle,
                    size: 20,
                  ),
                  label: Text(
                    isCompleted ? 'Completed!' : 'Mark Complete',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}