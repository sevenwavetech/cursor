import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/design_system.dart';

/// Completion tile widget following the design system specifications
/// 32pt x 32pt with 6pt border radius, bounce animation on tap
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
    this.size = DesignSystem.tileSize,
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
      duration: DesignSystem.animationFast,
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
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Play tap animation (scale to 0.8 then back to 1.0 with bounce)
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
                // Completed: solid fill with habit color
                // Empty: transparent fill with 2pt border in habit color
                color: widget.isCompleted 
                    ? widget.habitColor 
                    : Colors.transparent,
                border: widget.isCompleted 
                    ? null 
                    : Border.all(
                        color: widget.habitColor,
                        width: 2.0,
                      ),
                borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
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

/// Habit card widget following the design system specifications
/// 80pt height with habit icon, name, streak info, and completion tile
class HabitCard extends StatelessWidget {
  final Map<String, dynamic> habitData;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final int streak;

  const HabitCard({
    super.key,
    required this.habitData,
    required this.onTap,
    this.onEdit,
    this.onArchive,
    this.streak = 0,
  });

  @override
  Widget build(BuildContext context) {
    final habitColor = DesignSystem.getHabitColor(habitData['color']);
    final isCompleted = habitData['is_completed'] == 1;
    
    return Dismissible(
      key: Key('habit_${habitData['id']}'),
      background: _buildSwipeBackground(
        color: DesignSystem.primary,
        icon: Icons.edit,
        label: 'Edit',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: DesignSystem.warning,
        icon: Icons.archive,
        label: 'Archive',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
        } else if (direction == DismissDirection.endToStart) {
          onArchive?.call();
        }
        return false; // Don't actually dismiss
      },
      child: Container(
        height: DesignSystem.cardHeight,
        margin: EdgeInsets.symmetric(
          horizontal: DesignSystem.screenMargin,
          vertical: DesignSystem.spacingSmall / 2,
        ),
        padding: EdgeInsets.all(DesignSystem.spacingMedium),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
        ),
        child: Row(
          children: [
            // Left: Habit icon (40pt circle with habit color)
            Container(
              width: DesignSystem.habitIconSize,
              height: DesignSystem.habitIconSize,
              decoration: BoxDecoration(
                color: habitColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getHabitIcon(habitData['icon']),
                color: Colors.white,
                size: 24,
              ),
            ),
            
            SizedBox(width: DesignSystem.spacingMedium),
            
            // Middle: Habit name, streak info, weekly progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Habit name (18pt semibold)
                  Text(
                    habitData['name'],
                    style: DesignSystem.headline.copyWith(
                      color: context.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: DesignSystem.spacingMicro),
                  
                  // Streak info (14pt regular)
                  Text(
                    streak > 0 ? '$streak day streak' : 'No streak yet',
                    style: DesignSystem.body.copyWith(
                      fontSize: 14,
                      color: streak > 0 
                          ? DesignSystem.success 
                          : context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: DesignSystem.spacingMedium),
            
            // Right: Today's completion tile (32pt square, tappable)
            CompletionTile(
              isCompleted: isCompleted,
              habitColor: habitColor,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignSystem.screenMargin,
        vertical: DesignSystem.spacingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              SizedBox(height: DesignSystem.spacingMicro),
              Text(
                label,
                style: DesignSystem.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getHabitIcon(String iconName) {
    // Map icon names to actual icons
    switch (iconName) {
      case 'fitness_center': return Icons.fitness_center;
      case 'local_drink': return Icons.local_drink;
      case 'book': return Icons.book;
      case 'bedtime': return Icons.bedtime;
      case 'directions_run': return Icons.directions_run;
      case 'self_improvement': return Icons.self_improvement;
      case 'music_note': return Icons.music_note;
      case 'palette': return Icons.palette;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      default: return Icons.track_changes;
    }
  }
}