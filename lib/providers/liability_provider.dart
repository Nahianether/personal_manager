import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/liability.dart';
import '../services/database_service.dart';
import '../services/loan_liability_transaction_service.dart';

class LiabilityState {
  final List<Liability> liabilities;
  final bool isLoading;
  final String? error;

  LiabilityState({
    required this.liabilities,
    required this.isLoading,
    this.error,
  });

  LiabilityState copyWith({
    List<Liability>? liabilities,
    bool? isLoading,
    String? error,
  }) {
    return LiabilityState(
      liabilities: liabilities ?? this.liabilities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  double get totalLiabilityAmount {
    return liabilities
        .where((liability) => !liability.isPaid)
        .fold(0.0, (sum, liability) => sum + liability.amount);
  }

  List<Liability> get overdueItems {
    return liabilities
        .where((liability) => liability.isOverdue)
        .toList();
  }

  List<Liability> get upcomingItems {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    return liabilities
        .where((liability) => 
            !liability.isPaid &&
            liability.dueDate.isAfter(now) &&
            liability.dueDate.isBefore(nextWeek))
        .toList();
  }
}

class LiabilityNotifier extends StateNotifier<LiabilityState> {
  final DatabaseService _databaseService = DatabaseService();
  final LoanLiabilityTransactionService _transactionService = LoanLiabilityTransactionService();

  LiabilityNotifier() : super(LiabilityState(liabilities: [], isLoading: false));

  Future<void> loadLiabilities() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final liabilities = await _databaseService.getAllLiabilities();
      state = state.copyWith(liabilities: liabilities, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addLiability({
    required String personName,
    required double amount,
    required DateTime dueDate,
    String currency = 'BDT',
    String? description,
    required bool isHistoricalEntry,
    String? accountId, // Account to use when settling
  }) async {
    try {
      final liability = await _transactionService.createLiability(
        personName: personName,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        description: description,
        isHistoricalEntry: isHistoricalEntry,
        accountId: accountId,
      );

      state = state.copyWith(
        liabilities: [...state.liabilities, liability],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAsPaid(String liabilityId, {String? accountId}) async {
    try {
      final liabilityIndex = state.liabilities.indexWhere((l) => l.id == liabilityId);
      if (liabilityIndex == -1) return;

      final liability = state.liabilities[liabilityIndex];
      
      final settledLiability = await _transactionService.settleLiability(
        liability,
        settleAccountId: accountId,
      );
      
      final updatedLiabilities = state.liabilities.map((l) {
        return l.id == liabilityId ? settledLiability : l;
      }).toList();
      
      state = state.copyWith(liabilities: updatedLiabilities, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAsUnpaid(String liabilityId) async {
    try {
      final liabilityIndex = state.liabilities.indexWhere((l) => l.id == liabilityId);
      if (liabilityIndex == -1) return;

      final liability = state.liabilities[liabilityIndex];
      final updatedLiability = liability.copyWith(
        isPaid: false,
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertLiability(updatedLiability);
      
      final updatedLiabilities = state.liabilities.map((l) {
        return l.id == liabilityId ? updatedLiability : l;
      }).toList();
      
      state = state.copyWith(liabilities: updatedLiabilities, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLiability(Liability liability) async {
    try {
      final updatedLiability = await _transactionService.updateLiability(liability);
      
      final updatedLiabilities = state.liabilities.map((l) {
        return l.id == liability.id ? updatedLiability : l;
      }).toList();
      
      state = state.copyWith(liabilities: updatedLiabilities, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Liability> getPendingLiabilities() {
    return state.liabilities
        .where((liability) => !liability.isPaid)
        .toList();
  }

  List<Liability> getPaidLiabilities() {
    return state.liabilities
        .where((liability) => liability.isPaid)
        .toList();
  }

  void checkOverdueItems() {
    // This method can be used to check for overdue items
    // The isOverdue getter in the Liability model handles the logic
    // No need to update status since we simplified to just isPaid/not paid
  }

  Future<void> deleteLiability(String liabilityId) async {
    try {
      await _databaseService.deleteLiability(liabilityId);
      final updatedLiabilities = state.liabilities
          .where((liability) => liability.id != liabilityId)
          .toList();
      state = state.copyWith(liabilities: updatedLiabilities, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final liabilityProvider = StateNotifierProvider<LiabilityNotifier, LiabilityState>((ref) {
  return LiabilityNotifier();
});