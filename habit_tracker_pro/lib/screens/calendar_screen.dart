import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/completion.dart';
import '../services/database_helper.dart';
import '../utils/design_system.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime _selectedMonth = DateTime.now();
  List<Habit> _habits = [];
  Map<String, List<Completion>> _completionsByDate = {};
  bool _isLoading = true;
  bool _isYearView = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load habits
      final habits = await _databaseHelper.getAllHabits();
      
      // Load completions for the selected month (or year if in year view)
      final startDate = _isYearView 
          ? DateTime(_selectedMonth.year, 1, 1)
          : DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = _isYearView 
          ? DateTime(_selectedMonth.year, 12, 31)
          : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final completionsByDate = <String, List<Completion>>{};
      
      for (final habit in habits) {
        final completions = await _databaseHelper.getCompletionsForHabit(habit.id!);
        
        // Filter completions for the date range
        final filteredCompletions = completions.where((completion) {
          final date = completion.completionDate;
          return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                 date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
        
        // Group by date string
        for (final completion in filteredCompletions) {
          final dateKey = _formatDateKey(completion.completionDate);
          completionsByDate[dateKey] = completionsByDate[dateKey] ?? [];
          completionsByDate[dateKey]!.add(completion);
        }
      }

      if (mounted) {
        setState(() {
          _habits = habits;
          _completionsByDate = completionsByDate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calendar data: $e')),
        );
      }
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _previousPeriod() {
    setState(() {
      if (_isYearView) {
        _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      }
    });
    _loadData();
  }

  void _nextPeriod() {
    setState(() {
      if (_isYearView) {
        _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      }
    });
    _loadData();
  }

  void _toggleView() {
    setState(() {
      _isYearView = !_isYearView;
    });
    _loadData();
  }

  String _getHeaderTitle() {
    if (_isYearView) {
      return _selectedMonth.year.toString();
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: DesignSystem.largeTitle.copyWith(
            color: context.textColor,
            fontSize: 28, // Slightly smaller for app bar
          ),
        ),
        actions: [
          // View toggle button
          IconButton(
            onPressed: _toggleView,
            icon: Icon(_isYearView ? Icons.calendar_view_month : Icons.calendar_view_week),
            tooltip: _isYearView ? 'Month View' : 'Year View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header controls
          _buildHeaderControls(),
          
          // Calendar content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _habits.isEmpty
                    ? _buildEmptyState()
                    : _isYearView
                        ? _buildYearView()
                        : _buildMonthView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderControls() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignSystem.screenMargin,
        vertical: DesignSystem.spacingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            onPressed: _previousPeriod,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: context.surfaceColor,
              minimumSize: const Size(44, 44),
            ),
          ),
          
          // Title
          Text(
            _getHeaderTitle(),
            style: DesignSystem.title1.copyWith(
              color: context.textColor,
            ),
          ),
          
          // Next button
          IconButton(
            onPressed: _nextPeriod,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: context.surfaceColor,
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
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
            Icons.calendar_today,
            size: 80,
            color: context.secondaryTextColor.withOpacity(0.5),
          ),
          SizedBox(height: DesignSystem.spacingLarge),
          Text(
            'No habits to track',
            style: DesignSystem.title1.copyWith(
              color: context.textColor,
            ),
          ),
          SizedBox(height: DesignSystem.spacingSmall),
          Text(
            'Create some habits to see your progress here!',
            textAlign: TextAlign.center,
            style: DesignSystem.body.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignSystem.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar grid
          _buildCalendarGrid(),
          
          SizedBox(height: DesignSystem.spacingLarge),
          
          // Habit legend
          if (_habits.isNotEmpty) _buildHabitLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
      ),
      padding: EdgeInsets.all(DesignSystem.spacingMedium),
      child: Column(
        children: [
          // Day headers (Sun-Sat)
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: DesignSystem.caption.copyWith(
                            color: context.secondaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          
          SizedBox(height: DesignSystem.spacingSmall),
          
          // Calendar days
          ...List.generate((daysInMonth + firstWeekday + 6) ~/ 7, (weekIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: DesignSystem.spacingSmall),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                  
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 60));
                  }
                  
                  return Expanded(
                    child: _buildCalendarDay(dayNumber),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(int day) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    final dateKey = _formatDateKey(date);
    final completions = _completionsByDate[dateKey] ?? [];
    final isToday = _isToday(date);
    
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: DesignSystem.spacingMicro),
      decoration: BoxDecoration(
        color: isToday 
            ? DesignSystem.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
        border: isToday 
            ? Border.all(color: DesignSystem.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number
          Text(
            day.toString(),
            style: DesignSystem.body.copyWith(
              color: isToday 
                  ? DesignSystem.primary 
                  : context.textColor,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          
          SizedBox(height: DesignSystem.spacingMicro),
          
          // Completion dots
          if (completions.isNotEmpty) _buildCompletionDots(completions),
        ],
      ),
    );
  }

  Widget _buildCompletionDots(List<Completion> completions) {
    // Group completions by habit to get unique colors
    final habitIds = completions.map((c) => c.habitId).toSet().toList();
    final maxDots = 3; // Show max 3 dots
    
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: habitIds.take(maxDots).map((habitId) {
        final habit = _habits.firstWhere((h) => h.id == habitId);
        final color = DesignSystem.getHabitColor(habit.color);
        
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }).toList()
        ..addAll(
          habitIds.length > maxDots
              ? [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.secondaryTextColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ]
              : [],
        ),
    );
  }

  Widget _buildYearView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignSystem.screenMargin),
      child: Column(
        children: [
          // Year heat map grid (12 months)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              return _buildMonthHeatMap(index + 1);
            },
          ),
          
          SizedBox(height: DesignSystem.spacingLarge),
          
          // Habit legend
          if (_habits.isNotEmpty) _buildHabitLegend(),
        ],
      ),
    );
  }

  Widget _buildMonthHeatMap(int month) {
    final monthDate = DateTime(_selectedMonth.year, month);
    final monthName = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
    
    final daysInMonth = DateTime(_selectedMonth.year, month + 1, 0).day;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMonth = monthDate;
          _isYearView = false;
        });
        _loadData();
      },
      child: Container(
        padding: EdgeInsets.all(DesignSystem.spacingSmall),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
        ),
        child: Column(
          children: [
            Text(
              monthName,
              style: DesignSystem.body.copyWith(
                color: context.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DesignSystem.spacingSmall),
            
            // Mini heat map
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, dayIndex) {
                  final day = dayIndex + 1;
                  final date = DateTime(_selectedMonth.year, month, day);
                  final dateKey = _formatDateKey(date);
                  final completions = _completionsByDate[dateKey] ?? [];
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: completions.isEmpty
                          ? context.secondaryTextColor.withOpacity(0.1)
                          : DesignSystem.success.withOpacity(
                              (completions.length / _habits.length).clamp(0.3, 1.0)
                            ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitLegend() {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacingMedium),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habits',
            style: DesignSystem.headline.copyWith(
              color: context.textColor,
            ),
          ),
          SizedBox(height: DesignSystem.spacingMedium),
          
          ...(_habits.map((habit) {
            final color = DesignSystem.getHabitColor(habit.color);
            return Padding(
              padding: EdgeInsets.only(bottom: DesignSystem.spacingSmall),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: DesignSystem.spacingSmall),
                  Text(
                    habit.name,
                    style: DesignSystem.body.copyWith(
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}