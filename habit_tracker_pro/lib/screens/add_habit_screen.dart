import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';

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

  String _selectedColor = AppConstants.habitColorNames[0];
  String _selectedIcon = AppConstants.habitIconNames[0];
  String _selectedFrequency = 'daily';
  int _targetCount = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _initializeFromHabit();
    }
  }

  void _initializeFromHabit() {
    final habit = widget.habit!;
    _nameController.text = habit.name;
    _descriptionController.text = habit.description;
    _selectedColor = habit.color;
    _selectedIcon = habit.icon;
    _selectedFrequency = habit.frequency;
    _targetCount = habit.targetCount;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final habit = Habit(
        id: widget.habit?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
        createdAt: widget.habit?.createdAt ?? DateTime.now(),
        frequency: _selectedFrequency,
        targetCount: _targetCount,
      );

      if (widget.habit == null) {
        // Creating new habit
        await _databaseHelper.insertHabit(habit);
      } else {
        // Updating existing habit
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
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Habit' : 'Add Habit'),
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
              onPressed: _saveHabit,
              child: Text(
                isEditing ? 'Update' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit Preview
              _buildHabitPreview(),
              const SizedBox(height: AppConstants.largePadding),

              // Basic Information
              _buildBasicInformation(),
              const SizedBox(height: AppConstants.largePadding),

              // Color Selection
              _buildColorSelection(),
              const SizedBox(height: AppConstants.largePadding),

              // Icon Selection
              _buildIconSelection(),
              const SizedBox(height: AppConstants.largePadding),

              // Frequency and Target
              _buildFrequencyAndTarget(),
              const SizedBox(height: AppConstants.largePadding),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveHabit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppConstants.getColorByName(_selectedColor),
                    foregroundColor: Colors.white,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppConstants.getColorByName(_selectedColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Icon(
                    AppConstants.getIconByName(_selectedIcon),
                    color: AppConstants.getColorByName(_selectedColor),
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty ? 'Habit Name' : _nameController.text,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_descriptionController.text.isNotEmpty)
                        Text(
                          _descriptionController.text,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        '$_targetCount time${_targetCount > 1 ? 's' : ''} $_selectedFrequency',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.getColorByName(_selectedColor),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Habit Name',
            hintText: 'e.g., Drink water, Exercise, Read',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a habit name';
            }
            return null;
          },
          onChanged: (value) => setState(() {}), // Update preview
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Add more details about your habit...',
            border: OutlineInputBorder(),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Wrap(
          spacing: AppConstants.smallPadding,
          runSpacing: AppConstants.smallPadding,
          children: AppConstants.habitColorNames.map((colorName) {
            final color = AppConstants.getColorByName(colorName);
            final isSelected = _selectedColor == colorName;
            
            return GestureDetector(
              onTap: () => setState(() {
                _selectedColor = colorName;
              }),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                  border: isSelected 
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: AppConstants.smallPadding,
            mainAxisSpacing: AppConstants.smallPadding,
          ),
          itemCount: AppConstants.habitIconNames.length,
          itemBuilder: (context, index) {
            final iconName = AppConstants.habitIconNames[index];
            final icon = AppConstants.habitIcons[index];
            final isSelected = _selectedIcon == iconName;
            
            return GestureDetector(
              onTap: () => setState(() {
                _selectedIcon = iconName;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppConstants.getColorByName(_selectedColor).withOpacity(0.2)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                  border: isSelected 
                      ? Border.all(color: AppConstants.getColorByName(_selectedColor), width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                      ? AppConstants.getColorByName(_selectedColor)
                      : Colors.grey[600],
                  size: 24,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyAndTarget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency & Target',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Frequency Selection
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frequency',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                SegmentedButton<String>(
                  segments: AppConstants.frequencies.map((frequency) {
                    final index = AppConstants.frequencies.indexOf(frequency);
                    return ButtonSegment<String>(
                      value: frequency,
                      label: Text(AppConstants.frequencyLabels[index]),
                    );
                  }).toList(),
                  selected: {_selectedFrequency},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedFrequency = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Target Count
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Count',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Row(
                  children: [
                    IconButton(
                      onPressed: _targetCount > 1 
                          ? () => setState(() => _targetCount--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.smallPadding,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.getColorByName(_selectedColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                      ),
                      child: Text(
                        '$_targetCount',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.getColorByName(_selectedColor),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _targetCount < 10 
                          ? () => setState(() => _targetCount++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                    Expanded(
                      child: Text(
                        'time${_targetCount > 1 ? 's' : ''} per ${_selectedFrequency.substring(0, _selectedFrequency.length - 2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}