import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/account.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';
import 'database_service.dart';
import 'auth_service.dart';

class EnhancedApiService {
  static final EnhancedApiService _instance = EnhancedApiService._internal();
  late final Dio _dio;
  
  factory EnhancedApiService() {
    return _instance;
  }

  EnhancedApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: ApiConfig.defaultHeaders,
    ));
    
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    // Add authentication interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add authentication token to all requests
        final token = await AuthService().getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('🚨 API Error: ${error.response?.statusCode} - ${error.message}');
        if (error.response?.data != null) {
          print('🚨 Error Data: ${error.response?.data}');
        }
        
        // Handle unauthorized errors
        if (error.response?.statusCode == 401) {
          // Token might be expired, sign out user
          AuthService().signout();
        }
        
        handler.next(error);
      },
    ));
  }

  /// Validates and sanitizes account data before sending to API
  Map<String, dynamic> _sanitizeAccountData(Account account) {
    return {
      'id': account.id,
      'name': account.name.trim(),
      'type': account.type.toString().split('.').last,
      'balance': account.balance,
      'currency': account.currency,
      'credit_limit': account.creditLimit, // snake_case for backend
      'created_at': account.createdAt.toUtc().toIso8601String(), // snake_case for backend
      'updated_at': account.updatedAt.toUtc().toIso8601String(), // snake_case for backend
    };
  }

  /// Validates and sanitizes transaction data before sending to API
  Map<String, dynamic> _sanitizeTransactionData(transaction_model.Transaction transaction) {
    return {
      'id': transaction.id,
      'account_id': transaction.accountId, // snake_case for backend
      'type': transaction.type.toString().split('.').last,
      'amount': transaction.amount,
      'currency': transaction.currency,
      'category': transaction.category?.trim(),
      'description': transaction.description?.trim(),
      'date': transaction.date.toUtc().toIso8601String(),
      'created_at': transaction.createdAt.toUtc().toIso8601String(), // snake_case for backend
    };
  }

  /// Validates and sanitizes loan data before sending to API
  Map<String, dynamic> _sanitizeLoanData(Loan loan) {
    return {
      'id': loan.id,
      'person_name': loan.personName.trim(), // snake_case for backend
      'amount': loan.amount,
      'currency': loan.currency,
      'loan_date': loan.loanDate.toUtc().toIso8601String(), // snake_case for backend
      'return_date': loan.returnDate?.toUtc().toIso8601String(), // snake_case for backend
      'is_returned': loan.isReturned, // snake_case for backend
      'description': loan.description?.trim(),
      'created_at': loan.createdAt.toUtc().toIso8601String(), // snake_case for backend
      'updated_at': loan.updatedAt.toUtc().toIso8601String(), // snake_case for backend
      'is_historical_entry': loan.isHistoricalEntry, // snake_case for backend
      'account_id': loan.accountId, // snake_case for backend
      'transaction_id': loan.transactionId, // snake_case for backend
    };
  }

  /// Validates and sanitizes liability data before sending to API
  Map<String, dynamic> _sanitizeLiabilityData(Liability liability) {
    return {
      'id': liability.id,
      'person_name': liability.personName.trim(), // snake_case for backend
      'amount': liability.amount,
      'currency': liability.currency,
      'due_date': liability.dueDate.toUtc().toIso8601String(), // snake_case for backend
      'is_paid': liability.isPaid, // snake_case for backend
      'description': liability.description?.trim(),
      'created_at': liability.createdAt.toUtc().toIso8601String(), // snake_case for backend
      'updated_at': liability.updatedAt.toUtc().toIso8601String(), // snake_case for backend
      'is_historical_entry': liability.isHistoricalEntry, // snake_case for backend
      'account_id': liability.accountId, // snake_case for backend
      'transaction_id': liability.transactionId, // snake_case for backend
    };
  }

  /// Validates and sanitizes budget data before sending to API
  Map<String, dynamic> _sanitizeBudgetData(Budget budget) {
    return {
      'id': budget.id,
      'category': budget.category.trim(),
      'amount': budget.amount,
      'currency': budget.currency,
      'period': budget.period.toString().split('.').last,
      'created_at': budget.createdAt.toUtc().toIso8601String(),
      'updated_at': budget.updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Validates and sanitizes category data before sending to API
  Map<String, dynamic> _sanitizeCategoryData(Category category) {
    return {
      'id': category.id,
      'name': category.name.trim(),
      'type': category.type.toString().split('.').last,
      'icon_code_point': category.icon.codePoint,
      'color_value': category.color.toARGB32(),
      'is_default': category.isDefault,
      'created_at': category.createdAt.toUtc().toIso8601String(),
    };
  }

  /// Validates and sanitizes savings goal data before sending to API
  Map<String, dynamic> _sanitizeSavingsGoalData(SavingsGoal goal) {
    return {
      'id': goal.id,
      'name': goal.name.trim(),
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'currency': goal.currency,
      'target_date': goal.targetDate.toUtc().toIso8601String(),
      'description': goal.description?.trim(),
      'account_id': goal.accountId,
      'priority': goal.priority,
      'is_completed': goal.isCompleted,
      'created_at': goal.createdAt.toUtc().toIso8601String(),
      'updated_at': goal.updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Validates and sanitizes recurring transaction data before sending to API
  Map<String, dynamic> _sanitizeRecurringTransactionData(RecurringTransaction rt) {
    return {
      'id': rt.id,
      'account_id': rt.accountId,
      'transaction_type': rt.type.toString().split('.').last,
      'amount': rt.amount,
      'currency': rt.currency,
      'category': rt.category?.trim(),
      'description': rt.description?.trim(),
      'frequency': rt.frequency.toString().split('.').last,
      'start_date': rt.startDate.toUtc().toIso8601String(),
      'end_date': rt.endDate?.toUtc().toIso8601String(),
      'next_due_date': rt.nextDueDate.toUtc().toIso8601String(),
      'is_active': rt.isActive,
      'savings_goal_id': rt.savingsGoalId,
      'created_at': rt.createdAt.toUtc().toIso8601String(),
      'updated_at': rt.updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Health check with multiple fallback endpoints
  Future<bool> isServerReachable() async {
    final endpoints = ['/health', '/', '/accounts'];
    
    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get(endpoint);
        if (response.statusCode != null && response.statusCode! < 500) {
          print('✅ Server reachable via $endpoint');
          return true;
        }
      } catch (e) {
        print('❌ Failed to reach $endpoint: $e');
        continue;
      }
    }
    
    print('🚨 Server unreachable on all endpoints');
    return false;
  }

  /// Account API endpoints with enhanced error handling
  Future<bool> syncAccount(Account account) async {
    try {
      final accountData = _sanitizeAccountData(account);
      print('📤 ACCOUNT SYNC: ${account.name} (${account.type})');
      
      final response = await _dio.post('/accounts', data: accountData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Account synced successfully');
        return true;
      } else {
        print('⚠️ Unexpected status code: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        print('ℹ️ Account already exists, attempting update...');
        return await updateAccount(account);
      } else {
        print('❌ Account sync failed: ${e.response?.statusCode} - ${e.message}');
        return false;
      }
    } catch (e) {
      print('❌ Unexpected error syncing account: $e');
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      final accountData = _sanitizeAccountData(account);
      final response = await _dio.put('/accounts/${account.id}', data: accountData);
      
      if (response.statusCode == 200) {
        print('✅ Account updated successfully');
        return true;
      } else {
        print('⚠️ Account update unexpected status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Account update failed: $e');
      return false;
    }
  }

  /// Transaction API with account dependency check
  Future<bool> syncTransaction(transaction_model.Transaction transaction) async {
    try {
      // First verify account exists and create if needed
      await ensureAccountExistsOnServer(transaction.accountId);

      final transactionData = _sanitizeTransactionData(transaction);
      print('📤 TRANSACTION SYNC: ${transaction.type} ${transaction.amount} ${transaction.currency}');
      
      final response = await _dio.post('/transactions', data: transactionData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Transaction synced successfully');
        return true;
      } else {
        print('⚠️ Transaction unexpected status: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        print('ℹ️ Transaction already exists, attempting update...');
        return await updateTransaction(transaction);
      } else if (e.response?.statusCode == 400) {
        print('❌ Transaction validation failed: ${e.response?.data}');
        return false;
      } else {
        print('❌ Transaction sync failed: ${e.response?.statusCode} - ${e.message}');
        return false;
      }
    } catch (e) {
      print('❌ Unexpected error syncing transaction: $e');
      return false;
    }
  }

  /// Ensures account exists on server, creates it if missing
  Future<void> ensureAccountExistsOnServer(String accountId) async {
    try {
      // Try to get the account from server
      await _dio.get('/accounts/$accountId');
      print('✅ Account $accountId exists on server');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print('ℹ️ Account $accountId not found on server, creating it...');
        
        // Account doesn't exist, get it from local database and sync it
        try {
          final accounts = await DatabaseService().getAllAccounts();
          final account = accounts.firstWhere((acc) => acc.id == accountId);
          
          final success = await syncAccount(account);
          if (success) {
            print('✅ Account $accountId created on server');
          } else {
            print('⚠️ Failed to create account $accountId on server');
          }
        } catch (localError) {
          print('❌ Account $accountId not found locally: $localError');
          throw Exception('Account $accountId not found locally or on server');
        }
      } else {
        // Some other error checking account
        print('⚠️ Error checking account $accountId: ${e.response?.statusCode}');
        rethrow;
      }
    }
  }

  Future<bool> updateTransaction(transaction_model.Transaction transaction) async {
    try {
      final transactionData = _sanitizeTransactionData(transaction);
      final response = await _dio.put('/transactions/${transaction.id}', data: transactionData);
      
      if (response.statusCode == 200) {
        print('✅ Transaction updated successfully');
        return true;
      } else {
        print('⚠️ Transaction update unexpected status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Transaction update failed: $e');
      return false;
    }
  }

  /// Loan API endpoints
  Future<bool> syncLoan(Loan loan) async {
    try {
      final loanData = _sanitizeLoanData(loan);
      print('📤 LOAN SYNC: ${loan.personName} - ${loan.amount} ${loan.currency}');
      
      final response = await _dio.post('/loans', data: loanData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Loan synced successfully');
        return true;
      } else {
        print('⚠️ Loan unexpected status: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        print('ℹ️ Loan already exists, attempting update...');
        return await updateLoan(loan);
      } else {
        print('❌ Loan sync failed: ${e.response?.statusCode} - ${e.message}');
        return false;
      }
    } catch (e) {
      print('❌ Unexpected error syncing loan: $e');
      return false;
    }
  }

  Future<bool> updateLoan(Loan loan) async {
    try {
      final loanData = _sanitizeLoanData(loan);
      final response = await _dio.put('/loans/${loan.id}', data: loanData);
      
      if (response.statusCode == 200) {
        print('✅ Loan updated successfully');
        return true;
      } else {
        print('⚠️ Loan update unexpected status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Loan update failed: $e');
      return false;
    }
  }

  /// Liability API endpoints
  Future<bool> syncLiability(Liability liability) async {
    try {
      final liabilityData = _sanitizeLiabilityData(liability);
      print('📤 LIABILITY SYNC: ${liability.personName} - ${liability.amount} ${liability.currency}');
      
      final response = await _dio.post('/liabilities', data: liabilityData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Liability synced successfully');
        return true;
      } else {
        print('⚠️ Liability unexpected status: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        print('ℹ️ Liability already exists, attempting update...');
        return await updateLiability(liability);
      } else {
        print('❌ Liability sync failed: ${e.response?.statusCode} - ${e.message}');
        return false;
      }
    } catch (e) {
      print('❌ Unexpected error syncing liability: $e');
      return false;
    }
  }

  Future<bool> updateLiability(Liability liability) async {
    try {
      final liabilityData = _sanitizeLiabilityData(liability);
      final response = await _dio.put('/liabilities/${liability.id}', data: liabilityData);
      
      if (response.statusCode == 200) {
        print('✅ Liability updated successfully');
        return true;
      } else {
        print('⚠️ Liability update unexpected status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Liability update failed: $e');
      return false;
    }
  }

  /// Budget API endpoints
  Future<bool> syncBudget(Budget budget) async {
    try {
      final data = _sanitizeBudgetData(budget);
      print('📤 BUDGET SYNC: ${budget.category} - ${budget.amount} ${budget.currency}');
      final response = await _dio.post('/budgets', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Budget synced successfully');
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return await updateBudget(budget);
      }
      print('❌ Budget sync failed: ${e.response?.statusCode} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error syncing budget: $e');
      return false;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    try {
      final data = _sanitizeBudgetData(budget);
      final response = await _dio.put('/budgets/${budget.id}', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Budget update failed: $e');
      return false;
    }
  }

  /// Category API endpoints
  Future<bool> syncCategory(Category category) async {
    try {
      final data = _sanitizeCategoryData(category);
      print('📤 CATEGORY SYNC: ${category.name}');
      final response = await _dio.post('/categories', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Category synced successfully');
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return await updateCategory(category);
      }
      print('❌ Category sync failed: ${e.response?.statusCode} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error syncing category: $e');
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      final data = _sanitizeCategoryData(category);
      final response = await _dio.put('/categories/${category.id}', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Category update failed: $e');
      return false;
    }
  }

  /// Savings Goal API endpoints
  Future<bool> syncSavingsGoal(SavingsGoal goal) async {
    try {
      final data = _sanitizeSavingsGoalData(goal);
      print('📤 SAVINGS GOAL SYNC: ${goal.name} - ${goal.targetAmount} ${goal.currency}');
      final response = await _dio.post('/savings_goals', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Savings goal synced successfully');
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return await updateSavingsGoal(goal);
      }
      print('❌ Savings goal sync failed: ${e.response?.statusCode} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error syncing savings goal: $e');
      return false;
    }
  }

  Future<bool> updateSavingsGoal(SavingsGoal goal) async {
    try {
      final data = _sanitizeSavingsGoalData(goal);
      final response = await _dio.put('/savings_goals/${goal.id}', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Savings goal update failed: $e');
      return false;
    }
  }

  /// Recurring Transaction API endpoints
  Future<bool> syncRecurringTransaction(RecurringTransaction rt) async {
    try {
      await ensureAccountExistsOnServer(rt.accountId);
      final data = _sanitizeRecurringTransactionData(rt);
      print('📤 RECURRING TXN SYNC: ${rt.category ?? 'N/A'} - ${rt.amount} ${rt.currency}');
      final response = await _dio.post('/recurring_transactions', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Recurring transaction synced successfully');
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return await updateRecurringTransaction(rt);
      }
      print('❌ Recurring transaction sync failed: ${e.response?.statusCode} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error syncing recurring transaction: $e');
      return false;
    }
  }

  Future<bool> updateRecurringTransaction(RecurringTransaction rt) async {
    try {
      final data = _sanitizeRecurringTransactionData(rt);
      final response = await _dio.put('/recurring_transactions/${rt.id}', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Recurring transaction update failed: $e');
      return false;
    }
  }

  /// Enhanced batch sync with dependency ordering
  Future<bool> batchSyncAll({
    List<Account>? accounts,
    List<transaction_model.Transaction>? transactions,
    List<Loan>? loans,
    List<Liability>? liabilities,
  }) async {
    bool allSuccess = true;
    
    try {
      print('🔄 Starting comprehensive batch sync...');
      
      // 1. Sync accounts first (required for transactions)
      if (accounts != null && accounts.isNotEmpty) {
        print('📊 Syncing ${accounts.length} accounts...');
        for (final account in accounts) {
          final success = await syncAccount(account);
          if (!success) allSuccess = false;
        }
      }

      // 2. Sync transactions (requires accounts to exist)
      if (transactions != null && transactions.isNotEmpty) {
        print('💰 Syncing ${transactions.length} transactions...');
        for (final transaction in transactions) {
          final success = await syncTransaction(transaction);
          if (!success) allSuccess = false;
        }
      }

      // 3. Sync loans (independent)
      if (loans != null && loans.isNotEmpty) {
        print('💸 Syncing ${loans.length} loans...');
        for (final loan in loans) {
          final success = await syncLoan(loan);
          if (!success) allSuccess = false;
        }
      }

      // 4. Sync liabilities (independent)
      if (liabilities != null && liabilities.isNotEmpty) {
        print('📋 Syncing ${liabilities.length} liabilities...');
        for (final liability in liabilities) {
          final success = await syncLiability(liability);
          if (!success) allSuccess = false;
        }
      }

      if (allSuccess) {
        print('✅ All data synced successfully!');
      } else {
        print('⚠️ Some items failed to sync');
      }
      
      return allSuccess;
    } catch (e) {
      print('❌ Batch sync failed: $e');
      return false;
    }
  }

  // ─── Server-to-Local: Fetch methods ───────────────────────────────

  /// Convert server snake_case account response to Flutter camelCase
  Map<String, dynamic> _convertAccountFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'name': data['name'],
      'type': data['account_type'] ?? data['type'],
      'balance': data['balance'],
      'currency': data['currency'] ?? 'BDT',
      'creditLimit': data['credit_limit'] ?? data['creditLimit'],
      'createdAt': data['created_at'] ?? data['createdAt'],
      'updatedAt': data['updated_at'] ?? data['updatedAt'],
    };
  }

  /// Convert server snake_case transaction response to Flutter camelCase
  Map<String, dynamic> _convertTransactionFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'accountId': data['account_id'] ?? data['accountId'],
      'type': data['transaction_type'] ?? data['type'],
      'amount': data['amount'],
      'currency': data['currency'] ?? 'BDT',
      'category': data['category'],
      'description': data['description'],
      'date': data['date'],
      'createdAt': data['created_at'] ?? data['createdAt'],
    };
  }

  /// Convert server snake_case loan response to Flutter camelCase
  Map<String, dynamic> _convertLoanFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'personName': data['person_name'] ?? data['personName'],
      'amount': data['amount'],
      'currency': data['currency'] ?? 'BDT',
      'loanDate': data['loan_date'] ?? data['loanDate'],
      'returnDate': data['return_date'] ?? data['returnDate'],
      'isReturned': data['is_returned'] ?? data['isReturned'] ?? false,
      'description': data['description'],
      'createdAt': data['created_at'] ?? data['createdAt'],
      'updatedAt': data['updated_at'] ?? data['updatedAt'],
      'isHistoricalEntry': data['is_historical_entry'] ?? data['isHistoricalEntry'] ?? false,
      'accountId': data['account_id'] ?? data['accountId'],
      'transactionId': data['transaction_id'] ?? data['transactionId'],
    };
  }

  /// Convert server snake_case liability response to Flutter camelCase
  Map<String, dynamic> _convertLiabilityFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'personName': data['person_name'] ?? data['personName'],
      'amount': data['amount'],
      'currency': data['currency'] ?? 'BDT',
      'dueDate': data['due_date'] ?? data['dueDate'],
      'isPaid': data['is_paid'] ?? data['isPaid'] ?? false,
      'description': data['description'],
      'createdAt': data['created_at'] ?? data['createdAt'],
      'updatedAt': data['updated_at'] ?? data['updatedAt'],
      'isHistoricalEntry': data['is_historical_entry'] ?? data['isHistoricalEntry'] ?? false,
      'accountId': data['account_id'] ?? data['accountId'],
      'transactionId': data['transaction_id'] ?? data['transactionId'],
    };
  }

  /// Convert server snake_case budget response to Flutter camelCase
  Map<String, dynamic> _convertBudgetFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'category': data['category'],
      'amount': data['amount'],
      'currency': data['currency'] ?? 'BDT',
      'period': data['period'] ?? 'monthly',
      'createdAt': data['created_at'] ?? data['createdAt'],
      'updatedAt': data['updated_at'] ?? data['updatedAt'],
    };
  }

  /// Convert server snake_case category response to Flutter camelCase
  Map<String, dynamic> _convertCategoryFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'name': data['name'],
      'type': data['category_type'] ?? data['type'],
      'iconCodePoint': data['icon_code_point'] ?? data['iconCodePoint'] ?? 0xe1a0,
      'colorValue': data['color_value'] ?? data['colorValue'] ?? 0xFF9E9E9E,
      'isDefault': data['is_default'] ?? data['isDefault'] ?? false,
      'createdAt': data['created_at'] ?? data['createdAt'],
      'updatedAt': data['updated_at'] ?? data['updatedAt'],
    };
  }

  /// Convert server snake_case savings goal response to Flutter camelCase
  Map<String, dynamic> _convertSavingsGoalFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'name': data['name'],
      'targetAmount': data['target_amount'] ?? data['targetAmount'],
      'currentAmount': data['current_amount'] ?? data['currentAmount'] ?? 0.0,
      'currency': data['currency'] ?? 'BDT',
      'targetDate': data['target_date'] ?? data['targetDate'],
      'description': data['description'],
      'accountId': data['account_id'] ?? data['accountId'],
      'priority': data['priority'] ?? 'medium',
      'isCompleted': data['is_completed'] ?? data['isCompleted'] ?? false,
      'createdAt': data['created_at'] ?? data['createdAt'],
      'updatedAt': data['updated_at'] ?? data['updatedAt'],
    };
  }

  /// Convert server snake_case recurring transaction response to Flutter camelCase
  Map<String, dynamic> _convertRecurringTransactionFromServer(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString(),
      'accountId': data['account_id'] ?? data['accountId'],
      'transactionType': data['transaction_type'] ?? data['transactionType'] ?? data['type'],
      'type': data['transaction_type'] ?? data['type'],
      'amount': data['amount'],
      'currency': data['currency'] ?? 'BDT',
      'category': data['category'],
      'description': data['description'],
      'frequency': data['frequency'] ?? 'monthly',
      'startDate': data['start_date'] ?? data['startDate'],
      'endDate': data['end_date'] ?? data['endDate'],
      'nextDueDate': data['next_due_date'] ?? data['nextDueDate'],
      'isActive': data['is_active'] ?? data['isActive'] ?? true,
      'savingsGoalId': data['savings_goal_id'] ?? data['savingsGoalId'],
      'createdAt': data['created_at'] ?? data['createdAt'],
      'updatedAt': data['updated_at'] ?? data['updatedAt'],
    };
  }

  /// Parse response body that could be a list or wrapped in a key
  List<Map<String, dynamic>> _parseListResponse(dynamic responseData, String key) {
    if (responseData is List) {
      return responseData.cast<Map<String, dynamic>>();
    } else if (responseData is Map && responseData[key] is List) {
      return (responseData[key] as List).cast<Map<String, dynamic>>();
    } else if (responseData is Map && responseData['data'] is List) {
      return (responseData['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetch all accounts from server (uses /api/accounts for auth-protected, user-filtered data)
  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    try {
      print('📥 Fetching accounts from server...');
      final response = await _dio.get('/api/accounts');

      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'accounts');
        final converted = items.map((item) => _convertAccountFromServer(item)).toList();
        print('✅ Fetched ${converted.length} accounts from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching accounts from server: $e');
      return [];
    }
  }

  /// Fetch all transactions from server (uses /api/transactions for auth-protected, user-filtered data)
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    try {
      print('📥 Fetching transactions from server...');
      final response = await _dio.get('/api/transactions');

      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'transactions');
        final converted = items.map((item) => _convertTransactionFromServer(item)).toList();
        print('✅ Fetched ${converted.length} transactions from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching transactions from server: $e');
      return [];
    }
  }

  /// Fetch all loans from server (uses /api/loans for auth-protected, user-filtered data)
  Future<List<Map<String, dynamic>>> fetchLoans() async {
    try {
      print('📥 Fetching loans from server...');
      final response = await _dio.get('/api/loans');

      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'loans');
        final converted = items.map((item) => _convertLoanFromServer(item)).toList();
        print('✅ Fetched ${converted.length} loans from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching loans from server: $e');
      return [];
    }
  }

  /// Fetch all liabilities from server (uses /api/liabilities for auth-protected, user-filtered data)
  Future<List<Map<String, dynamic>>> fetchLiabilities() async {
    try {
      print('📥 Fetching liabilities from server...');
      final response = await _dio.get('/api/liabilities');

      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'liabilities');
        final converted = items.map((item) => _convertLiabilityFromServer(item)).toList();
        print('✅ Fetched ${converted.length} liabilities from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching liabilities from server: $e');
      return [];
    }
  }

  /// Fetch all budgets from server
  Future<List<Map<String, dynamic>>> fetchBudgets() async {
    try {
      print('📥 Fetching budgets from server...');
      final response = await _dio.get('/api/budgets');
      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'budgets');
        final converted = items.map((item) => _convertBudgetFromServer(item)).toList();
        print('✅ Fetched ${converted.length} budgets from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching budgets from server: $e');
      return [];
    }
  }

  /// Fetch all categories from server
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      print('📥 Fetching categories from server...');
      final response = await _dio.get('/api/categories');
      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'categories');
        final converted = items.map((item) => _convertCategoryFromServer(item)).toList();
        print('✅ Fetched ${converted.length} categories from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching categories from server: $e');
      return [];
    }
  }

  /// Fetch all savings goals from server
  Future<List<Map<String, dynamic>>> fetchSavingsGoals() async {
    try {
      print('📥 Fetching savings goals from server...');
      final response = await _dio.get('/api/savings_goals');
      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'savings_goals');
        final converted = items.map((item) => _convertSavingsGoalFromServer(item)).toList();
        print('✅ Fetched ${converted.length} savings goals from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching savings goals from server: $e');
      return [];
    }
  }

  /// Fetch all recurring transactions from server
  Future<List<Map<String, dynamic>>> fetchRecurringTransactions() async {
    try {
      print('📥 Fetching recurring transactions from server...');
      final response = await _dio.get('/api/recurring_transactions');
      if (response.statusCode == 200 && response.data != null) {
        final items = _parseListResponse(response.data, 'recurring_transactions');
        final converted = items.map((item) => _convertRecurringTransactionFromServer(item)).toList();
        print('✅ Fetched ${converted.length} recurring transactions from server');
        return converted;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching recurring transactions from server: $e');
      return [];
    }
  }

  /// Delete operations with proper error handling
  Future<bool> deleteAccount(String accountId) async {
    try {
      final response = await _dio.delete('/accounts/$accountId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting account: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final response = await _dio.delete('/transactions/$transactionId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      return false;
    }
  }

  Future<bool> deleteLoan(String loanId) async {
    try {
      final response = await _dio.delete('/loans/$loanId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting loan: $e');
      return false;
    }
  }

  Future<bool> deleteLiability(String liabilityId) async {
    try {
      final response = await _dio.delete('/liabilities/$liabilityId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting liability: $e');
      return false;
    }
  }

  Future<bool> deleteBudget(String budgetId) async {
    try {
      final response = await _dio.delete('/budgets/$budgetId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting budget: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      final response = await _dio.delete('/categories/$categoryId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting category: $e');
      return false;
    }
  }

  Future<bool> deleteSavingsGoal(String goalId) async {
    try {
      final response = await _dio.delete('/savings_goals/$goalId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting savings goal: $e');
      return false;
    }
  }

  Future<bool> deleteRecurringTransaction(String rtId) async {
    try {
      final response = await _dio.delete('/recurring_transactions/$rtId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting recurring transaction: $e');
      return false;
    }
  }
}