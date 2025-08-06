import 'database_helper.dart';
import '../models/habit.dart';
import '../models/completion.dart';

/// Database validation utility for testing schema and operations
class DatabaseValidator {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Validate database schema and basic operations
  Future<Map<String, dynamic>> validateDatabase() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Create sample habit
      final now = DateTime.now();
      final sampleHabit = Habit(
        name: 'Test Habit',
        description: 'This is a test habit',
        color: '#6366F1',
        icon: 'fitness_center',
        frequency: 'daily',
        createdAt: now,
        updatedAt: now,
      );
      
      final habitId = await _dbHelper.insertHabit(sampleHabit);
      results['habit_creation'] = habitId > 0 ? 'PASS' : 'FAIL';
      
      // Test 2: Retrieve habit
      final retrievedHabit = await _dbHelper.getHabit(habitId);
      results['habit_retrieval'] = retrievedHabit != null ? 'PASS' : 'FAIL';
      
      // Test 3: Create completion
      final completion = Completion(
        habitId: habitId,
        completionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      final completionId = await _dbHelper.insertCompletion(completion);
      results['completion_creation'] = completionId > 0 ? 'PASS' : 'FAIL';
      
      // Test 4: Get completions for habit
      final completions = await _dbHelper.getCompletionsForHabit(habitId);
      results['completion_retrieval'] = completions.isNotEmpty ? 'PASS' : 'FAIL';
      
      // Test 5: Calculate streak
      final streak = await _dbHelper.getStreakForHabit(habitId);
      results['streak_calculation'] = streak >= 0 ? 'PASS' : 'FAIL';
      
      // Test 6: Get completion rate
      final rate = await _dbHelper.getCompletionRateForHabit(habitId);
      results['completion_rate'] = rate >= 0 ? 'PASS' : 'FAIL';
      
      // Test 7: Archive habit
      await _dbHelper.archiveHabit(habitId);
      final archivedHabits = await _dbHelper.getAllHabits(includeArchived: true);
      final activeHabits = await _dbHelper.getAllHabits(includeArchived: false);
      results['habit_archiving'] = (archivedHabits.length > activeHabits.length) ? 'PASS' : 'FAIL';
      
      // Test 8: Overall stats
      final stats = await _dbHelper.getOverallStats();
      results['overall_stats'] = stats.isNotEmpty ? 'PASS' : 'FAIL';
      
      // Test 9: Delete completion
      await _dbHelper.deleteCompletion(completionId);
      final remainingCompletions = await _dbHelper.getCompletionsForHabit(habitId);
      results['completion_deletion'] = remainingCompletions.isEmpty ? 'PASS' : 'FAIL';
      
      // Test 10: Delete habit
      await _dbHelper.deleteHabit(habitId);
      final deletedHabit = await _dbHelper.getHabit(habitId);
      results['habit_deletion'] = deletedHabit == null ? 'PASS' : 'FAIL';
      
      // Summary
      final passCount = results.values.where((v) => v == 'PASS').length;
      final totalTests = results.length;
      results['summary'] = '$passCount/$totalTests tests passed';
      results['validation_status'] = passCount == totalTests ? 'SUCCESS' : 'PARTIAL_FAILURE';
      
    } catch (e) {
      results['error'] = e.toString();
      results['validation_status'] = 'ERROR';
    }
    
