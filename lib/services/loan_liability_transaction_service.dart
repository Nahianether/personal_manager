import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/transaction.dart' as transaction_model;
import 'database_service.dart';
import 'enhanced_api_service.dart';

class LoanLiabilityTransactionService {
  static final LoanLiabilityTransactionService _instance = LoanLiabilityTransactionService._internal();
  static const uuid = Uuid();
  final EnhancedApiService _apiService = EnhancedApiService();
  
  factory LoanLiabilityTransactionService() {
    return _instance;
  }
  
  LoanLiabilityTransactionService._internal();

  /// Ensures account exists before creating transactions
  Future<void> _ensureAccountExists(String accountId) async {
    try {
      // Use the enhanced API service's better account verification
      await _apiService.ensureAccountExistsOnServer(accountId);
    } catch (e) {
      print('Warning: Could not ensure account exists: $e');
      // Continue anyway - might be a connectivity issue
    }
  }

  /// Creates a loan with automatic account debit for non-historical entries
  Future<Loan> createLoan({
    required String personName,
    required double amount,
    required String currency,
    required DateTime loanDate,
    String? description,
    required bool isHistoricalEntry,
    String? accountId, // Required for non-historical entries
  }) async {
    final now = DateTime.now();
    final loanId = uuid.v4();
    String? transactionId;

    // For non-historical entries, create a transaction to debit the account
    if (!isHistoricalEntry && accountId != null) {
      // Ensure account exists on server before creating transaction
      await _ensureAccountExists(accountId);
      
      transactionId = await _createLoanGivenTransaction(
        accountId: accountId,
        amount: amount,
        currency: currency,
        date: loanDate,
        description: 'Loan given to $personName',
        loanId: loanId,
      );
    }

    final loan = Loan(
      id: loanId,
      personName: personName,
      amount: amount,
      currency: currency,
      loanDate: loanDate,
      isHistoricalEntry: isHistoricalEntry,
      accountId: accountId,
      transactionId: transactionId,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService().insertLoan(loan);
    return loan;
  }

  /// Creates a liability without affecting accounts (no money flows when creating liability record)
  Future<Liability> createLiability({
    required String personName,
    required double amount,
    required String currency,
    required DateTime dueDate,
    String? description,
    required bool isHistoricalEntry,
    String? accountId, // Account to use when settling
  }) async {
    final now = DateTime.now();
    final liabilityId = uuid.v4();

    final liability = Liability(
      id: liabilityId,
      personName: personName,
      amount: amount,
      currency: currency,
      dueDate: dueDate,
      isHistoricalEntry: isHistoricalEntry,
      accountId: accountId,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService().insertLiability(liability);
    return liability;
  }

  /// Settles a loan (marks as returned) and credits the account
  Future<Loan> settleLoan(Loan loan, {String? settleAccountId, DateTime? returnDate}) async {
    if (loan.isReturned) {
      throw Exception('Loan is already returned');
    }

    final accountId = settleAccountId ?? loan.accountId;
    final actualReturnDate = returnDate ?? DateTime.now();
    
    String? settleTransactionId;
    
    // For non-historical loans, create a transaction to credit the account
    if (!loan.isHistoricalEntry && accountId != null) {
      // Ensure account exists on server before creating transaction
      await _ensureAccountExists(accountId);
      
      // Create transaction to credit the account when loan is returned
      settleTransactionId = await _createLoanReturnedTransaction(
        accountId: accountId,
        amount: loan.amount,
        currency: loan.currency,
        date: actualReturnDate,
        description: 'Loan returned by ${loan.personName}',
        loanId: loan.id,
      );
    }

    final settledLoan = loan.copyWith(
      isReturned: true,
      returnDate: actualReturnDate,
      updatedAt: DateTime.now(),
      accountId: accountId,
      transactionId: settleTransactionId, // Update with settlement transaction
    );

    await DatabaseService().insertLoan(settledLoan);
    return settledLoan;
  }

  /// Settles a liability (marks as paid) and debits the account
  Future<Liability> settleLiability(Liability liability, {String? settleAccountId}) async {
    if (liability.isPaid) {
      throw Exception('Liability is already paid');
    }

    final accountId = settleAccountId ?? liability.accountId;
    if (accountId == null) {
      throw Exception('Account ID is required to settle liability');
    }

    String? settleTransactionId;
    
    // Ensure account exists on server before creating transaction
    await _ensureAccountExists(accountId);
    
    // Create transaction to debit the account when liability is paid
    settleTransactionId = await _createLiabilityPaidTransaction(
      accountId: accountId,
      amount: liability.amount,
      currency: liability.currency,
      date: DateTime.now(),
      description: 'Liability paid to ${liability.personName}',
      liabilityId: liability.id,
    );

    final settledLiability = liability.copyWith(
      isPaid: true,
      updatedAt: DateTime.now(),
      accountId: accountId,
      transactionId: settleTransactionId, // Update with settlement transaction
    );

    await DatabaseService().insertLiability(settledLiability);
    return settledLiability;
  }

  /// Creates a debit transaction when giving a loan
  Future<String> _createLoanGivenTransaction({
    required String accountId,
    required double amount,
    required String currency,
    required DateTime date,
    required String description,
    required String loanId,
  }) async {
    final transactionId = uuid.v4();
    final transaction = transaction_model.Transaction(
      id: transactionId,
      accountId: accountId,
      amount: amount,
      type: transaction_model.TransactionType.expense,
      category: 'Loan Given', // You might want to create a specific category
      description: description,
      date: date,
      currency: currency,
      createdAt: DateTime.now(),
    );

    await DatabaseService().insertTransaction(transaction);
    return transactionId;
  }

  /// Creates a credit transaction when loan is returned
  Future<String> _createLoanReturnedTransaction({
    required String accountId,
    required double amount,
    required String currency,
    required DateTime date,
    required String description,
    required String loanId,
  }) async {
    final transactionId = uuid.v4();
    final transaction = transaction_model.Transaction(
      id: transactionId,
      accountId: accountId,
      amount: amount,
      type: transaction_model.TransactionType.income,
      category: 'Loan Returned', // You might want to create a specific category
      description: description,
      date: date,
      currency: currency,
      createdAt: DateTime.now(),
    );

    await DatabaseService().insertTransaction(transaction);
    return transactionId;
  }

  /// Creates a debit transaction when paying a liability
  Future<String> _createLiabilityPaidTransaction({
    required String accountId,
    required double amount,
    required String currency,
    required DateTime date,
    required String description,
    required String liabilityId,
  }) async {
    final transactionId = uuid.v4();
    final transaction = transaction_model.Transaction(
      id: transactionId,
      accountId: accountId,
      amount: amount,
      type: transaction_model.TransactionType.expense,
      category: 'Liability Payment', // You might want to create a specific category
      description: description,
      date: date,
      currency: currency,
      createdAt: DateTime.now(),
    );

    await DatabaseService().insertTransaction(transaction);
    return transactionId;
  }

  /// Updates an existing loan without affecting transactions (for editing details)
  Future<Loan> updateLoan(Loan loan) async {
    final updatedLoan = loan.copyWith(updatedAt: DateTime.now());
    await DatabaseService().insertLoan(updatedLoan);
    return updatedLoan;
  }

  /// Updates an existing liability without affecting transactions (for editing details)
  Future<Liability> updateLiability(Liability liability) async {
    final updatedLiability = liability.copyWith(updatedAt: DateTime.now());
    await DatabaseService().insertLiability(updatedLiability);
    return updatedLiability;
  }
}