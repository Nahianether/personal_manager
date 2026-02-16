import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/liability_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/savings_goal.dart';
import '../utils/currency_utils.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search accounts, transactions, loans...',
            border: InputBorder.none,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
      ),
      body: _query.isEmpty ? _buildEmptyHint(context) : _buildResults(context),
    );
  }

  Widget _buildEmptyHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search across all your data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accounts, transactions, loans,\nliabilities, and savings goals',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final lowerQuery = _query.toLowerCase();

    final accounts = ref.watch(accountProvider).accounts.where((a) {
      return a.name.toLowerCase().contains(lowerQuery) ||
          _getAccountTypeLabel(a.type).toLowerCase().contains(lowerQuery);
    }).toList();

    final transactions = ref.watch(transactionProvider).transactions.where((t) {
      return (t.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (t.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    final loans = ref.watch(loanProvider).loans.where((l) {
      return l.personName.toLowerCase().contains(lowerQuery) ||
          (l.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    final liabilities = ref.watch(liabilityProvider).liabilities.where((l) {
      return l.personName.toLowerCase().contains(lowerQuery) ||
          (l.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    final goals = ref.watch(savingsGoalProvider).goals.where((g) {
      return g.name.toLowerCase().contains(lowerQuery) ||
          (g.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    final totalResults = accounts.length +
        transactions.length +
        loans.length +
        liabilities.length +
        goals.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (accounts.isNotEmpty) ...[
          _buildSectionHeader(context, 'Accounts', accounts.length, Icons.account_balance_wallet_rounded),
          ...accounts.map((a) => _buildAccountTile(context, a)),
        ],
        if (transactions.isNotEmpty) ...[
          _buildSectionHeader(context, 'Transactions', transactions.length, Icons.receipt_long_rounded),
          ...transactions.take(20).map((t) => _buildTransactionTile(context, t)),
          if (transactions.length > 20)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '+ ${transactions.length - 20} more transactions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
        if (loans.isNotEmpty) ...[
          _buildSectionHeader(context, 'Loans', loans.length, Icons.handshake_rounded),
          ...loans.map((l) => _buildLoanTile(context, l)),
        ],
        if (liabilities.isNotEmpty) ...[
          _buildSectionHeader(context, 'Liabilities', liabilities.length, Icons.assignment_rounded),
          ...liabilities.map((l) => _buildLiabilityTile(context, l)),
        ],
        if (goals.isNotEmpty) ...[
          _buildSectionHeader(context, 'Savings Goals', goals.length, Icons.savings_rounded),
          ...goals.map((g) => _buildGoalTile(context, g)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, Account account) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAccountColor(account.type).withValues(alpha: 0.15),
          child: Icon(
            _getAccountIcon(account.type),
            color: _getAccountColor(account.type),
            size: 20,
          ),
        ),
        title: Text(account.name),
        subtitle: Text(_getAccountTypeLabel(account.type)),
        trailing: Text(
          CurrencyUtils.formatCurrency(account.displayBalance, account.currency),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: account.displayBalance >= 0
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Transaction transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isExpense ? Colors.red : Colors.green).withValues(alpha: 0.15),
          child: Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: isExpense ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(transaction.category ?? 'Transaction'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null && transaction.description!.isNotEmpty)
              Text(
                transaction.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              DateFormat('dd MMM yyyy').format(transaction.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}${CurrencyUtils.formatCurrency(transaction.amount.abs(), transaction.currency)}',
          style: TextStyle(
            color: isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoanTile(BuildContext context, Loan loan) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          child: const Icon(Icons.handshake_rounded, color: Colors.orange, size: 20),
        ),
        title: Text(loan.personName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loan.description != null && loan.description!.isNotEmpty)
              Text(loan.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              loan.isReturned ? 'Returned' : 'Active',
              style: TextStyle(
                color: loan.isReturned ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          CurrencyUtils.formatCurrency(loan.amount, loan.currency),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
        ),
      ),
    );
  }

  Widget _buildLiabilityTile(BuildContext context, Liability liability) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          child: const Icon(Icons.assignment_rounded, color: Colors.red, size: 20),
        ),
        title: Text(liability.personName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (liability.description != null && liability.description!.isNotEmpty)
              Text(liability.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              liability.isPaid
                  ? 'Paid'
                  : liability.isOverdue
                      ? 'Overdue'
                      : 'Due ${DateFormat('dd MMM').format(liability.dueDate)}',
              style: TextStyle(
                color: liability.isPaid
                    ? Colors.green
                    : liability.isOverdue
                        ? Colors.red
                        : Colors.orange,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          CurrencyUtils.formatCurrency(liability.amount, liability.currency),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
        ),
      ),
    );
  }

  Widget _buildGoalTile(BuildContext context, SavingsGoal goal) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withValues(alpha: 0.15),
          child: const Icon(Icons.savings_rounded, color: Colors.teal, size: 20),
        ),
        title: Text(goal.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (goal.description != null && goal.description!.isNotEmpty)
              Text(goal.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progressPercentage,
                      minHeight: 4,
                      backgroundColor: Colors.teal.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          CurrencyUtils.formatCurrency(goal.targetAmount, goal.currency),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
        ),
      ),
    );
  }

  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.wallet:
        return 'Digital Wallet';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.mobileBanking:
        return 'Mobile Banking';
      case AccountType.cash:
        return 'Cash';
      case AccountType.investment:
        return 'Investment';
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.creditCard:
        return 'Credit Card';
    }
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.mobileBanking:
        return Icons.phone_android_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
      case AccountType.savings:
        return Icons.savings_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
    }
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.wallet:
        return Colors.blue;
      case AccountType.bank:
        return Colors.green;
      case AccountType.mobileBanking:
        return Colors.purple;
      case AccountType.cash:
        return Colors.orange;
      case AccountType.investment:
        return Colors.red;
      case AccountType.savings:
        return Colors.teal;
      case AccountType.creditCard:
        return Colors.deepOrange;
    }
  }
}
