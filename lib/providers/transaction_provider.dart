import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
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
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});