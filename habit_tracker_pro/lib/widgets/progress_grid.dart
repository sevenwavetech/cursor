import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/habit_entry.dart';
import '../utils/constants.dart';
import '../utils/date_helper.dart';

class ProgressGrid extends StatefulWidget {
  final int habitId;
  final Color habitColor;
  final int targetCount;
  final int days;

  const ProgressGrid({
    super.key,
    required this.habitId,
    required this.habitColor,
    required this.targetCount,
    this.days = 28, // Show last 4 weeks by default
  });

  @override
  State<ProgressGrid> createState() => _ProgressGridState();
}

class _ProgressGridState extends State<ProgressGrid> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<DateTime, HabitEntry> _entries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: widget.days - 1));
      
      final entries = await _databaseHelper.getHabitEntries(
        widget.habitId,
        startDate: startDate,
        endDate: endDate,
      );

      final entriesMap = <DateTime, HabitEntry>{};
      for (final entry in entries) {
        entriesMap[DateHelper.dateOnly(entry.date)] = entry;
      }

      if (mounted) {
        setState(() {
          _entries = entriesMap;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final endDate = DateTime.now();
    final dates = DateHelper.getDateRange(endDate, widget.days);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Last ${widget.days} days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        
        // Week day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            return SizedBox(
              width: AppConstants.tileSize,
              child: Text(
                DateHelper.getShortDayName(index + 1).substring(0, 1),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        
        // Progress grid
        _buildProgressGrid(dates),
      ],
    );
  }

  Widget _buildProgressGrid(List<DateTime> dates) {
    final rows = <Widget>[];
    
    // Group dates into weeks (rows of 7)
    for (int i = 0; i < dates.length; i += 7) {
      final weekDates = dates.skip(i).take(7).toList();
      
      // Pad the week if it's incomplete (for the first week)
      while (weekDates.length < 7) {
        weekDates.insert(0, weekDates.first.subtract(const Duration(days: 1)));
      }
      
      rows.add(_buildWeekRow(weekDates));
    }
    
    return Column(
      children: rows,
    );
  }

  Widget _buildWeekRow(List<DateTime> weekDates) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.tileSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDates.map((date) => _buildTile(date)).toList(),
      ),
    );
  }

  Widget _buildTile(DateTime date) {
    final entry = _entries[DateHelper.dateOnly(date)];
    final completionCount = entry?.completionCount ?? 0;
    final isToday = DateHelper.isToday(date);
    final isFuture = date.isAfter(DateTime.now());
    
    Color tileColor;
    if (isFuture) {
      tileColor = Colors.grey[200]!;
    } else {
      tileColor = AppConstants.getStreakColor(completionCount, widget.targetCount);
    }

    return Tooltip(
      message: _buildTooltipMessage(date, completionCount),
      child: Container(
        width: AppConstants.tileSize,
        height: AppConstants.tileSize,
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius / 2),
          border: isToday ? Border.all(color: widget.habitColor, width: 2) : null,
        ),
        child: completionCount > 0 && completionCount >= widget.targetCount
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
            : completionCount > 0
                ? Center(
                    child: Text(
                      completionCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
      ),
    );
  }

  String _buildTooltipMessage(DateTime date, int completionCount) {
    final dateStr = DateHelper.formatDateReadable(date);
    
    if (date.isAfter(DateTime.now())) {
      return dateStr;
    }
    
    if (completionCount == 0) {
      return '$dateStr\nNo completions';
    } else if (completionCount >= widget.targetCount) {
      return '$dateStr\nCompleted ($completionCount/${widget.targetCount})';
    } else {
      return '$dateStr\nPartial ($completionCount/${widget.targetCount})';
    }
  }
}

// Compact version for smaller spaces
class CompactProgressGrid extends StatelessWidget {
  final int habitId;
  final Color habitColor;
  final int targetCount;
  final int days;

  const CompactProgressGrid({
    super.key,
    required this.habitId,
    required this.habitColor,
    required this.targetCount,
    this.days = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.tileSize,
      child: FutureBuilder<List<HabitEntry>>(
        future: _loadEntries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final entries = snapshot.data!;
          final entriesMap = <DateTime, HabitEntry>{};
          for (final entry in entries) {
            entriesMap[DateHelper.dateOnly(entry.date)] = entry;
          }

          final endDate = DateTime.now();
          final dates = DateHelper.getDateRange(endDate, days);

          return Row(
            children: dates.map((date) {
              final entry = entriesMap[DateHelper.dateOnly(date)];
              final completionCount = entry?.completionCount ?? 0;
              final isFuture = date.isAfter(DateTime.now());
              
              Color tileColor;
              if (isFuture) {
                tileColor = Colors.grey[200]!;
              } else {
                tileColor = AppConstants.getStreakColor(completionCount, targetCount);
              }

              return Container(
                width: AppConstants.tileSize * 0.6,
                height: AppConstants.tileSize * 0.6,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<List<HabitEntry>> _loadEntries() async {
    final databaseHelper = DatabaseHelper();
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));
    
    return await databaseHelper.getHabitEntries(
      habitId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}