import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import 'transaction_provider.dart';

class RecurringTransactionState {
  final List<RecurringTransaction> items;
  final bool isLoading;
  final String? error;

  RecurringTransactionState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  RecurringTransactionState copyWith({
    List<RecurringTransaction>? items,
    bool? isLoading,
    String? error,
  }) {
    return RecurringTransactionState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RecurringTransactionNotifier extends StateNotifier<RecurringTransactionState> {
  final DatabaseService _databaseService = DatabaseService();
  final Ref _ref;

  RecurringTransactionNotifier(this._ref)
      : super(RecurringTransactionState(items: [], isLoading: false));

  Future<void> loadRecurringTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _databaseService.getAllRecurringTransactions();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addRecurringTransaction({
    required String accountId,
    required TransactionType type,
    required double amount,
    String currency = 'BDT',
    String? category,
    String? description,
    required RecurringFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final rt = RecurringTransaction(
        id: const Uuid().v4(),
        accountId: accountId,
        type: type,
        amount: amount,
        currency: currency,
        category: category,
        description: description,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        nextDueDate: startDate,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _databaseService.insertRecurringTransaction(rt);

      state = state.copyWith(
        items: [...state.items, rt],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateRecurringTransaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    String currency = 'BDT',
    String? category,
    String? description,
    required RecurringFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final existing = state.items.firstWhere((rt) => rt.id == id);
      final updated = existing.copyWith(
        accountId: accountId,
        type: type,
        amount: amount,
        currency: currency,
        category: category,
        description: description,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateRecurringTransaction(updated);

      state = state.copyWith(
        items: state.items.map((rt) => rt.id == id ? updated : rt).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleActive(String id) async {
    try {
      final existing = state.items.firstWhere((rt) => rt.id == id);
      final updated = existing.copyWith(
        isActive: !existing.isActive,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateRecurringTransaction(updated);

      state = state.copyWith(
        items: state.items.map((rt) => rt.id == id ? updated : rt).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    try {
      await _databaseService.deleteRecurringTransaction(id);

      state = state.copyWith(
        items: state.items.where((rt) => rt.id != id).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> generateDueTransactions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txnNotifier = _ref.read(transactionProvider.notifier);

    final updatedItems = <RecurringTransaction>[];
    bool anyGenerated = false;

    for (final rt in state.items) {
      if (!rt.isActive) {
        updatedItems.add(rt);
        continue;
      }
      if (rt.endDate != null && today.isAfter(rt.endDate!)) {
        updatedItems.add(rt);
        continue;
      }

      DateTime dueDate = rt.nextDueDate;
      bool generated = false;

      while (!dueDate.isAfter(today)) {
        // Check end date for each iteration
        if (rt.endDate != null && dueDate.isAfter(rt.endDate!)) break;

        await txnNotifier.addTransaction(
          accountId: rt.accountId,
          type: rt.type,
          amount: rt.amount,
          category: rt.category,
          description: rt.description != null
              ? '${rt.description} (Recurring)'
              : '(Recurring)',
          date: dueDate,
        );

        dueDate = _calculateNextDueDate(dueDate, rt.frequency);
        generated = true;
      }

      if (generated) {
        final updated = rt.copyWith(
          nextDueDate: dueDate,
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateRecurringTransaction(updated);
        updatedItems.add(updated);
        anyGenerated = true;
      } else {
        updatedItems.add(rt);
      }
    }

    if (anyGenerated) {
      state = state.copyWith(items: updatedItems);
      // Reload transactions to reflect generated ones
      await txnNotifier.loadAllTransactions();
    }
  }

  DateTime _calculateNextDueDate(DateTime current, RecurringFrequency freq) {
    switch (freq) {
      case RecurringFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        // Handle month overflow (e.g., Jan 31 → Feb 28)
        final next = DateTime(current.year, current.month + 1, current.day);
        if (next.month > current.month + 1 || (current.month == 12 && next.month > 1)) {
          // Day overflowed into next month, use last day of target month
          return DateTime(current.year, current.month + 2, 0);
        }
        return next;
      case RecurringFrequency.yearly:
        return DateTime(current.year + 1, current.month, current.day);
    }
  }
}

final recurringTransactionProvider =
    StateNotifierProvider<RecurringTransactionNotifier, RecurringTransactionState>((ref) {
  return RecurringTransactionNotifier(ref);
});
