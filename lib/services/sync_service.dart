import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'enhanced_api_service.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';
import '../models/account.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  final DatabaseService _databaseService = DatabaseService();
  final EnhancedApiService _apiService = EnhancedApiService();
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  bool get isSyncing => _isSyncing;
  
  // Helper method to get current user ID
  Future<String?> _getCurrentUserId() async {
    return await AuthService().getUserId();
  }

  Future<void> initialize() async {
    await ConnectivityService.initialize();
    
    _connectivitySubscription = ConnectivityService.connectivityStream.listen((isConnected) {
      if (isConnected && !_isSyncing && !_syncStatusController.isClosed) {
        syncPendingData();
      }
    });
    
    _startPeriodicSync();
    
    // Perform initial sync from server when app starts
    if (ConnectivityService.isConnected) {
      _performInitialSync();
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (ConnectivityService.isConnected && !_isSyncing && !_syncStatusController.isClosed) {
        syncPendingData();
      }
    });
  }

  Future<void> syncPendingData() async {
    if (_isSyncing || _syncStatusController.isClosed) return;
    
    _isSyncing = true;
    
    // Check if controller is closed before adding events
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(SyncStatus.syncing);
    }
    
    try {
      final serverReachable = await _apiService.isServerReachable();
      if (!serverReachable) {
        if (!_syncStatusController.isClosed) {
          _syncStatusController.add(SyncStatus.failed);
        }
        return;
      }

      await _syncPendingAccounts();
      await _syncPendingTransactions();
      await _syncPendingLoans();
      await _syncPendingLiabilities();
      await _syncPendingBudgets();
      await _syncPendingCategories();
      await _syncPendingSavingsGoals();
      await _syncPendingRecurringTransactions();
      
      if (!_syncStatusController.isClosed) {
        _syncStatusController.add(SyncStatus.synced);
      }
    } catch (e) {
      if (!_syncStatusController.isClosed) {
        _syncStatusController.add(SyncStatus.failed);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPendingAccounts() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();
    
    final pendingAccounts = await db.query(
      'accounts',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final accountData in pendingAccounts) {
      try {
        final account = Account.fromJson({
          'id': accountData['id'],
          'name': accountData['name'],
          'type': accountData['type'],
          'balance': accountData['balance'],
          'currency': accountData['currency'],
          'creditLimit': accountData['credit_limit'],
          'createdAt': accountData['created_at'],
          'updatedAt': accountData['updated_at'],
        });

        final success = await _apiService.syncAccount(account);
        if (success) {
          await _markAsSynced(db, 'accounts', account.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncPendingTransactions() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();
    
    final pendingTransactions = await db.query(
      'transactions',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final transactionData in pendingTransactions) {
      try {
        final transaction = transaction_model.Transaction.fromJson({
          'id': transactionData['id'],
          'accountId': transactionData['account_id'],
          'type': transactionData['type'],
          'amount': transactionData['amount'],
          'currency': transactionData['currency'],
          'category': transactionData['category'],
          'description': transactionData['description'],
          'date': transactionData['date'],
          'createdAt': transactionData['created_at'],
        });

        final success = await _apiService.syncTransaction(transaction);
        if (success) {
          await _markAsSynced(db, 'transactions', transaction.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncPendingLoans() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();
    
    final pendingLoans = await db.query(
      'loans',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final loanData in pendingLoans) {
      try {
        final loan = Loan.fromJson({
          'id': loanData['id'],
          'personName': loanData['person_name'],
          'amount': loanData['amount'],
          'currency': loanData['currency'],
          'loanDate': loanData['loan_date'],
          'returnDate': loanData['return_date'],
          'isReturned': loanData['is_returned'] == 1,
          'description': loanData['description'],
          'createdAt': loanData['created_at'],
          'updatedAt': loanData['updated_at'],
        });

        final success = await _apiService.syncLoan(loan);
        if (success) {
          await _markAsSynced(db, 'loans', loan.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncPendingLiabilities() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();
    
    final pendingLiabilities = await db.query(
      'liabilities',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final liabilityData in pendingLiabilities) {
      try {
        final liability = Liability.fromJson({
          'id': liabilityData['id'],
          'personName': liabilityData['person_name'],
          'amount': liabilityData['amount'],
          'currency': liabilityData['currency'],
          'dueDate': liabilityData['due_date'],
          'isPaid': liabilityData['is_paid'] == 1,
          'description': liabilityData['description'],
          'createdAt': liabilityData['created_at'],
          'updatedAt': liabilityData['updated_at'],
        });

        final success = await _apiService.syncLiability(liability);
        if (success) {
          await _markAsSynced(db, 'liabilities', liability.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncPendingBudgets() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();

    final pendingBudgets = await db.query(
      'budgets',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final budgetData in pendingBudgets) {
      try {
        final budget = Budget.fromJson({
          'id': budgetData['id'],
          'category': budgetData['category'],
          'amount': budgetData['amount'],
          'currency': budgetData['currency'],
          'period': budgetData['period'],
          'createdAt': budgetData['created_at'],
          'updatedAt': budgetData['updated_at'],
        });

        final success = await _apiService.syncBudget(budget);
        if (success) {
          await _markAsSynced(db, 'budgets', budget.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncPendingCategories() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();

    final pendingCategories = await db.query(
      'categories',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final catData in pendingCategories) {
      try {
        final category = Category.fromJson({
          'id': catData['id'],
          'name': catData['name'],
          'type': catData['type'],
          'iconCodePoint': catData['icon_code_point'],
          'colorValue': catData['color_value'],
          'isDefault': catData['is_default'] == 1,
          'createdAt': catData['created_at'],
        });

        final success = await _apiService.syncCategory(category);
        if (success) {
          await _markAsSynced(db, 'categories', category.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncPendingSavingsGoals() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();

    final pendingGoals = await db.query(
      'savings_goals',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final goalData in pendingGoals) {
      try {
        final goal = SavingsGoal.fromJson({
          'id': goalData['id'],
          'name': goalData['name'],
          'targetAmount': goalData['target_amount'],
          'currentAmount': goalData['current_amount'],
          'currency': goalData['currency'],
          'targetDate': goalData['target_date'],
          'description': goalData['description'],
          'accountId': goalData['account_id'],
          'priority': goalData['priority'],
          'isCompleted': goalData['is_completed'] == 1,
          'createdAt': goalData['created_at'],
          'updatedAt': goalData['updated_at'],
        });

        final success = await _apiService.syncSavingsGoal(goal);
        if (success) {
          await _markAsSynced(db, 'savings_goals', goal.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncPendingRecurringTransactions() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();

    final pendingRts = await db.query(
      'recurring_transactions',
      where: userId != null ? 'sync_status = ? AND user_id = ?' : 'sync_status = ?',
      whereArgs: userId != null ? ['pending', userId] : ['pending'],
    );

    for (final rtData in pendingRts) {
      try {
        final rt = RecurringTransaction.fromJson({
          'id': rtData['id'],
          'accountId': rtData['account_id'],
          'type': rtData['type'],
          'amount': rtData['amount'],
          'currency': rtData['currency'],
          'category': rtData['category'],
          'description': rtData['description'],
          'frequency': rtData['frequency'],
          'startDate': rtData['start_date'],
          'endDate': rtData['end_date'],
          'nextDueDate': rtData['next_due_date'],
          'isActive': rtData['is_active'] == 1,
          'savingsGoalId': rtData['savings_goal_id'],
          'createdAt': rtData['created_at'],
          'updatedAt': rtData['updated_at'],
        });

        final success = await _apiService.syncRecurringTransaction(rt);
        if (success) {
          await _markAsSynced(db, 'recurring_transactions', rt.id);
        }
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _markAsSynced(Database db, String table, String id) async {
    await db.update(
      table,
      {
        'sync_status': 'synced',
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markForSync(String table, String id) async {
    final db = await _databaseService.database;
    await db.update(
      table,
      {'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (ConnectivityService.isConnected && !_isSyncing) {
      // Use Future.delayed to avoid circular calls
      Future.delayed(const Duration(milliseconds: 100), () {
        syncPendingData();
      });
    }
  }

  Future<int> getPendingItemsCount() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();
    
    final accountsCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null 
        ? 'SELECT COUNT(*) FROM accounts WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM accounts WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;
    
    final transactionsCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null 
        ? 'SELECT COUNT(*) FROM transactions WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM transactions WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;
    
    final loansCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null 
        ? 'SELECT COUNT(*) FROM loans WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM loans WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;
    
    final liabilitiesCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null
        ? 'SELECT COUNT(*) FROM liabilities WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM liabilities WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;

    final budgetsCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null
        ? 'SELECT COUNT(*) FROM budgets WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM budgets WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;

    final categoriesCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null
        ? 'SELECT COUNT(*) FROM categories WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM categories WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;

    final savingsGoalsCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null
        ? 'SELECT COUNT(*) FROM savings_goals WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM savings_goals WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;

    final recurringCount = Sqflite.firstIntValue(await db.rawQuery(
      userId != null
        ? 'SELECT COUNT(*) FROM recurring_transactions WHERE sync_status = ? AND user_id = ?'
        : 'SELECT COUNT(*) FROM recurring_transactions WHERE sync_status = ?',
      userId != null ? ['pending', userId] : ['pending']
    )) ?? 0;

    final total = accountsCount + transactionsCount + loansCount + liabilitiesCount
        + budgetsCount + categoriesCount + savingsGoalsCount + recurringCount;

    print('🔍 Pending Items Count:');
    print('  Accounts: $accountsCount');
    print('  Transactions: $transactionsCount');
    print('  Loans: $loansCount');
    print('  Liabilities: $liabilitiesCount');
    print('  Budgets: $budgetsCount');
    print('  Categories: $categoriesCount');
    print('  Savings Goals: $savingsGoalsCount');
    print('  Recurring: $recurringCount');
    print('  Total: $total');

    return total;
  }

  Future<void> forceSyncAll() async {
    final db = await _databaseService.database;
    final userId = await _getCurrentUserId();
    
    final tables = ['accounts', 'transactions', 'loans', 'liabilities', 'budgets', 'categories', 'savings_goals', 'recurring_transactions'];
    for (final table in tables) {
      if (userId != null) {
        await db.update(table, {'sync_status': 'pending'}, where: 'user_id = ?', whereArgs: [userId]);
      } else {
        await db.update(table, {'sync_status': 'pending'});
      }
    }
    
    await syncPendingData();
  }

  /// Downloads all user data from server and merges into local database.
  /// Respects local pending changes (won't overwrite them).
  /// Order: accounts → transactions → loans → liabilities, then push pending.
  Future<void> downloadAllServerData() async {
    print('📥 Downloading all server data...');

    try {
      final serverReachable = await _apiService.isServerReachable();
      if (!serverReachable) {
        print('❌ Server not reachable for data download');
        return;
      }

      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        print('❌ No user ID available for data download');
        return;
      }

      // 1. Fetch and upsert accounts first (transactions depend on them)
      final accounts = await _apiService.fetchAccounts();
      print('📊 Processing ${accounts.length} accounts from server...');
      for (final account in accounts) {
        try {
          await _databaseService.upsertAccountFromServer(account, userId);
        } catch (e) {
          print('⚠️ Error upserting account ${account['id']}: $e');
        }
      }

      // 2. Fetch and upsert transactions (requires accounts to exist)
      final transactions = await _apiService.fetchTransactions();
      print('💰 Processing ${transactions.length} transactions from server...');
      for (final transaction in transactions) {
        try {
          await _databaseService.upsertTransactionFromServer(transaction, userId);
        } catch (e) {
          print('⚠️ Error upserting transaction ${transaction['id']}: $e');
        }
      }

      // 3. Fetch and upsert loans
      final loans = await _apiService.fetchLoans();
      print('💸 Processing ${loans.length} loans from server...');
      for (final loan in loans) {
        try {
          await _databaseService.upsertLoanFromServer(loan, userId);
        } catch (e) {
          print('⚠️ Error upserting loan ${loan['id']}: $e');
        }
      }

      // 4. Fetch and upsert liabilities
      final liabilities = await _apiService.fetchLiabilities();
      print('📋 Processing ${liabilities.length} liabilities from server...');
      for (final liability in liabilities) {
        try {
          await _databaseService.upsertLiabilityFromServer(liability, userId);
        } catch (e) {
          print('⚠️ Error upserting liability ${liability['id']}: $e');
        }
      }

      // 5. Fetch and upsert budgets
      final budgets = await _apiService.fetchBudgets();
      print('📊 Processing ${budgets.length} budgets from server...');
      for (final budget in budgets) {
        try {
          await _databaseService.upsertBudgetFromServer(budget, userId);
        } catch (e) {
          print('⚠️ Error upserting budget ${budget['id']}: $e');
        }
      }

      // 6. Fetch and upsert categories
      final categories = await _apiService.fetchCategories();
      print('🏷️ Processing ${categories.length} categories from server...');
      for (final category in categories) {
        try {
          await _databaseService.upsertCategoryFromServer(category, userId);
        } catch (e) {
          print('⚠️ Error upserting category ${category['id']}: $e');
        }
      }

      // 7. Fetch and upsert savings goals
      final savingsGoals = await _apiService.fetchSavingsGoals();
      print('🎯 Processing ${savingsGoals.length} savings goals from server...');
      for (final goal in savingsGoals) {
        try {
          await _databaseService.upsertSavingsGoalFromServer(goal, userId);
        } catch (e) {
          print('⚠️ Error upserting savings goal ${goal['id']}: $e');
        }
      }

      // 8. Fetch and upsert recurring transactions
      final recurringTxns = await _apiService.fetchRecurringTransactions();
      print('🔄 Processing ${recurringTxns.length} recurring transactions from server...');
      for (final rt in recurringTxns) {
        try {
          await _databaseService.upsertRecurringTransactionFromServer(rt, userId);
        } catch (e) {
          print('⚠️ Error upserting recurring transaction ${rt['id']}: $e');
        }
      }

      print('✅ Server data download completed: ${accounts.length} accounts, ${transactions.length} transactions, ${loans.length} loans, ${liabilities.length} liabilities, ${budgets.length} budgets, ${categories.length} categories, ${savingsGoals.length} savings goals, ${recurringTxns.length} recurring transactions');
    } catch (e) {
      print('❌ Error downloading server data: $e');
    }
  }

  Future<void> _performInitialSync() async {
    print('🔄 Performing initial sync from server...');

    try {
      final serverReachable = await _apiService.isServerReachable();
      if (!serverReachable) {
        print('❌ Server not reachable for initial sync');
        return;
      }

      // First pull data from server into local database
      await downloadAllServerData();

      // Then push any pending local changes to server
      await syncPendingData();

      print('✅ Initial sync completed');
    } catch (e) {
      print('❌ Initial sync failed: $e');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isSyncing = false;
    
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    if (!_syncStatusController.isClosed) {
      _syncStatusController.close();
    }
    
    ConnectivityService.dispose();
  }
  
  bool get isDisposed => _syncStatusController.isClosed;
}