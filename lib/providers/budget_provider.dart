import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class BudgetState {
  final List<Budget> budgets;
  final bool isLoading;
  final String? error;

  BudgetState({
    required this.budgets,
    required this.isLoading,
    this.error,
  });

  BudgetState copyWith({
    List<Budget>? budgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final DatabaseService _databaseService = DatabaseService();

  BudgetNotifier() : super(BudgetState(budgets: [], isLoading: false));

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final budgets = await _databaseService.getAllBudgets();
      state = state.copyWith(budgets: budgets, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addBudget({
    required String category,
    required double amount,
    BudgetPeriod period = BudgetPeriod.monthly,
  }) async {
    try {
      final now = DateTime.now();
      final budget = Budget(
        id: const Uuid().v4(),
        category: category,
        amount: amount,
        period: period,
        createdAt: now,
        updatedAt: now,
      );

      await _databaseService.insertBudget(budget);

      state = state.copyWith(
        budgets: [...state.budgets, budget],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateBudget({
    required String budgetId,
    required String category,
    required double amount,
    required BudgetPeriod period,
  }) async {
    try {
      final existing = state.budgets.firstWhere((b) => b.id == budgetId);
      final updated = existing.copyWith(
        category: category,
        amount: amount,
        period: period,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateBudget(updated);

      state = state.copyWith(
        budgets: state.budgets.map((b) => b.id == budgetId ? updated : b).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _databaseService.deleteBudget(budgetId);

      state = state.copyWith(
        budgets: state.budgets.where((b) => b.id != budgetId).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  double getSpentAmount(Budget budget, List<Transaction> transactions) {
    final now = DateTime.now();
    late DateTime periodStart;
    late DateTime periodEnd;

    switch (budget.period) {
      case BudgetPeriod.weekly:
        // Start of current week (Monday)
        final weekday = now.weekday;
        periodStart = DateTime(now.year, now.month, now.day - (weekday - 1));
        periodEnd = periodStart.add(const Duration(days: 7));
        break;
      case BudgetPeriod.monthly:
        periodStart = DateTime(now.year, now.month, 1);
        periodEnd = DateTime(now.year, now.month + 1, 1);
        break;
      case BudgetPeriod.yearly:
        periodStart = DateTime(now.year, 1, 1);
        periodEnd = DateTime(now.year + 1, 1, 1);
        break;
    }

    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.category == budget.category &&
            !t.date.isBefore(periodStart) &&
            t.date.isBefore(periodEnd))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<BudgetStatus> getBudgetStatuses(List<Transaction> transactions) {
    return state.budgets.map((budget) {
      final spent = getSpentAmount(budget, transactions);
      return BudgetStatus(budget: budget, spent: spent);
    }).toList();
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier();
});
