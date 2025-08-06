import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';
import '../utils/design_system.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, dynamic> _stats = {};
  List<Habit> _archivedHabits = [];
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;

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
      // Load overall statistics
      final stats = await _databaseHelper.getOverallStats();
      
      // Load archived habits
      final allHabits = await _databaseHelper.getAllHabits(includeArchived: true);
      final archivedHabits = allHabits.where((h) => h.isArchived).toList();

      if (mounted) {
        setState(() {
          _stats = stats;
          _archivedHabits = archivedHabits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _restoreHabit(Habit habit) async {
    try {
      final updatedHabit = habit.copyWith(isArchived: false, updatedAt: DateTime.now());
      await _databaseHelper.updateHabit(updatedHabit);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${habit.name} restored')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring habit: $e')),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteHabit(Habit habit) async {
    final confirmed = await _showDeleteConfirmation(habit.name);
    if (confirmed == true) {
      try {
        await _databaseHelper.deleteHabit(habit.id!);
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${habit.name} permanently deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting habit: $e')),
          );
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(String habitName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit Permanently'),
        content: Text(
          'Are you sure you want to permanently delete "$habitName"? This will also delete all completion data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DesignSystem.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export coming soon!')),
    );
  }

  Future<void> _importData() async {
    // TODO: Implement data import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data import coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: DesignSystem.largeTitle.copyWith(
            color: context.textColor,
            fontSize: 28, // Slightly smaller for app bar
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(DesignSystem.screenMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Statistics
                  _buildAppStatistics(),
                  SizedBox(height: DesignSystem.spacingLarge),

                  // Habit Management
                  _buildHabitManagement(),
                  SizedBox(height: DesignSystem.spacingLarge),

                  // Data & Privacy
                  _buildDataPrivacy(),
                  SizedBox(height: DesignSystem.spacingLarge),

                  // App Preferences
                  _buildAppPreferences(),
                  SizedBox(height: DesignSystem.spacingLarge),

                  // About
                  _buildAbout(),
                ],
              ),
            ),
    );
  }

  Widget _buildAppStatistics() {
    return _buildSection(
      title: 'Statistics',
      icon: Icons.analytics,
      child: Column(
        children: [
          _buildStatRow(
            'Total Habits Created',
            _stats['total_habits']?.toString() ?? '0',
            Icons.track_changes,
            DesignSystem.primary,
          ),
          _buildStatRow(
            'Days Tracked',
            _stats['total_days_tracked']?.toString() ?? '0',
            Icons.calendar_today,
            DesignSystem.success,
          ),
          _buildStatRow(
            'Total Completions',
            _stats['total_completions']?.toString() ?? '0',
            Icons.check_circle,
            DesignSystem.warning,
          ),
          _buildStatRow(
            'Current Streak',
            _stats['longest_streak']?.toString() ?? '0',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitManagement() {
    return _buildSection(
      title: 'Habit Management',
      icon: Icons.manage_accounts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_archivedHabits.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: DesignSystem.spacingMedium),
              child: Text(
                'No archived habits',
                style: DesignSystem.body.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archived Habits (${_archivedHabits.length})',
                  style: DesignSystem.body.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: DesignSystem.spacingSmall),
                
                ...(_archivedHabits.map((habit) => _buildArchivedHabitTile(habit))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildArchivedHabitTile(Habit habit) {
    final habitColor = DesignSystem.getHabitColor(habit.color);
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignSystem.spacingSmall),
      padding: EdgeInsets.all(DesignSystem.spacingMedium),
      decoration: BoxDecoration(
        color: context.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
        border: Border.all(
          color: context.secondaryTextColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: habitColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getHabitIcon(habit.icon),
              color: habitColor,
              size: 16,
            ),
          ),
          SizedBox(width: DesignSystem.spacingMedium),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: DesignSystem.body.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (habit.description != null)
                  Text(
                    habit.description!,
                    style: DesignSystem.caption.copyWith(
                      color: context.secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Action buttons
          IconButton(
            onPressed: () => _restoreHabit(habit),
            icon: const Icon(Icons.restore),
            tooltip: 'Restore',
            style: IconButton.styleFrom(
              foregroundColor: DesignSystem.success,
            ),
          ),
          IconButton(
            onPressed: () => _permanentlyDeleteHabit(habit),
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete Permanently',
            style: IconButton.styleFrom(
              foregroundColor: DesignSystem.destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacy() {
    return _buildSection(
      title: 'Data & Privacy',
      icon: Icons.security,
      child: Column(
        children: [
          _buildSettingsTile(
            title: 'Export Data',
            subtitle: 'Save your habits and progress',
            icon: Icons.download,
            onTap: _exportData,
          ),
          _buildSettingsTile(
            title: 'Import Data',
            subtitle: 'Restore from backup',
            icon: Icons.upload,
            onTap: _importData,
          ),
          _buildSettingsTile(
            title: 'Clear All Data',
            subtitle: 'Reset the app to initial state',
            icon: Icons.warning,
            iconColor: DesignSystem.destructive,
            onTap: _showClearDataConfirmation,
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences() {
    return _buildSection(
      title: 'App Preferences',
      icon: Icons.tune,
      child: Column(
        children: [
          _buildThemeSelector(),
          _buildSettingsTile(
            title: 'Notifications',
            subtitle: 'Manage reminder settings',
            icon: Icons.notifications,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications settings coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacingMedium),
      child: Row(
        children: [
          Icon(
            Icons.palette,
            color: context.secondaryTextColor,
            size: 24,
          ),
          SizedBox(width: DesignSystem.spacingMedium),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: DesignSystem.body.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Choose app appearance',
                  style: DesignSystem.caption.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.auto_mode, size: 16),
              ),
            ],
            selected: {_themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              setState(() {
                _themeMode = selection.first;
              });
              // TODO: Implement theme persistence
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme preference saved!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return _buildSection(
      title: 'About',
      icon: Icons.info,
      child: Column(
        children: [
          _buildSettingsTile(
            title: 'Version',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
            showArrow: false,
          ),
          _buildSettingsTile(
            title: 'Privacy Policy',
            subtitle: 'Learn how we protect your data',
            icon: Icons.privacy_tip,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon!')),
              );
            },
          ),
          _buildSettingsTile(
            title: 'Terms of Service',
            subtitle: 'App usage terms and conditions',
            icon: Icons.description,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of service coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacingMedium),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: DesignSystem.primary,
                  size: 20,
                ),
                SizedBox(width: DesignSystem.spacingSmall),
                Text(
                  title,
                  style: DesignSystem.headline.copyWith(
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignSystem.spacingMedium,
        vertical: DesignSystem.spacingSmall,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: DesignSystem.spacingMedium),
          
          Expanded(
            child: Text(
              label,
              style: DesignSystem.body.copyWith(
                color: context.textColor,
              ),
            ),
          ),
          
          Text(
            value,
            style: DesignSystem.body.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacingMedium),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? context.secondaryTextColor,
              size: 24,
            ),
            SizedBox(width: DesignSystem.spacingMedium),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignSystem.body.copyWith(
                      color: context.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: DesignSystem.caption.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: context.secondaryTextColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearDataConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your habits, completions, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DesignSystem.destructive),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseHelper.deleteDatabase();
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      }
    }
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
      case 'restaurant': return Icons.restaurant;
      case 'phone': return Icons.phone;
      case 'computer': return Icons.computer;
      case 'favorite': return Icons.favorite;
      case 'lightbulb': return Icons.lightbulb;
      case 'nature': return Icons.nature;
      default: return Icons.track_changes;
    }
  }
}