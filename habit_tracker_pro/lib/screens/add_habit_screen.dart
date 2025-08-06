import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';
import '../utils/design_system.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // If provided, we're editing

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  int _selectedColorIndex = 0;
  String _selectedIcon = 'fitness_center';
  String _selectedFrequency = 'daily';
  bool _isLoading = false;
  bool _isFormValid = false;

  // Available icons for habit selection
  final List<Map<String, dynamic>> _habitIcons = [
    {'name': 'fitness_center', 'icon': Icons.fitness_center, 'label': 'Fitness'},
    {'name': 'local_drink', 'icon': Icons.local_drink, 'label': 'Water'},
    {'name': 'book', 'icon': Icons.book, 'label': 'Reading'},
    {'name': 'bedtime', 'icon': Icons.bedtime, 'label': 'Sleep'},
    {'name': 'directions_run', 'icon': Icons.directions_run, 'label': 'Running'},
    {'name': 'self_improvement', 'icon': Icons.self_improvement, 'label': 'Meditation'},
    {'name': 'music_note', 'icon': Icons.music_note, 'label': 'Music'},
    {'name': 'palette', 'icon': Icons.palette, 'label': 'Art'},
    {'name': 'work', 'icon': Icons.work, 'label': 'Work'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Study'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Nutrition'},
    {'name': 'phone', 'icon': Icons.phone, 'label': 'Communication'},
    {'name': 'computer', 'icon': Icons.computer, 'label': 'Technology'},
    {'name': 'favorite', 'icon': Icons.favorite, 'label': 'Health'},
    {'name': 'lightbulb', 'icon': Icons.lightbulb, 'label': 'Learning'},
    {'name': 'nature', 'icon': Icons.nature, 'label': 'Nature'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _initializeFromHabit();
    }
    _nameController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
  }

  void _initializeFromHabit() {
    final habit = widget.habit!;
    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _selectedColorIndex = DesignSystem.habitColorNames.indexOf(habit.color);
    if (_selectedColorIndex == -1) _selectedColorIndex = 0;
    _selectedIcon = habit.icon;
    _selectedFrequency = habit.frequency;
  }

  void _validateForm() {
    final isValid = _nameController.text.trim().isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final habit = Habit(
        id: widget.habit?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        color: DesignSystem.habitColorNames[_selectedColorIndex],
        icon: _selectedIcon,
        frequency: _selectedFrequency,
        createdAt: widget.habit?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.habit == null) {
        await _databaseHelper.insertHabit(habit);
      } else {
        await _databaseHelper.updateHabit(habit);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving habit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Habit' : 'New Habit',
          style: DesignSystem.title1.copyWith(
            color: context.textColor,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _isFormValid ? _saveHabit : null,
              child: Text(
                isEditing ? 'Update' : 'Save',
                style: DesignSystem.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isFormValid 
                      ? DesignSystem.primary 
                      : context.secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DesignSystem.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live preview of habit card
              _buildHabitPreview(),
              SizedBox(height: DesignSystem.spacingLarge),

              // Basic Information
              _buildBasicInformation(),
              SizedBox(height: DesignSystem.spacingLarge),

              // Color Selection
              _buildColorSelection(),
              SizedBox(height: DesignSystem.spacingLarge),

              // Icon Selection
              _buildIconSelection(),
              SizedBox(height: DesignSystem.spacingLarge),

              // Frequency Selection
              _buildFrequencySelection(),
              SizedBox(height: DesignSystem.spacingXL),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: DesignSystem.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isLoading ? _saveHabit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid 
                        ? DesignSystem.getHabitColorByIndex(_selectedColorIndex)
                        : context.secondaryTextColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Habit' : 'Create Habit',
                          style: DesignSystem.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitPreview() {
    final habitColor = DesignSystem.getHabitColorByIndex(_selectedColorIndex);
    final selectedIconData = _habitIcons.firstWhere(
      (icon) => icon['name'] == _selectedIcon,
      orElse: () => _habitIcons[0],
    );

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
            'Preview',
            style: DesignSystem.headline.copyWith(
              color: context.textColor,
            ),
          ),
          SizedBox(height: DesignSystem.spacingMedium),
          
          // Preview habit card
          Container(
            height: DesignSystem.cardHeight,
            padding: EdgeInsets.all(DesignSystem.spacingMedium),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
              border: Border.all(
                color: context.secondaryTextColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Habit icon
                Container(
                  width: DesignSystem.habitIconSize,
                  height: DesignSystem.habitIconSize,
                  decoration: BoxDecoration(
                    color: habitColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedIconData['icon'],
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: DesignSystem.spacingMedium),
                
                // Habit info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _nameController.text.isEmpty ? 'Habit Name' : _nameController.text,
                        style: DesignSystem.headline.copyWith(
                          color: context.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: DesignSystem.spacingMicro),
                      Text(
                        'No streak yet',
                        style: DesignSystem.body.copyWith(
                          fontSize: 14,
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Completion tile preview
                Container(
                  width: DesignSystem.tileSize,
                  height: DesignSystem.tileSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: habitColor, width: 2),
                    borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: DesignSystem.headline.copyWith(
            color: context.textColor,
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium),
        
        // Habit name input
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Habit Name',
            hintText: 'e.g., Drink water, Exercise, Read',
            suffixText: '${_nameController.text.length}/30',
          ),
          maxLength: 30,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a habit name';
            }
            return null;
          },
          onChanged: (value) => setState(() {}), // Update preview
        ),
        SizedBox(height: DesignSystem.spacingMedium),
        
        // Description input
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Add more details about your habit...',
          ),
          maxLines: 3,
          onChanged: (value) => setState(() {}), // Update preview
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Color',
          style: DesignSystem.headline.copyWith(
            color: context.textColor,
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium),
        
        // Color grid (4x4)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: DesignSystem.habitColors.length,
          itemBuilder: (context, index) {
            final color = DesignSystem.habitColors[index];
            final isSelected = _selectedColorIndex == index;
            
            return GestureDetector(
              onTap: () => setState(() {
                _selectedColorIndex = index;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
                  border: isSelected 
                      ? Border.all(color: context.textColor, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Icon',
          style: DesignSystem.headline.copyWith(
            color: context.textColor,
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium),
        
        // Horizontal scrolling icon list
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _habitIcons.length,
            itemBuilder: (context, index) {
              final iconData = _habitIcons[index];
              final isSelected = _selectedIcon == iconData['name'];
              
              return Padding(
                padding: EdgeInsets.only(right: DesignSystem.spacingMedium),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedIcon = iconData['name'];
                  }),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? DesignSystem.getHabitColorByIndex(_selectedColorIndex).withOpacity(0.2)
                              : context.surfaceColor,
                          borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
                          border: isSelected 
                              ? Border.all(
                                  color: DesignSystem.getHabitColorByIndex(_selectedColorIndex), 
                                  width: 2
                                )
                              : Border.all(
                                  color: context.secondaryTextColor.withOpacity(0.3),
                                  width: 1
                                ),
                        ),
                        child: Icon(
                          iconData['icon'],
                          color: isSelected 
                              ? DesignSystem.getHabitColorByIndex(_selectedColorIndex)
                              : context.secondaryTextColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacingMicro),
                      Text(
                        iconData['label'],
                        style: DesignSystem.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: DesignSystem.headline.copyWith(
            color: context.textColor,
          ),
        ),
        SizedBox(height: DesignSystem.spacingMedium),
        
        // Frequency selector
        Container(
          padding: EdgeInsets.all(DesignSystem.spacingMedium),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(DesignSystem.cardBorderRadius),
          ),
          child: Column(
            children: [
              _buildFrequencyOption('daily', 'Daily', 'Every day'),
              _buildFrequencyOption('weekly', 'Weekly', 'Once a week'),
              _buildFrequencyOption('custom', 'Custom', 'Set your own schedule'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyOption(String value, String title, String subtitle) {
    final isSelected = _selectedFrequency == value;
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFrequency = value;
      }),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignSystem.spacingMedium,
          vertical: DesignSystem.spacingSmall,
        ),
        margin: EdgeInsets.only(bottom: DesignSystem.spacingSmall),
        decoration: BoxDecoration(
          color: isSelected 
              ? DesignSystem.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignSystem.tileBorderRadius),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedFrequency,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFrequency = newValue;
                  });
                }
              },
              activeColor: DesignSystem.primary,
            ),
            SizedBox(width: DesignSystem.spacingSmall),
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
          ],
        ),
      ),
    );
  }
}