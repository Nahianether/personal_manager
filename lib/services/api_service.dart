import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/account.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/loan.dart';
import '../models/liability.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final Dio _dio;
  
  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: ApiConfig.defaultHeaders,
    ));
    
    // Add authentication interceptor
    _addAuthInterceptor();
    
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  void _addAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          print('Error getting auth token: $e');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid, clear stored data
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('user_id');
            await prefs.remove('user_name');
            await prefs.remove('user_email');
            await prefs.setBool('is_logged_in', false);
            print('🔄 Cleared expired auth data');
          } catch (e) {
            print('Error clearing auth data: $e');
          }
        }
        handler.next(error);
      },
    ));
  }

  // Account API endpoints
  Future<bool> syncAccount(Account account) async {
    try {
      final accountData = account.toJson();
      print('📤 ACCOUNT API CALL:');
      print('  URL: POST /api/accounts');
      print('  Body: $accountData');
      
      final response = await _dio.post('/api/accounts', data: accountData);
      
      print('📥 ACCOUNT API RESPONSE:');
      print('  Status: ${response.statusCode}');
      print('  Data: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error syncing account: $e');
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      final response = await _dio.put('/api/accounts/${account.id}', data: account.toJson());
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating account: $e');
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      final response = await _dio.delete('/api/accounts/$accountId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  // Transaction API endpoints
  Future<bool> syncTransaction(transaction_model.Transaction transaction) async {
    try {
      final transactionData = transaction.toJson();
      print('📤 TRANSACTION API CALL:');
      print('  URL: POST /api/transactions');
      print('  Body: $transactionData');
      
      final response = await _dio.post('/api/transactions', data: transactionData);
      
      print('📥 TRANSACTION API RESPONSE:');
      print('  Status: ${response.statusCode}');
      print('  Data: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error syncing transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(transaction_model.Transaction transaction) async {
    try {
      final response = await _dio.put('/api/transactions/${transaction.id}', data: transaction.toJson());
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final response = await _dio.delete('/api/transactions/$transactionId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Loan API endpoints
  Future<bool> syncLoan(Loan loan) async {
    try {
      final loanData = loan.toJson();
      print('📤 LOAN API CALL:');
      print('  URL: POST /api/loans');
      print('  Body: $loanData');
      
      final response = await _dio.post('/api/loans', data: loanData);
      
      print('📥 LOAN API RESPONSE:');
      print('  Status: ${response.statusCode}');
      print('  Data: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error syncing loan: $e');
      return false;
    }
  }

  Future<bool> updateLoan(Loan loan) async {
    try {
      final response = await _dio.put('/api/loans/${loan.id}', data: loan.toJson());
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating loan: $e');
      return false;
    }
  }

  Future<bool> deleteLoan(String loanId) async {
    try {
      final response = await _dio.delete('/api/loans/$loanId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting loan: $e');
      return false;
    }
  }

  // Liability API endpoints
  Future<bool> syncLiability(Liability liability) async {
    try {
      final liabilityData = liability.toJson();
      print('📤 LIABILITY API CALL:');
      print('  URL: POST /api/liabilities');
      print('  Body: $liabilityData');
      
      final response = await _dio.post('/api/liabilities', data: liabilityData);
      
      print('📥 LIABILITY API RESPONSE:');
      print('  Status: ${response.statusCode}');
      print('  Data: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error syncing liability: $e');
      return false;
    }
  }

  Future<bool> updateLiability(Liability liability) async {
    try {
      final response = await _dio.put('/api/liabilities/${liability.id}', data: liability.toJson());
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating liability: $e');
      return false;
    }
  }

  Future<bool> deleteLiability(String liabilityId) async {
    try {
      final response = await _dio.delete('/api/liabilities/$liabilityId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting liability: $e');
      return false;
    }
  }

  // Batch sync endpoints
  Future<bool> batchSyncAccounts(List<Account> accounts) async {
    try {
      final data = accounts.map((account) => account.toJson()).toList();
      final batchData = {'accounts': data};
      
      print('📤 BATCH ACCOUNTS API CALL:');
      print('  URL: POST /accounts/batch');
      print('  Body: $batchData');
      print('  Count: ${accounts.length} accounts');
      
      final response = await _dio.post('/accounts/batch', data: batchData);
      
      print('📥 BATCH ACCOUNTS API RESPONSE:');
      print('  Status: ${response.statusCode}');
      print('  Data: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error batch syncing accounts: $e');
      return false;
    }
  }

  Future<bool> batchSyncTransactions(List<transaction_model.Transaction> transactions) async {
    try {
      final data = transactions.map((transaction) => transaction.toJson()).toList();
      final response = await _dio.post('/transactions/batch', data: {'transactions': data});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error batch syncing transactions: $e');
      return false;
    }
  }

  Future<bool> batchSyncLoans(List<Loan> loans) async {
    try {
      final data = loans.map((loan) => loan.toJson()).toList();
      final response = await _dio.post('/loans/batch', data: {'loans': data});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error batch syncing loans: $e');
      return false;
    }
  }

  Future<bool> batchSyncLiabilities(List<Liability> liabilities) async {
    try {
      final data = liabilities.map((liability) => liability.toJson()).toList();
      final response = await _dio.post('/liabilities/batch', data: {'liabilities': data});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error batch syncing liabilities: $e');
      return false;
    }
  }

  // Health check - try multiple endpoints to verify server connectivity
  Future<bool> isServerReachable() async {
    try {
      // Try health endpoint first
      try {
        final response = await _dio.get('/health');
        return response.statusCode == 200;
      } catch (e) {
        // If health endpoint doesn't exist, try a simple GET request to root or accounts
        try {
          final response = await _dio.get('/accounts');
          // Even if it returns an error, if we get a response, server is reachable
          return response.statusCode != null;
        } catch (e2) {
          // Try root endpoint
          try {
            final response = await _dio.get('/');
            return response.statusCode != null;
          } catch (e3) {
            return false;
          }
        }
      }
    } catch (e) {
      print('Server not reachable: $e');
      return false;
    }
  }
}