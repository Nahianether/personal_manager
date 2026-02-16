import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/savings_goal.dart';
import '../services/database_service.dart';

class SavingsGoalState {
  final List<SavingsGoal> goals;
  final bool isLoading;
  final String? error;

  SavingsGoalState({
    required this.goals,
    required this.isLoading,
    this.error,
  });

  SavingsGoalState copyWith({
    List<SavingsGoal>? goals,
    bool? isLoading,
    String? error,
  }) {
    return SavingsGoalState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<SavingsGoal> get activeGoals =>
      goals.where((g) => !g.isCompleted).toList();

  List<SavingsGoal> get completedGoals =>
      goals.where((g) => g.isCompleted).toList();

  double get totalTargetAmount =>
      goals.fold(0.0, (sum, g) => sum + g.targetAmount);

  double get totalSavedAmount =>
      goals.fold(0.0, (sum, g) => sum + g.currentAmount);
}

class SavingsGoalNotifier extends StateNotifier<SavingsGoalState> {
  final DatabaseService _databaseService = DatabaseService();

  SavingsGoalNotifier()
      : super(SavingsGoalState(goals: [], isLoading: false));

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final goals = await _databaseService.getAllSavingsGoals();
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    String currency = 'BDT',
    String? description,
    String? accountId,
    String priority = 'medium',
  }) async {
    try {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: const Uuid().v4(),
        name: name,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        currency: currency,
        targetDate: targetDate,
        description: description,
        accountId: accountId,
        priority: priority,
        createdAt: now,
        updatedAt: now,
      );

      await _databaseService.insertSavingsGoal(goal);
      state = state.copyWith(
        goals: [...state.goals, goal],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    try {
      final updated = goal.copyWith(updatedAt: DateTime.now());
      await _databaseService.updateSavingsGoal(updated);
      state = state.copyWith(
        goals: state.goals.map((g) => g.id == updated.id ? updated : g).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addToGoal(String goalId, double amount) async {
    try {
      final goal = state.goals.firstWhere((g) => g.id == goalId);
      final newAmount = goal.currentAmount + amount;
      final isCompleted = newAmount >= goal.targetAmount;
      final updated = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );
      await _databaseService.updateSavingsGoal(updated);
      state = state.copyWith(
        goals: state.goals.map((g) => g.id == goalId ? updated : g).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _databaseService.deleteSavingsGoal(goalId);
      state = state.copyWith(
        goals: state.goals.where((g) => g.id != goalId).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final savingsGoalProvider =
    StateNotifierProvider<SavingsGoalNotifier, SavingsGoalState>((ref) {
  return SavingsGoalNotifier();
});
