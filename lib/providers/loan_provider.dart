import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../services/database_service.dart';
import '../services/loan_liability_transaction_service.dart';

class LoanState {
  final List<Loan> loans;
  final bool isLoading;
  final String? error;

  LoanState({
    required this.loans,
    required this.isLoading,
    this.error,
  });

  LoanState copyWith({
    List<Loan>? loans,
    bool? isLoading,
    String? error,
  }) {
    return LoanState(
      loans: loans ?? this.loans,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  double get totalLoanAmount {
    return loans
        .where((loan) => !loan.isReturned)
        .fold(0.0, (sum, loan) => sum + loan.amount);
  }

  double get totalReturnedAmount {
    return loans
        .where((loan) => loan.isReturned)
        .fold(0.0, (sum, loan) => sum + loan.amount);
  }
}

class LoanNotifier extends StateNotifier<LoanState> {
  final DatabaseService _databaseService = DatabaseService();
  final LoanLiabilityTransactionService _transactionService = LoanLiabilityTransactionService();

  LoanNotifier() : super(LoanState(loans: [], isLoading: false));

  Future<void> loadLoans() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final loans = await _databaseService.getAllLoans();
      state = state.copyWith(loans: loans, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addLoan({
    required String personName,
    required double amount,
    required DateTime loanDate,
    DateTime? returnDate,
    String currency = 'BDT',
    String? description,
    required bool isHistoricalEntry,
    String? accountId, // Required for non-historical entries
  }) async {
    try {
      final loan = await _transactionService.createLoan(
        personName: personName,
        amount: amount,
        currency: currency,
        loanDate: loanDate,
        description: description,
        isHistoricalEntry: isHistoricalEntry,
        accountId: accountId,
      );

      state = state.copyWith(
        loans: [...state.loans, loan],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markLoanAsReturned(String loanId, {DateTime? returnDate, String? accountId}) async {
    try {
      final loanIndex = state.loans.indexWhere((loan) => loan.id == loanId);
      if (loanIndex == -1) return;

      final loan = state.loans[loanIndex];
      
      final settledLoan = await _transactionService.settleLoan(
        loan,
        returnDate: returnDate,
        settleAccountId: accountId,
      );
      
      final updatedLoans = state.loans.map((l) {
        return l.id == loanId ? settledLoan : l;
      }).toList();
      
      state = state.copyWith(loans: updatedLoans, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLoan(Loan loan) async {
    try {
      final updatedLoan = await _transactionService.updateLoan(loan);
      
      final updatedLoans = state.loans.map((l) {
        return l.id == loan.id ? updatedLoan : l;
      }).toList();
      
      state = state.copyWith(loans: updatedLoans, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Loan> getActiveLoans() {
    return state.loans.where((loan) => !loan.isReturned).toList();
  }

  List<Loan> getReturnedLoans() {
    return state.loans.where((loan) => loan.isReturned).toList();
  }

  List<Loan> getAllLoansGiven() {
    // Since we simplified the model, all loans are given by the user to other people
    return state.loans;
  }

  Future<void> deleteLoan(String loanId) async {
    try {
      await _databaseService.deleteLoan(loanId);
      final updatedLoans = state.loans
          .where((loan) => loan.id != loanId)
          .toList();
      state = state.copyWith(loans: updatedLoans, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final loanProvider = StateNotifierProvider<LoanNotifier, LoanState>((ref) {
  return LoanNotifier();
});