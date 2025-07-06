import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/liability.dart';
import '../services/database_service.dart';

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
        .where((liability) => liability.status == LiabilityStatus.pending)
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
            liability.status == LiabilityStatus.pending &&
            liability.dueDate.isAfter(now) &&
            liability.dueDate.isBefore(nextWeek))
        .toList();
  }
}

class LiabilityNotifier extends StateNotifier<LiabilityState> {
  final DatabaseService _databaseService = DatabaseService();

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
    required String name,
    required LiabilityType type,
    required double amount,
    required DateTime dueDate,
    String currency = 'BDT',
    String? description,
  }) async {
    try {
      final liability = Liability(
        id: const Uuid().v4(),
        name: name,
        type: type,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        status: LiabilityStatus.pending,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertLiability(liability);
      state = state.copyWith(
        liabilities: [...state.liabilities, liability],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAsPaid(String liabilityId) async {
    try {
      final liabilityIndex = state.liabilities.indexWhere((l) => l.id == liabilityId);
      if (liabilityIndex == -1) return;

      final liability = state.liabilities[liabilityIndex];
      final updatedLiability = liability.copyWith(
        status: LiabilityStatus.paid,
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

  Future<void> markAsOverdue(String liabilityId) async {
    try {
      final liabilityIndex = state.liabilities.indexWhere((l) => l.id == liabilityId);
      if (liabilityIndex == -1) return;

      final liability = state.liabilities[liabilityIndex];
      final updatedLiability = liability.copyWith(
        status: LiabilityStatus.overdue,
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
      final updatedLiability = liability.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _databaseService.insertLiability(updatedLiability);
      
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
        .where((liability) => liability.status == LiabilityStatus.pending)
        .toList();
  }

  List<Liability> getPaidLiabilities() {
    return state.liabilities
        .where((liability) => liability.status == LiabilityStatus.paid)
        .toList();
  }

  List<Liability> getLiabilitiesByType(LiabilityType type) {
    return state.liabilities.where((liability) => liability.type == type).toList();
  }

  void checkOverdueItems() {
    bool hasChanges = false;
    final updatedLiabilities = <Liability>[];
    
    for (final liability in state.liabilities) {
      if (liability.isOverdue && liability.status == LiabilityStatus.pending) {
        final updatedLiability = liability.copyWith(
          status: LiabilityStatus.overdue,
          updatedAt: DateTime.now(),
        );
        updatedLiabilities.add(updatedLiability);
        _databaseService.insertLiability(updatedLiability);
        hasChanges = true;
      } else {
        updatedLiabilities.add(liability);
      }
    }
    
    if (hasChanges) {
      state = state.copyWith(liabilities: updatedLiabilities);
    }
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