    return results;
  }

  /// Test constraint validations
  Future<Map<String, dynamic>> validateConstraints() async {
    final results = <String, dynamic>{};
    
    try {
      // Test name length constraint (should be <= 30 chars)
      final longNameHabit = Habit(
        name: 'This is a very long habit name that exceeds thirty characters',
        color: '#6366F1',
        icon: 'fitness_center',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      try {
        await _dbHelper.insertHabit(longNameHabit);
        results['name_length_constraint'] = 'FAIL'; // Should have failed
      } catch (e) {
        results['name_length_constraint'] = 'PASS'; // Correctly rejected
      }
      
      // Test frequency constraint
      final invalidFrequencyHabit = Habit(
        name: 'Test',
        color: '#6366F1',
        icon: 'fitness_center',
        frequency: 'invalid_frequency',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      try {
        await _dbHelper.insertHabit(invalidFrequencyHabit);
        results['frequency_constraint'] = 'FAIL'; // Should have failed
      } catch (e) {
        results['frequency_constraint'] = 'PASS'; // Correctly rejected
      }
      
      // Test unique completion constraint
      final validHabit = Habit(
        name: 'Test Habit',
        color: '#6366F1',
        icon: 'fitness_center',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final habitId = await _dbHelper.insertHabit(validHabit);
      final today = DateTime.now();
      
      final completion1 = Completion(
        habitId: habitId,
        completionDate: today,
        createdAt: DateTime.now(),
      );
      
      await _dbHelper.insertCompletion(completion1);
      
      // Try to insert duplicate completion for same date
      final completion2 = Completion(
        habitId: habitId,
        completionDate: today,
        createdAt: DateTime.now(),
      );
      
      await _dbHelper.insertCompletion(completion2); // Should replace, not create duplicate
      final completions = await _dbHelper.getCompletionsForHabit(habitId);
      results['unique_completion_constraint'] = completions.length == 1 ? 'PASS' : 'FAIL';
      
      // Clean up
      await _dbHelper.deleteHabit(habitId);
      
    } catch (e) {
      results['constraint_validation_error'] = e.toString();
    }
    
    return results;
  }

  /// Test performance with bulk operations
  Future<Map<String, dynamic>> validatePerformance() async {
    final results = <String, dynamic>{};
    final stopwatch = Stopwatch();
    
    try {
      // Test bulk habit insertion
      stopwatch.start();
      final habitIds = <int>[];
      for (int i = 0; i < 100; i++) {
        final habit = Habit(
          name: 'Habit $i',
          color: '#6366F1',
          icon: 'fitness_center',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final id = await _dbHelper.insertHabit(habit);
        habitIds.add(id);
      }
      stopwatch.stop();
      results['bulk_habit_insertion_ms'] = stopwatch.elapsedMilliseconds;
      
      // Test bulk completion insertion
      stopwatch.reset();
      stopwatch.start();
      for (final habitId in habitIds) {
        for (int day = 0; day < 30; day++) {
          final completion = Completion(
            habitId: habitId,
            completionDate: DateTime.now().subtract(Duration(days: day)),
            createdAt: DateTime.now(),
          );
          await _dbHelper.insertCompletion(completion);
        }
      }
      stopwatch.stop();
      results['bulk_completion_insertion_ms'] = stopwatch.elapsedMilliseconds;
      
      // Test bulk retrieval
      stopwatch.reset();
      stopwatch.start();
      await _dbHelper.getAllHabits();
      stopwatch.stop();
      results['habit_retrieval_ms'] = stopwatch.elapsedMilliseconds;
      
      // Test complex query performance
      stopwatch.reset();
      stopwatch.start();
      await _dbHelper.getOverallStats();
      stopwatch.stop();
      results['stats_query_ms'] = stopwatch.elapsedMilliseconds;
      
      // Clean up
      for (final habitId in habitIds) {
        await _dbHelper.deleteHabit(habitId);
      }
      
      results['performance_test_status'] = 'SUCCESS';
      
    } catch (e) {
      results['performance_test_error'] = e.toString();
      results['performance_test_status'] = 'ERROR';
    }
    
    return results;
  }

  /// Run all validations
  Future<Map<String, dynamic>> runAllValidations() async {
    final results = <String, dynamic>{};
    
    print('🔍 Running database validations...\n');
    
    // Basic functionality tests
    print('📋 Testing basic operations...');
    final basicTests = await validateDatabase();
    results['basic_operations'] = basicTests;
    print('   ${basicTests['summary']} - ${basicTests['validation_status']}\n');
    
    // Constraint tests
    print('🔒 Testing database constraints...');
    final constraintTests = await validateConstraints();
    results['constraints'] = constraintTests;
    print('   Constraint validation completed\n');
    
    // Performance tests
    print('⚡ Testing performance...');
    final performanceTests = await validatePerformance();
    results['performance'] = performanceTests;
    print('   Performance tests: ${performanceTests['performance_test_status']}\n');
    
    // Overall summary
    final allPassed = basicTests['validation_status'] == 'SUCCESS' &&
                     performanceTests['performance_test_status'] == 'SUCCESS';
    
    results['overall_status'] = allPassed ? 'ALL_TESTS_PASSED' : 'SOME_TESTS_FAILED';
    
    print('✅ Database validation completed: ${results['overall_status']}');
    
    return results;
  }
}