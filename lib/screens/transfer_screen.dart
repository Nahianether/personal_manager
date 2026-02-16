import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';
import 'transfer_history_screen.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Transfer History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransferHistoryScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transfer Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue,
                    Colors.blue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Transfer Between Accounts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Move money from one account to another',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // From Account Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _fromAccountId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Select source account',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        suffixIcon: _fromAccountId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _fromAccountId = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      items: accountState.accounts.map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: _buildAccountDropdownItem(account, currencyFormatter),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fromAccountId = value;
                          // Clear to account if it's the same as from account
                          if (_toAccountId == value) {
                            _toAccountId = null;
                          }
                        });
                      },
                    ),
                    if (_fromAccountId != null) ...[
                      const SizedBox(height: 8),
                      _buildAccountBalance(_fromAccountId!, accountState.accounts, currencyFormatter),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transfer Direction Indicator
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // To Account Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _toAccountId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Select destination account',
                        prefixIcon: const Icon(Icons.account_balance),
                        suffixIcon: _toAccountId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _toAccountId = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      items: accountState.accounts
                          .where((account) => account.id != _fromAccountId)
                          .map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: _buildAccountDropdownItem(account, currencyFormatter),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _toAccountId = value;
                        });
                      },
                    ),
                    if (_toAccountId != null) ...[
                      const SizedBox(height: 8),
                      _buildAccountBalance(_toAccountId!, accountState.accounts, currencyFormatter),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer Amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Amount to transfer',
                        prefixText: '৳ ',
                        prefixIcon: Icon(Icons.currency_exchange),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild to update validation
                      },
                    ),
                    if (_fromAccountId != null && _amountController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildTransferValidation(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Transfer description',
                        hintText: 'e.g., Savings transfer, Emergency fund...',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      subtitle: Text(DateFormat('EEEE').format(_selectedDate)),
                      trailing: const Icon(Icons.keyboard_arrow_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Transfer Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSubmit() ? _submitTransfer : null,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Transfer Money'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdownItem(Account account, NumberFormat currencyFormatter) {
    return Row(
      children: [
        Icon(
          _getAccountIcon(account.type),
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${account.type.toString().split('.').last.toUpperCase()} • ${currencyFormatter.format(account.balance)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountBalance(String accountId, List<Account> accounts, NumberFormat currencyFormatter) {
    final account = accounts.firstWhere((a) => a.id == accountId);
    final availableAmount = account.isCreditCard && account.creditLimit != null ? account.availableCredit : account.balance;
    final isLowBalance = availableAmount < 1000; // You can adjust this threshold

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLowBalance 
            ? Colors.orange.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowBalance ? Colors.orange : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLowBalance ? Icons.warning : Icons.check_circle,
            color: isLowBalance ? Colors.orange : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Available: ${currencyFormatter.format(availableAmount)}',
            style: TextStyle(
              color: isLowBalance ? Colors.orange : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferValidation() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      return _buildValidationMessage(
        'Please enter a valid amount',
        Icons.error,
        Colors.red,
      );
    }

    final fromAccount = ref.read(accountProvider).accounts.firstWhere((a) => a.id == _fromAccountId);
    
    if (amount > fromAccount.balance) {
      return _buildValidationMessage(
        'Insufficient balance in source account',
        Icons.error,
        Colors.red,
      );
    }

    return _buildValidationMessage(
      'Transfer amount is valid',
      Icons.check_circle,
      Colors.green,
    );
  }

  Widget _buildValidationMessage(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    if (_fromAccountId == null || _toAccountId == null) return false;
    if (_amountController.text.isEmpty) return false;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return false;

    final fromAccount = ref.read(accountProvider).accounts.firstWhere((a) => a.id == _fromAccountId);
    if (amount > fromAccount.balance) return false;

    return true;
  }

  void _submitTransfer() {
    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();
    final fromAccount = ref.read(accountProvider).accounts.firstWhere((a) => a.id == _fromAccountId);
    final toAccount = ref.read(accountProvider).accounts.firstWhere((a) => a.id == _toAccountId);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer ${NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(amount)}'),
            const SizedBox(height: 8),
            Text('From: ${fromAccount.name}'),
            Text('To: ${toAccount.name}'),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Description: $description'),
            ],
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Execute the transfer
              ref.read(transactionProvider.notifier).addTransfer(
                fromAccountId: _fromAccountId!,
                toAccountId: _toAccountId!,
                amount: amount,
                description: description.isNotEmpty ? description : null,
                date: _selectedDate,
              );

              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close transfer screen
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transfer of ${NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(amount)} completed successfully!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirm Transfer'),
          ),
        ],
      ),
    );
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
}