class HabitEntry {
  final int? id;
  final int habitId;
  final DateTime date;
  final int completionCount;
  final String? notes;
  final DateTime createdAt;

  HabitEntry({
    this.id,
    required this.habitId,
    required this.date,
    required this.completionCount,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': _dateOnly(date).millisecondsSinceEpoch,
      'completionCount': completionCount,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory HabitEntry.fromMap(Map<String, dynamic> map) {
    return HabitEntry(
      id: map['id'],
      habitId: map['habitId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      completionCount: map['completionCount'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  HabitEntry copyWith({
    int? id,
    int? habitId,
    DateTime? date,
    int? completionCount,
    String? notes,
    DateTime? createdAt,
  }) {
    return HabitEntry(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completionCount: completionCount ?? this.completionCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method to get date without time
  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Check if this entry is for today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    return today == entryDate;
  }

  // Check if entry is completed based on target
  bool isCompleted(int targetCount) {
    return completionCount >= targetCount;
  }
}