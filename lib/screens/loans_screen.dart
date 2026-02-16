import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../utils/currency_utils.dart';
import '../providers/account_provider.dart';
import '../models/loan.dart';
import '../models/account.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final loanState = ref.watch(loanProvider);
          
          if (loanState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loanState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${loanState.error}'),
                  ElevatedButton(
                    onPressed: () => ref.read(loanProvider.notifier).loadLoans(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (loanState.loans.isEmpty) {
            return const Center(
              child: Text('No loans found. Add one to get started!'),
            );
          }

          return ListView.builder(
            itemCount: loanState.loans.length,
            itemBuilder: (context, index) {
              final loan = loanState.loans[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: loan.isReturned ? Colors.green : Colors.orange,
                    child: Icon(
                      loan.isReturned ? Icons.check_circle : Icons.trending_up,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('Loan to ${loan.personName}'),
                  subtitle: Text(
                    loan.isReturned ? 'RETURNED' : 'OUTSTANDING',
                  ),
                  trailing: Text(
                    CurrencyUtils.formatCurrency(loan.amount, loan.currency),
                    style: TextStyle(
                      color: loan.isReturned ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Amount: ${CurrencyUtils.formatCurrency(loan.amount, loan.currency)}'),
                              Text('Loan Date: ${DateFormat('dd/MM/yyyy').format(loan.loanDate)}'),
                            ],
                          ),
                          if (loan.returnDate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Return Date: ${DateFormat('dd/MM/yyyy').format(loan.returnDate!)}'),
                                Text(
                                  'Status: ${loan.isReturned ? 'RETURNED' : 'OUTSTANDING'}',
                                  style: TextStyle(
                                    color: loan.isReturned ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (loan.description != null && loan.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Description: ${loan.description}'),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showDeleteLoanDialog(context, loan),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                              if (!loan.isReturned) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _showMarkReturnedDialog(context, loan),
                                  child: const Text('Mark Returned'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "loans_fab",
        onPressed: () => _showAddLoanDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteLoanDialog(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Text('Are you sure you want to delete loan to "${loan.personName}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(loanProvider.notifier).deleteLoan(loan.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMarkReturnedDialog(BuildContext context, Loan loan) {
    DateTime returnDate = DateTime.now();
    Account? selectedAccount;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mark Loan as Returned'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mark loan to "${loan.personName}" as returned?'),
                const SizedBox(height: 16),
                
                // Account Selection for receiving money back
                if (!loan.isHistoricalEntry) ...[ 
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
                          labelText: 'Select Account to Credit',
                          border: OutlineInputBorder(),
                          helperText: 'Money will be added to this account',
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
                                        'Balance: ${CurrencyUtils.formatCurrency(account.balance, account.currency)}',
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

                ListTile(
                  title: const Text('Return Date'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(returnDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: returnDate,
                      firstDate: loan.loanDate,
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        returnDate = date;
                      });
                    }
                  },
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
                // Validation for non-historical loans
                if (!loan.isHistoricalEntry && selectedAccount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an account to credit')),
                  );
                  return;
                }
                
                ref.read(loanProvider.notifier).markLoanAsReturned(
                  loan.id, 
                  returnDate: returnDate,
                  accountId: selectedAccount?.id,
                );
                Navigator.pop(context);
                
                final message = loan.isHistoricalEntry 
                  ? 'Historical loan marked as returned!'
                  : 'Loan returned and ${CurrencyUtils.formatCurrency(loan.amount, loan.currency)} credited to ${selectedAccount!.name}';
                  
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              child: const Text('Mark Returned'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context) {
    final personNameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedLoanDate = DateTime.now();
    bool isHistoricalEntry = false; // Default to new loan (debit account)
    Account? selectedAccount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: personNameController,
                  decoration: const InputDecoration(
                    labelText: 'Person Name (Who you gave money to)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Loan Amount',
                    border: const OutlineInputBorder(),
                    prefixText: '${CurrencyUtils.getSymbol(selectedAccount?.currency ?? 'BDT')} ',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Historical Entry Toggle
                SwitchListTile(
                  title: const Text('Historical Entry'),
                  subtitle: Text(
                    isHistoricalEntry 
                      ? 'Past loan entry (no account debit)'
                      : 'New loan (will debit selected account)'
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
                
                // Account Selection (only for new loans)
                if (!isHistoricalEntry) ...[
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
                                        'Balance: ${CurrencyUtils.formatCurrency(account.balance, account.currency)}',
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
                        validator: (value) {
                          if (!isHistoricalEntry && value == null) {
                            return 'Please select an account';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                ListTile(
                  title: const Text('Loan Date'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedLoanDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedLoanDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedLoanDate = date;
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
                
                if (!isHistoricalEntry && selectedAccount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an account')),
                  );
                  return;
                }
                
                // Check sufficient balance for new loans
                if (!isHistoricalEntry && selectedAccount != null && selectedAccount!.balance < amount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Insufficient balance. Available: ${CurrencyUtils.formatCurrency(selectedAccount!.balance, selectedAccount!.currency)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                ref.read(loanProvider.notifier).addLoan(
                      personName: personName,
                      amount: amount,
                      loanDate: selectedLoanDate,
                      description: description.isNotEmpty ? description : null,
                      isHistoricalEntry: isHistoricalEntry,
                      accountId: selectedAccount?.id,
                    );
                Navigator.pop(context);
                
                final message = isHistoricalEntry 
                  ? 'Historical loan entry added successfully!'
                  : 'Loan created and ${CurrencyUtils.formatCurrency(amount, selectedAccount!.currency)} debited from ${selectedAccount!.name}';
                  
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              child: const Text('Add Loan'),
            ),
          ],
        ),
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