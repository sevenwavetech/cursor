class Completion {
  final int? id;
  final int habitId;
  final DateTime completionDate;
  final DateTime createdAt;

  Completion({
    this.id,
    required this.habitId,
    required this.completionDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'completion_date': _formatDateOnly(completionDate),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Completion.fromMap(Map<String, dynamic> map) {
    return Completion(
      id: map['id'],
      habitId: map['habit_id'],
      completionDate: DateTime.parse(map['completion_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Completion copyWith({
    int? id,
    int? habitId,
    DateTime? completionDate,
    DateTime? createdAt,
  }) {
    return Completion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper method to format date as YYYY-MM-DD
  String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// Get date without time component
  DateTime get dateOnly {
    return DateTime(completionDate.year, completionDate.month, completionDate.day);
  }

  /// Check if this completion is for today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compDate = DateTime(completionDate.year, completionDate.month, completionDate.day);
    return today == compDate;
  }

  /// Check if this completion is for yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final compDate = DateTime(completionDate.year, completionDate.month, completionDate.day);
    return yesterdayDate == compDate;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Completion &&
      other.id == id &&
      other.habitId == habitId &&
      other.completionDate == completionDate &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      habitId.hashCode ^
      completionDate.hashCode ^
      createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Completion{id: $id, habitId: $habitId, completionDate: $completionDate, createdAt: $createdAt}';
  }
}