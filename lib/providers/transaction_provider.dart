import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../services/database_service.dart';
import 'account_provider.dart';

class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  TransactionState({
    required this.transactions,
    required this.isLoading,
    this.error,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final DatabaseService _databaseService = DatabaseService();
  final Ref _ref;

  TransactionNotifier(this._ref) : super(TransactionState(transactions: [], isLoading: false));

  Future<void> loadTransactionsByAccount(String accountId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await _databaseService.getTransactionsByAccount(accountId);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadAllTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await _databaseService.getAllTransactions();
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addTransaction({
    required String accountId,
    required TransactionType type,
    required double amount,
    String currency = 'BDT',
    String? category,
    String? description,
    DateTime? date,
  }) async {
    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        accountId: accountId,
        type: type,
        amount: amount,
        currency: currency,
        category: category,
        description: description,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _databaseService.insertTransaction(transaction);
      
      final accountNotifier = _ref.read(accountProvider.notifier);
      final account = accountNotifier.getAccountById(accountId);
      
      if (account != null) {
        double newBalance = account.balance;
        
        if (account.isCreditCard) {
          // For credit cards: balance represents amount owed/used
          switch (type) {
            case TransactionType.income:
              newBalance -= amount; // Payment reduces debt
              break;
            case TransactionType.expense:
              newBalance += amount; // Spending increases debt
              break;
            case TransactionType.transfer:
              break;
          }
        } else {
          // For regular accounts: balance represents available amount
          switch (type) {
            case TransactionType.income:
              newBalance += amount;
              break;
            case TransactionType.expense:
              newBalance -= amount;
              break;
            case TransactionType.transfer:
              break;
          }
        }
        
        await accountNotifier.updateAccountBalance(accountId, newBalance);
      }
      
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        error: null,
      );
    } catch (e) {
      // Check for database permission errors
      if (e.toString().contains('readonly database') || e.toString().contains('1032')) {
        try {
          // Attempt to reset the database
          print('Attempting to reset database due to permission error...');
          await _databaseService.resetDatabase();
          
          // Retry the transaction
          final retryTransaction = Transaction(
            id: const Uuid().v4(),
            accountId: accountId,
            type: type,
            amount: amount,
            currency: currency,
            category: category,
            description: description,
            date: date ?? DateTime.now(),
            createdAt: DateTime.now(),
          );
          
          await _databaseService.insertTransaction(retryTransaction);
          
          // Update account balance if successful
          final accountNotifier = _ref.read(accountProvider.notifier);
          final account = accountNotifier.getAccountById(accountId);
          
          if (account != null) {
            double newBalance = account.balance;
            
            if (account.isCreditCard) {
              switch (type) {
                case TransactionType.income:
                  newBalance -= amount;
                  break;
                case TransactionType.expense:
                  newBalance += amount;
                  break;
                case TransactionType.transfer:
                  break;
              }
            } else {
              switch (type) {
                case TransactionType.income:
                  newBalance += amount;
                  break;
                case TransactionType.expense:
                  newBalance -= amount;
                  break;
                case TransactionType.transfer:
                  break;
              }
            }
            
            await accountNotifier.updateAccountBalance(accountId, newBalance);
          }
          
          state = state.copyWith(
            transactions: [retryTransaction, ...state.transactions],
            error: null,
          );
          return;
        } catch (resetError) {
          state = state.copyWith(error: 'Database error: ${resetError.toString()}. Please restart the app.');
          return;
        }
      }
      
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String currency = 'BDT',
    String? description,
    DateTime? date,
  }) async {
    try {
      final transferDate = date ?? DateTime.now();
      final now = DateTime.now();
      
      final fromTransaction = Transaction(
        id: const Uuid().v4(),
        accountId: fromAccountId,
        type: TransactionType.transfer,
        amount: -amount,
        currency: currency,
        category: 'Transfer Out',
        description: description,
        date: transferDate,
        createdAt: now,
      );

      final toTransaction = Transaction(
        id: const Uuid().v4(),
        accountId: toAccountId,
        type: TransactionType.transfer,
        amount: amount,
        currency: currency,
        category: 'Transfer In',
        description: description,
        date: transferDate,
        createdAt: now,
      );

      await _databaseService.insertTransaction(fromTransaction);
      await _databaseService.insertTransaction(toTransaction);
      
      final accountNotifier = _ref.read(accountProvider.notifier);
      final fromAccount = accountNotifier.getAccountById(fromAccountId);
      final toAccount = accountNotifier.getAccountById(toAccountId);
      
      if (fromAccount != null) {
        double newFromBalance;
        if (fromAccount.isCreditCard) {
          // For credit card: transferring money out increases debt (balance)
          newFromBalance = fromAccount.balance + amount;
        } else {
          // For regular accounts: transferring money out decreases balance
          newFromBalance = fromAccount.balance - amount;
        }
        await accountNotifier.updateAccountBalance(fromAccountId, newFromBalance);
      }
      
      if (toAccount != null) {
        double newToBalance;
        if (toAccount.isCreditCard) {
          // For credit card: receiving money reduces debt (balance)
          newToBalance = toAccount.balance - amount;
        } else {
          // For regular accounts: receiving money increases balance
          newToBalance = toAccount.balance + amount;
        }
        await accountNotifier.updateAccountBalance(toAccountId, newToBalance);
      }
      
      state = state.copyWith(
        transactions: [toTransaction, fromTransaction, ...state.transactions],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> editTransaction({
    required String transactionId,
    required String accountId,
    required TransactionType type,
    required double amount,
    String currency = 'BDT',
    String? category,
    String? description,
    required DateTime date,
  }) async {
    try {
      final oldTransaction = state.transactions.firstWhere((t) => t.id == transactionId);
      final accountNotifier = _ref.read(accountProvider.notifier);

      // 1. Reverse the old transaction's balance effect
      final oldAccount = accountNotifier.getAccountById(oldTransaction.accountId);
      if (oldAccount != null) {
        double reversal = 0.0;
        if (oldAccount.isCreditCard) {
          switch (oldTransaction.type) {
            case TransactionType.income:
              reversal = oldTransaction.amount;
              break;
            case TransactionType.expense:
              reversal = -oldTransaction.amount;
              break;
            case TransactionType.transfer:
              break;
          }
        } else {
          switch (oldTransaction.type) {
            case TransactionType.income:
              reversal = -oldTransaction.amount;
              break;
            case TransactionType.expense:
              reversal = oldTransaction.amount;
              break;
            case TransactionType.transfer:
              break;
          }
        }
        if (reversal != 0) {
          await accountNotifier.updateAccountBalance(
            oldTransaction.accountId,
            oldAccount.balance + reversal,
          );
        }
      }

      // 2. Build the updated transaction
      final updatedTransaction = Transaction(
        id: transactionId,
        accountId: accountId,
        type: type,
        amount: amount,
        currency: currency,
        category: category,
        description: description,
        date: date,
        createdAt: oldTransaction.createdAt,
      );

      // 3. Persist to database
      await _databaseService.updateTransaction(updatedTransaction);

      // 4. Apply the new transaction's balance effect
      // Re-read the account in case it changed (e.g. same account, balance just reversed)
      final newAccount = accountNotifier.getAccountById(accountId);
      if (newAccount != null) {
        double effect = 0.0;
        if (newAccount.isCreditCard) {
          switch (type) {
            case TransactionType.income:
              effect = -amount;
              break;
            case TransactionType.expense:
              effect = amount;
              break;
            case TransactionType.transfer:
              break;
          }
        } else {
          switch (type) {
            case TransactionType.income:
              effect = amount;
              break;
            case TransactionType.expense:
              effect = -amount;
              break;
            case TransactionType.transfer:
              break;
          }
        }
        if (effect != 0) {
          await accountNotifier.updateAccountBalance(
            accountId,
            newAccount.balance + effect,
          );
        }
      }

      // 5. Update state
      state = state.copyWith(
        transactions: state.transactions
            .map((t) => t.id == transactionId ? updatedTransaction : t)
            .toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Combined search + filter. All parameters are optional and ANDed together.
  List<Transaction> searchAndFilter({
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? category,
    double? amountMin,
    double? amountMax,
    String? accountId,
    TransactionType? type,
  }) {
    var results = state.transactions.toList();

    if (type != null) {
      results = results.where((t) => t.type == type).toList();
    }

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results.where((t) {
        final desc = t.description?.toLowerCase() ?? '';
        final cat = t.category?.toLowerCase() ?? '';
        return desc.contains(q) || cat.contains(q);
      }).toList();
    }

    if (dateFrom != null) {
      final start = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
      results = results.where((t) => !t.date.isBefore(start)).toList();
    }

    if (dateTo != null) {
      final end = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
      results = results.where((t) => !t.date.isAfter(end)).toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results.where((t) => t.category == category).toList();
    }

    if (amountMin != null) {
      results = results.where((t) => t.amount.abs() >= amountMin).toList();
    }

    if (amountMax != null) {
      results = results.where((t) => t.amount.abs() <= amountMax).toList();
    }

    if (accountId != null && accountId.isNotEmpty) {
      results = results.where((t) => t.accountId == accountId).toList();
    }

    return results;
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return state.transactions
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
  }

  List<Transaction> getTransactionsByCategory(String category) {
    return state.transactions
        .where((t) => t.category == category)
        .toList();
  }

  List<Transaction> getTransactionsByType(TransactionType type) {
    return state.transactions
        .where((t) => t.type == type)
        .toList();
  }

  Map<String, double> getExpensesByCategory() {
    final expenses = state.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    
    final Map<String, double> categoryTotals = {};
    
    for (final expense in expenses) {
      final category = expense.category ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }
    
    return categoryTotals;
  }

  Map<String, double> getIncomesByCategory() {
    final incomes = state.transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    
    final Map<String, double> categoryTotals = {};
    
    for (final income in incomes) {
      final category = income.category ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + income.amount;
    }
    
    return categoryTotals;
  }

  double get totalIncome {
    return state.transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return state.transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netBalance {
    return totalIncome - totalExpense;
  }

  // Get current month's income and expense
  Map<String, double> getCurrentMonthData() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final currentMonthTransactions = state.transactions.where((t) =>
        t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();

    double income = currentMonthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    double expense = currentMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return {
      'income': income,
      'expense': expense,
    };
  }

  // Monthly spending summary with trend change percentages
  List<Map<String, dynamic>> getMonthlySpendingSummary() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> summary = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

      final monthTransactions = state.transactions.where((t) =>
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();

      double income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      double expense = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      double? changePercent;
      if (summary.isNotEmpty) {
        final prevExpense = summary.last['expense'] as double;
        if (prevExpense > 0) {
          changePercent = ((expense - prevExpense) / prevExpense) * 100;
        }
      }

      summary.add({
        'month': monthDate,
        'income': income,
        'expense': expense,
        'net': income - expense,
        'changePercent': changePercent,
      });
    }

    return summary;
  }

  // Category spending over last 6 months (top 5 categories)
  Map<String, List<Map<String, dynamic>>> getCategorySpendingOverTime() {
    final now = DateTime.now();

    // First, collect all category totals to find top 5
    final Map<String, double> totalByCategory = {};
    final Map<String, List<Map<String, dynamic>>> categoryMonthly = {};

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

      final monthExpenses = state.transactions.where((t) =>
          t.type == TransactionType.expense &&
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();

      final Map<String, double> monthCategoryTotals = {};
      for (final t in monthExpenses) {
        final cat = t.category ?? 'Other';
        monthCategoryTotals[cat] = (monthCategoryTotals[cat] ?? 0) + t.amount;
        totalByCategory[cat] = (totalByCategory[cat] ?? 0) + t.amount;
      }

      // Store data for all categories for this month
      for (final entry in monthCategoryTotals.entries) {
        categoryMonthly.putIfAbsent(entry.key, () => []);
        categoryMonthly[entry.key]!.add({
          'month': monthDate,
          'amount': entry.value,
        });
      }

      // Fill in zeroes for categories that had no spending this month
      for (final cat in categoryMonthly.keys) {
        if (!monthCategoryTotals.containsKey(cat)) {
          categoryMonthly[cat]!.add({
            'month': monthDate,
            'amount': 0.0,
          });
        }
      }
    }

    // Get top 5 categories by total spending
    final sortedCategories = totalByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedCategories.take(5).map((e) => e.key).toSet();

    // Filter to only top 5
    categoryMonthly.removeWhere((key, _) => !top5.contains(key));

    return categoryMonthly;
  }

  // Smart budget suggestions based on spending history
  List<Map<String, dynamic>> getSmartBudgetSuggestions(List<Budget> budgets) {
    final now = DateTime.now();
    final suggestions = <Map<String, dynamic>>[];
    final budgetedCategories = budgets.map((b) => b.category).toSet();

    // Calculate 3-month average spending per category
    final Map<String, List<double>> categoryMonthlySpending = {};

    for (int i = 1; i <= 3; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

      final monthExpenses = state.transactions.where((t) =>
          t.type == TransactionType.expense &&
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();

      final Map<String, double> monthTotals = {};
      for (final t in monthExpenses) {
        final cat = t.category ?? 'Other';
        monthTotals[cat] = (monthTotals[cat] ?? 0) + t.amount;
      }

      for (final entry in monthTotals.entries) {
        categoryMonthlySpending.putIfAbsent(entry.key, () => []);
        categoryMonthlySpending[entry.key]!.add(entry.value);
      }
    }

    for (final entry in categoryMonthlySpending.entries) {
      final category = entry.key;
      final monthlyAmounts = entry.value;
      final average = monthlyAmounts.fold(0.0, (s, v) => s + v) / 3;

      if (average < 1) continue; // Skip negligible categories

      if (!budgetedCategories.contains(category)) {
        // No budget exists — suggest creating one
        final suggested = (average * 1.1).ceilToDouble(); // 10% buffer
        suggestions.add({
          'category': category,
          'suggestion': 'Create a monthly budget of ${suggested.toStringAsFixed(0)} based on your 3-month average',
          'suggestedAmount': suggested,
          'currentBudget': null,
          'averageSpending': average,
        });
      } else {
        // Budget exists — check if it needs adjustment
        final budget = budgets.firstWhere((b) => b.category == category);
        final ratio = average / budget.amount;

        if (ratio > 1.1) {
          // Consistently over budget
          final suggested = (average * 1.1).ceilToDouble();
          suggestions.add({
            'category': category,
            'suggestion': 'Increase budget from ${budget.amount.toStringAsFixed(0)} to ${suggested.toStringAsFixed(0)} — you regularly exceed it',
            'suggestedAmount': suggested,
            'currentBudget': budget.amount,
            'averageSpending': average,
          });
        } else if (ratio < 0.5) {
          // Significantly under budget
          final suggested = (average * 1.2).ceilToDouble();
          suggestions.add({
            'category': category,
            'suggestion': 'Reduce budget from ${budget.amount.toStringAsFixed(0)} to ${suggested.toStringAsFixed(0)} — you use less than half',
            'suggestedAmount': suggested,
            'currentBudget': budget.amount,
            'averageSpending': average,
          });
        }
      }
    }

    // Sort: unbudgeted first, then by average spending descending
    suggestions.sort((a, b) {
      final aHasBudget = a['currentBudget'] != null ? 1 : 0;
      final bHasBudget = b['currentBudget'] != null ? 1 : 0;
      if (aHasBudget != bHasBudget) return aHasBudget - bHasBudget;
      return (b['averageSpending'] as double).compareTo(a['averageSpending'] as double);
    });

    return suggestions;
  }

  // Unusual spending alerts: current month vs 3-month rolling average
  List<Map<String, dynamic>> getUnusualSpendingAlerts() {
    final now = DateTime.now();
    final alerts = <Map<String, dynamic>>[];

    // Current month spending by category
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0);

    final currentMonthExpenses = state.transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.isAfter(startOfCurrentMonth.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endOfCurrentMonth.add(const Duration(days: 1)))).toList();

    final Map<String, double> currentByCategory = {};
    for (final t in currentMonthExpenses) {
      final cat = t.category ?? 'Other';
      currentByCategory[cat] = (currentByCategory[cat] ?? 0) + t.amount;
    }

    // 3-month average by category (previous 3 months, excluding current)
    final Map<String, double> avgByCategory = {};
    final Map<String, int> monthCountByCategory = {};

    for (int i = 1; i <= 3; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

      final monthExpenses = state.transactions.where((t) =>
          t.type == TransactionType.expense &&
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();

      final Map<String, double> monthTotals = {};
      for (final t in monthExpenses) {
        final cat = t.category ?? 'Other';
        monthTotals[cat] = (monthTotals[cat] ?? 0) + t.amount;
      }

      for (final entry in monthTotals.entries) {
        avgByCategory[entry.key] = (avgByCategory[entry.key] ?? 0) + entry.value;
        monthCountByCategory[entry.key] = (monthCountByCategory[entry.key] ?? 0) + 1;
      }
    }

    // Calculate averages
    for (final key in avgByCategory.keys) {
      avgByCategory[key] = avgByCategory[key]! / 3;
    }

    // Compare current vs average
    for (final entry in currentByCategory.entries) {
      final avg = avgByCategory[entry.key];
      if (avg == null || avg < 1) continue; // No history or negligible

      final percentAbove = ((entry.value - avg) / avg) * 100;
      if (percentAbove > 50) {
        alerts.add({
          'category': entry.key,
          'currentAmount': entry.value,
          'averageAmount': avg,
          'percentAbove': percentAbove,
        });
      }
    }

    // Sort by percentAbove descending
    alerts.sort((a, b) =>
        (b['percentAbove'] as double).compareTo(a['percentAbove'] as double));

    return alerts;
  }

  // Get last 6 months data for chart
  List<Map<String, dynamic>> getLast6MonthsData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> monthlyData = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

      final monthTransactions = state.transactions.where((t) =>
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();

      double income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      double expense = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      monthlyData.add({
        'month': monthDate,
        'income': income,
        'expense': expense,
        'net': income - expense,
      });
    }

    return monthlyData;
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final transaction = state.transactions.firstWhere((t) => t.id == transactionId);
      
      await _databaseService.deleteTransaction(transactionId);
      
      final accountNotifier = _ref.read(accountProvider.notifier);
      final account = accountNotifier.getAccountById(transaction.accountId);
      
      if (account != null) {
        double balanceAdjustment = 0.0;
        
        if (account.isCreditCard) {
          // For credit cards: reverse the debt calculation
          switch (transaction.type) {
            case TransactionType.income:
              balanceAdjustment = transaction.amount; // Removing payment increases debt
              break;
            case TransactionType.expense:
              balanceAdjustment = -transaction.amount; // Removing spending decreases debt
              break;
            case TransactionType.transfer:
              break;
          }
        } else {
          // For regular accounts: reverse the balance calculation
          switch (transaction.type) {
            case TransactionType.income:
              balanceAdjustment = -transaction.amount;
              break;
            case TransactionType.expense:
              balanceAdjustment = transaction.amount;
              break;
            case TransactionType.transfer:
              break;
          }
        }
        
        if (balanceAdjustment != 0) {
          await accountNotifier.updateAccountBalance(
            transaction.accountId,
            account.balance + balanceAdjustment,
          );
        }
      }
      
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != transactionId).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  Future<void> deleteMultipleTransactions(List<String> ids) async {
    try {
      final toDelete = state.transactions.where((t) => ids.contains(t.id)).toList();

      await _databaseService.deleteMultipleTransactions(ids);

      // Reverse balances for each deleted transaction
      final accountNotifier = _ref.read(accountProvider.notifier);
      final balanceAdjustments = <String, double>{};

      for (final transaction in toDelete) {
        final account = accountNotifier.getAccountById(transaction.accountId);
        if (account == null) continue;

        double adj = 0.0;
        if (account.isCreditCard) {
          switch (transaction.type) {
            case TransactionType.income:
              adj = transaction.amount;
              break;
            case TransactionType.expense:
              adj = -transaction.amount;
              break;
            case TransactionType.transfer:
              break;
          }
        } else {
          switch (transaction.type) {
            case TransactionType.income:
              adj = -transaction.amount;
              break;
            case TransactionType.expense:
              adj = transaction.amount;
              break;
            case TransactionType.transfer:
              break;
          }
        }

        balanceAdjustments[transaction.accountId] =
            (balanceAdjustments[transaction.accountId] ?? 0) + adj;
      }

      for (final entry in balanceAdjustments.entries) {
        final account = accountNotifier.getAccountById(entry.key);
        if (account != null && entry.value != 0) {
          await accountNotifier.updateAccountBalance(
            entry.key,
            account.balance + entry.value,
          );
        }
      }

      state = state.copyWith(
        transactions: state.transactions.where((t) => !ids.contains(t.id)).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});