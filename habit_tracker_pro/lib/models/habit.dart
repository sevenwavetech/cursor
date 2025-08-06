class Habit {
  final int? id;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final String frequency; // 'daily', 'weekly', 'custom'
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Habit({
    this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    this.frequency = 'daily',
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'frequency': frequency,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      icon: map['icon'],
      frequency: map['frequency'] ?? 'daily',
      isArchived: (map['is_archived'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    String? frequency,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Habit &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.color == color &&
      other.icon == icon &&
      other.frequency == frequency &&
      other.isArchived == isArchived &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      color.hashCode ^
      icon.hashCode ^
      frequency.hashCode ^
      isArchived.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Habit{id: $id, name: $name, description: $description, color: $color, icon: $icon, frequency: $frequency, isArchived: $isArchived, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}