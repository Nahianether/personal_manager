import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AccountState {
  final List<Account> accounts;
  final bool isLoading;
  final String? error;

  AccountState({
    required this.accounts,
    required this.isLoading,
    this.error,
  });

  AccountState copyWith({
    List<Account>? accounts,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  double get totalBalance {
    return accounts.fold(0.0, (sum, account) {
      if (account.isCreditCard) {
        // For credit cards, subtract the debt (negative contribution to net worth)
        return sum - account.balance;
      } else {
        // For regular accounts, add the balance
        return sum + account.balance;
      }
    });
  }
}

class AccountNotifier extends StateNotifier<AccountState> {
  final DatabaseService _databaseService = DatabaseService();

  AccountNotifier() : super(AccountState(accounts: [], isLoading: false));

  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final accounts = await _databaseService.getAllAccounts();
      
      // Create default wallet if no accounts exist
      if (accounts.isEmpty) {
        await _createDefaultWallet();
        final updatedAccounts = await _databaseService.getAllAccounts();
        state = state.copyWith(accounts: updatedAccounts, isLoading: false);
      } else {
        state = state.copyWith(accounts: accounts, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> _createDefaultWallet() async {
    final defaultWallet = Account(
      id: const Uuid().v4(),
      name: 'Wallet',
      type: AccountType.wallet,
      balance: 0.0,
      currency: 'BDT',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _databaseService.insertAccount(defaultWallet);
  }

  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    String currency = 'BDT',
    double? creditLimit, // For credit cards
  }) async {
    try {
      final account = Account(
        id: const Uuid().v4(),
        name: name,
        type: type,
        balance: initialBalance,
        currency: currency,
        creditLimit: creditLimit,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertAccount(account);
      state = state.copyWith(
        accounts: [...state.accounts, account],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      final updatedAccount = account.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _databaseService.updateAccount(updatedAccount);
      
      final updatedAccounts = state.accounts.map((a) {
        return a.id == account.id ? updatedAccount : a;
      }).toList();
      
      state = state.copyWith(accounts: updatedAccounts, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _databaseService.deleteAccount(accountId);
      final updatedAccounts = state.accounts
          .where((account) => account.id != accountId)
          .toList();
      state = state.copyWith(accounts: updatedAccounts, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      await _databaseService.updateAccountBalance(accountId, newBalance);
      
      final updatedAccounts = state.accounts.map((account) {
        if (account.id == accountId) {
          return account.copyWith(
            balance: newBalance,
            updatedAt: DateTime.now(),
          );
        }
        return account;
      }).toList();
      
      state = state.copyWith(accounts: updatedAccounts, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Account? getAccountById(String accountId) {
    try {
      return state.accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  List<Account> getAccountsByType(AccountType type) {
    return state.accounts.where((account) => account.type == type).toList();
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier();
});