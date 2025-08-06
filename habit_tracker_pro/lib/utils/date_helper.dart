class DateHelper {
  // Get date without time component
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return dateOnly(date1) == dateOnly(date2);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  // Get start of week (Monday)
  static DateTime getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return dateOnly(date).subtract(Duration(days: dayOfWeek - 1));
  }

  // Get end of week (Sunday)
  static DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    return startOfWeek.add(const Duration(days: 6));
  }

  // Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Get days in month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // Get month name
  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Get short month name
  static String getShortMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Get day name
  static String getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }

  // Get short day name
  static String getShortDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Format date as string
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format date as readable string
  static String formatDateReadable(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return '${getShortDayName(date.weekday)}, ${date.day} ${getShortMonthName(date.month)}';
    }
  }

  // Get date range for habit grid (last N days)
  static List<DateTime> getDateRange(DateTime endDate, int days) {
    final dates = <DateTime>[];
    for (int i = days - 1; i >= 0; i--) {
      dates.add(dateOnly(endDate).subtract(Duration(days: i)));
    }
    return dates;
  }

  // Get weeks in month for calendar view
  static List<List<DateTime>> getWeeksInMonth(DateTime date) {
    final startOfMonth = getStartOfMonth(date);
    final endOfMonth = getEndOfMonth(date);
    final startOfFirstWeek = getStartOfWeek(startOfMonth);
    
    final weeks = <List<DateTime>>[];
    DateTime currentWeekStart = startOfFirstWeek;
    
    while (currentWeekStart.isBefore(endOfMonth) || 
           currentWeekStart.month == date.month) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(currentWeekStart.add(Duration(days: i)));
      }
      weeks.add(week);
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      
      // Break if we've gone past the month and filled a complete week
      if (week.last.month != date.month && weeks.length > 1) {
        break;
      }
    }
    
    return weeks;
  }

  // Calculate days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    return dateOnly(end).difference(dateOnly(start)).inDays;
  }

  // Get relative date string
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = daysBetween(date, now);
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < -1 && difference > -7) {
      return '${-difference} days ago';
    } else if (difference > 1 && difference < 7) {
      return 'In $difference days';
    } else {
      return formatDate(date);
    }
  }
}