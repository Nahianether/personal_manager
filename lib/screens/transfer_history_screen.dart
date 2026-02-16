import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../utils/currency_utils.dart';

class _TransferRecord {
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? description;
  final DateTime date;

  _TransferRecord({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.description,
    required this.date,
  });
}

class TransferHistoryScreen extends ConsumerStatefulWidget {
  final String? accountId;
  final String? accountName;

  const TransferHistoryScreen({
    super.key,
    this.accountId,
    this.accountName,
  });

  @override
  ConsumerState<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends ConsumerState<TransferHistoryScreen> {
  String? _filterAccountId;

  @override
  void initState() {
    super.initState();
    _filterAccountId = widget.accountId;
  }

  List<_TransferRecord> _buildTransferRecords(List<Transaction> allTransactions) {
    // Get all transfer transactions
    final transfers = allTransactions
        .where((t) => t.type == TransactionType.transfer)
        .toList();

    // Separate outgoing (negative amount, "Transfer Out") and incoming (positive, "Transfer In")
    final outgoing = transfers.where((t) => t.amount < 0).toList();
    final incoming = transfers.where((t) => t.amount > 0).toList();

    final matched = <String>{};
    final records = <_TransferRecord>[];

    for (final out in outgoing) {
      // Find matching incoming transaction
      Transaction? match;
      for (final inc in incoming) {
        if (matched.contains(inc.id)) continue;
        if (inc.date.toIso8601String() == out.date.toIso8601String() &&
            (inc.amount - out.amount.abs()).abs() < 0.01 &&
            inc.description == out.description) {
          match = inc;
          break;
        }
      }

      if (match != null) {
        matched.add(match.id);
        matched.add(out.id);
        records.add(_TransferRecord(
          fromAccountId: out.accountId,
          toAccountId: match.accountId,
          amount: match.amount,
          description: out.description,
          date: out.date,
        ));
      } else {
        // Unmatched outgoing transfer — show as standalone
        records.add(_TransferRecord(
          fromAccountId: out.accountId,
          toAccountId: '',
          amount: out.amount.abs(),
          description: out.description,
          date: out.date,
        ));
      }
    }

    // Check for unmatched incoming transfers
    for (final inc in incoming) {
      if (matched.contains(inc.id)) continue;
      records.add(_TransferRecord(
        fromAccountId: '',
        toAccountId: inc.accountId,
        amount: inc.amount,
        description: inc.description,
        date: inc.date,
      ));
    }

    // Sort by date descending (most recent first)
    records.sort((a, b) => b.date.compareTo(a.date));

    // Filter by account if specified
    if (_filterAccountId != null && _filterAccountId!.isNotEmpty) {
      return records
          .where((r) =>
              r.fromAccountId == _filterAccountId ||
              r.toAccountId == _filterAccountId)
          .toList();
    }

    return records;
  }

  String _getAccountName(String accountId) {
    if (accountId.isEmpty) return 'Unknown';
    final accounts = ref.read(accountProvider).accounts;
    final account = accounts.where((a) => a.id == accountId).firstOrNull;
    return account?.name ?? 'Deleted Account';
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final accountState = ref.watch(accountProvider);
    final records = _buildTransferRecords(transactionState.transactions);
    final dateFormat = DateFormat('MMM d, yyyy');

    final hasPreselectedAccount = widget.accountId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          hasPreselectedAccount
              ? 'Transfers: ${widget.accountName}'
              : 'Transfer History',
        ),
      ),
      body: Column(
        children: [
          // Account filter dropdown — only when no pre-selected account
          if (!hasPreselectedAccount)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DropdownButtonFormField<String>(
                value: _filterAccountId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Filter by Account',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Accounts'),
                  ),
                  ...accountState.accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _filterAccountId = value);
                },
              ),
            ),

          // Transfer list
          Expanded(
            child: records.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final fromAcct = accountState.accounts
                          .where((a) => a.id == record.fromAccountId)
                          .firstOrNull;
                      final currencyFormatter = CurrencyUtils.getFormatter(
                          fromAcct?.currency ?? 'BDT');
                      return _buildTransferCard(
                        context,
                        record,
                        currencyFormatter,
                        dateFormat,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No transfers found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterAccountId != null
                ? 'No transfers for this account'
                : 'Transfer money between accounts\nto see history here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(
    BuildContext context,
    _TransferRecord record,
    NumberFormat formatter,
    DateFormat dateFormat,
  ) {
    final fromName = _getAccountName(record.fromAccountId);
    final toName = _getAccountName(record.toAccountId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fromName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        toName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(record.amount),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.description != null && record.description!.isNotEmpty
                      ? '${dateFormat.format(record.date)}  \u2022  ${record.description}'
                      : dateFormat.format(record.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
