import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/account.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/loan.dart';
import '../models/liability.dart';
import 'database_service.dart';

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

    // Add error interceptor for better error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        print('🚨 API Error: ${error.response?.statusCode} - ${error.message}');
        if (error.response?.data != null) {
          print('🚨 Error Data: ${error.response?.data}');
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
        throw e;
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
}