class Habit {
  final int? id;
  final String name;
  final String description;
  final String color;
  final String icon;
  final DateTime createdAt;
  final bool isActive;
  final String frequency; // daily, weekly, monthly
  final int targetCount; // for habits that need multiple completions per day
  
  Habit({
    this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.isActive = true,
    this.frequency = 'daily',
    this.targetCount = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'frequency': frequency,
      'targetCount': targetCount,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      icon: map['icon'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] == 1,
      frequency: map['frequency'],
      targetCount: map['targetCount'],
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
    bool? isActive,
    String? frequency,
    int? targetCount,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
    );
  }
}