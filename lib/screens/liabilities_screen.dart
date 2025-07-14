import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/liability_provider.dart';
import '../providers/account_provider.dart';
import '../models/liability.dart';
import '../models/account.dart';

class LiabilitiesScreen extends ConsumerStatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  ConsumerState<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends ConsumerState<LiabilitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liabilities'),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final liabilityState = ref.watch(liabilityProvider);
          
          if (liabilityState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (liabilityState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${liabilityState.error}'),
                  ElevatedButton(
                    onPressed: () => ref.read(liabilityProvider.notifier).loadLiabilities(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (liabilityState.liabilities.isEmpty) {
            return const Center(
              child: Text('No liabilities found. Add one to get started!'),
            );
          }

          return ListView.builder(
            itemCount: liabilityState.liabilities.length,
            itemBuilder: (context, index) {
              final liability = liabilityState.liabilities[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: liability.isPaid 
                        ? Colors.green 
                        : liability.isOverdue 
                            ? Colors.red 
                            : Colors.blue,
                    child: Icon(
                      liability.isPaid 
                          ? Icons.check_circle 
                          : liability.isOverdue 
                              ? Icons.warning 
                              : Icons.assignment,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('To: ${liability.personName}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(liability.isPaid ? 'PAID' : liability.isOverdue ? 'OVERDUE' : 'PENDING'),
                      Text('Due: ${DateFormat('dd/MM/yyyy').format(liability.dueDate)}'),
                      if (liability.isOverdue && !liability.isPaid)
                        Text(
                          'Overdue by ${liability.daysUntilDue.abs()} days',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormatter.format(liability.amount),
                          style: TextStyle(
                            color: liability.isPaid 
                                ? Colors.green 
                                : liability.isOverdue 
                                    ? Colors.red 
                                    : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _showDeleteLiabilityDialog(context, liability),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                            ),
                            if (!liability.isPaid)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                onPressed: () => _markAsPaid(context, liability),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "liabilities_fab",
        onPressed: () => _showAddLiabilityDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }


  void _markAsPaid(BuildContext context, Liability liability) {
    Account? selectedAccount;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mark Liability as Paid'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mark liability to "${liability.personName}" as paid?'),
                const SizedBox(height: 16),
                
                // Account Selection for debiting payment
                if (!liability.isHistoricalEntry) ...[ 
                  Consumer(
                    builder: (context, ref, child) {
                      final accountState = ref.watch(accountProvider);
                      final accounts = accountState.accounts;
                      
                      if (accounts.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No accounts available. Please create an account first.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        );
                      }
                      
                      return DropdownButtonFormField<Account>(
                        value: selectedAccount,
                        decoration: const InputDecoration(
                          labelText: 'Select Account to Debit',
                          border: OutlineInputBorder(),
                          helperText: 'Money will be deducted from this account',
                        ),
                        items: accounts.map((account) {
                          return DropdownMenuItem<Account>(
                            value: account,
                            child: Row(
                              children: [
                                Icon(
                                  _getAccountIcon(account.type),
                                  size: 20,
                                  color: _getAccountColor(account.type),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(account.name),
                                      Text(
                                        'Balance: ৳${account.balance.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Account? account) {
                          setState(() {
                            selectedAccount = account;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation for non-historical liabilities
                if (!liability.isHistoricalEntry && selectedAccount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an account to debit')),
                  );
                  return;
                }
                
                // Check sufficient balance for non-historical liabilities
                if (!liability.isHistoricalEntry && selectedAccount != null && selectedAccount!.balance < liability.amount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Insufficient balance. Available: ৳${selectedAccount!.balance.toStringAsFixed(2)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                ref.read(liabilityProvider.notifier).markAsPaid(
                  liability.id,
                  accountId: selectedAccount?.id,
                );
                Navigator.pop(context);
                
                final message = liability.isHistoricalEntry 
                  ? 'Historical liability marked as paid!'
                  : 'Liability paid and ৳${liability.amount.toStringAsFixed(2)} debited from ${selectedAccount!.name}';
                  
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              child: const Text('Mark as Paid'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLiabilityDialog(BuildContext context) {
    final personNameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));
    bool isHistoricalEntry = true; // Default to historical entry (no immediate account impact)
    Account? selectedAccount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Liability'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: personNameController,
                  decoration: const InputDecoration(
                    labelText: 'Person Name (Who you owe money to)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Liability Amount',
                    border: OutlineInputBorder(),
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Historical Entry Toggle
                SwitchListTile(
                  title: const Text('Historical Entry'),
                  subtitle: Text(
                    isHistoricalEntry 
                      ? 'Past liability record (no account impact)' 
                      : 'Current liability (will set payment account)'
                  ),
                  value: isHistoricalEntry,
                  onChanged: (value) {
                    setState(() {
                      isHistoricalEntry = value;
                      if (value) selectedAccount = null; // Clear account for historical
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Account Selection (for settlement when paid)
                Consumer(
                  builder: (context, ref, child) {
                    final accountState = ref.watch(accountProvider);
                    final accounts = accountState.accounts;
                    
                    if (accounts.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No accounts available. Please create an account first.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      );
                    }
                    
                    return DropdownButtonFormField<Account>(
                      value: selectedAccount,
                      decoration: const InputDecoration(
                        labelText: 'Payment Account (for settlement)',
                        border: OutlineInputBorder(),
                        helperText: 'Account to debit when liability is paid',
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem<Account>(
                          value: account,
                          child: Row(
                            children: [
                              Icon(
                                _getAccountIcon(account.type),
                                size: 20,
                                color: _getAccountColor(account.type),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(account.name),
                                    Text(
                                      'Balance: ৳${account.balance.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Account? account) {
                        setState(() {
                          selectedAccount = account;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDueDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDueDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final personName = personNameController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0.0;
                final description = descriptionController.text.trim();
                
                // Validation
                if (personName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter person name')),
                  );
                  return;
                }
                
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount')),
                  );
                  return;
                }
                
                ref.read(liabilityProvider.notifier).addLiability(
                  personName: personName,
                  amount: amount,
                  dueDate: selectedDueDate,
                  description: description.isNotEmpty ? description : null,
                  isHistoricalEntry: isHistoricalEntry,
                  accountId: selectedAccount?.id,
                );
                Navigator.pop(context);
                
                final message = isHistoricalEntry 
                  ? 'Historical liability record added successfully!'
                  : 'Liability added with payment account: ${selectedAccount?.name ?? 'None'}';
                  
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              child: const Text('Add Liability'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteLiabilityDialog(BuildContext context, Liability liability) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Liability'),
        content: Text('Are you sure you want to delete liability to "${liability.personName}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(liabilityProvider.notifier).deleteLiability(liability.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Liability to ${liability.personName} deleted successfully')),
              );
            },
            child: const Text('Delete'),
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