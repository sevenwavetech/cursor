import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CompletionTile extends StatefulWidget {
  final bool isCompleted;
  final Color habitColor;
  final VoidCallback onTap;
  final double size;

  const CompletionTile({
    super.key,
    required this.isCompleted,
    required this.habitColor,
    required this.onTap,
    this.size = AppConstants.tileSize,
  });

  @override
  State<CompletionTile> createState() => _CompletionTileState();
}

class _CompletionTileState extends State<CompletionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.shortAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Play tap animation
    await _animationController.forward();
    await _animationController.reverse();
    
    // Call the callback
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.isCompleted 
                    ? widget.habitColor 
                    : Colors.transparent,
                border: widget.isCompleted 
                    ? null 
                    : Border.all(
                        color: widget.habitColor,
                        width: 2.0,
                      ),
                borderRadius: BorderRadius.circular(
                  AppConstants.smallBorderRadius / 2,
                ),
              ),
              child: widget.isCompleted
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: widget.size * 0.6,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class TodayCompletionTiles extends StatelessWidget {
  final List<Map<String, dynamic>> habits;
  final Function(int habitId) onHabitToggle;

  const TodayCompletionTiles({
    super.key,
    required this.habits,
    required this.onHabitToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Icon(
                Icons.track_changes,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'No habits yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Create your first habit to get started',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Tiles grid
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: habits.map((habitData) {
                final habitColor = AppConstants.getColorByName(habitData['color']);
                final isCompleted = habitData['is_completed'] == 1;
                
                return Column(
                  children: [
                    CompletionTile(
                      isCompleted: isCompleted,
                      habitColor: habitColor,
                      onTap: () => onHabitToggle(habitData['id']),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: AppConstants.tileSize,
                      child: Text(
                        habitData['name'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Progress summary
            _buildProgressSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context) {
    final completedCount = habits.where((h) => h['is_completed'] == 1).length;
    final totalCount = habits.length;
    final percentage = totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$completedCount of $totalCount completed',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.smallPadding,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: percentage == 100 
                ? Colors.green.withOpacity(0.1)
                : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          ),
          child: Text(
            '${percentage.round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: percentage == 100 
                  ? Colors.green[700]
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}