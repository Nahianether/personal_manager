import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../services/database_service.dart';

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
        .where((loan) => loan.status == LoanStatus.active)
        .fold(0.0, (sum, loan) => sum + loan.remainingAmount);
  }

  double get totalPaidAmount {
    return loans.fold(0.0, (sum, loan) => sum + loan.paidAmount);
  }
}

class LoanNotifier extends StateNotifier<LoanState> {
  final DatabaseService _databaseService = DatabaseService();

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
    required String name,
    required LoanType type,
    required double principal,
    required double interestRate,
    required DateTime startDate,
    DateTime? endDate,
    String currency = 'BDT',
    String? description,
  }) async {
    try {
      final totalAmount = principal + (principal * interestRate / 100);
      
      final loan = Loan(
        id: const Uuid().v4(),
        name: name,
        type: type,
        principal: principal,
        interestRate: interestRate,
        remainingAmount: totalAmount,
        totalAmount: totalAmount,
        currency: currency,
        startDate: startDate,
        endDate: endDate,
        status: LoanStatus.active,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertLoan(loan);
      state = state.copyWith(
        loans: [...state.loans, loan],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> makePayment(String loanId, double amount) async {
    try {
      final loanIndex = state.loans.indexWhere((loan) => loan.id == loanId);
      if (loanIndex == -1) return;

      final loan = state.loans[loanIndex];
      final newRemainingAmount = loan.remainingAmount - amount;
      
      final updatedLoan = loan.copyWith(
        remainingAmount: newRemainingAmount > 0 ? newRemainingAmount : 0,
        status: newRemainingAmount <= 0 ? LoanStatus.completed : LoanStatus.active,
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertLoan(updatedLoan);
      
      final updatedLoans = state.loans.map((l) {
        return l.id == loanId ? updatedLoan : l;
      }).toList();
      
      state = state.copyWith(loans: updatedLoans, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLoan(Loan loan) async {
    try {
      final updatedLoan = loan.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _databaseService.insertLoan(updatedLoan);
      
      final updatedLoans = state.loans.map((l) {
        return l.id == loan.id ? updatedLoan : l;
      }).toList();
      
      state = state.copyWith(loans: updatedLoans, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Loan> getActiveLoans() {
    return state.loans.where((loan) => loan.status == LoanStatus.active).toList();
  }

  List<Loan> getCompletedLoans() {
    return state.loans.where((loan) => loan.status == LoanStatus.completed).toList();
  }

  List<Loan> getLoansByType(LoanType type) {
    return state.loans.where((loan) => loan.type == type).toList();
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