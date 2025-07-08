import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../widgets/category_selector.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.arrow_downward),
              text: 'Income',
            ),
            Tab(
              icon: Icon(Icons.arrow_upward),
              text: 'Expense',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList(TransactionType.income, currencyFormatter),
          _buildTransactionList(TransactionType.expense, currencyFormatter),
        ],
      ),
      floatingActionButton: _buildTabSpecificFAB(),
    );
  }

  Widget _buildTabSpecificFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isIncomeTab = _tabController.index == 0;
        return FloatingActionButton.extended(
          heroTag: "transactions_fab",
          onPressed: () {
            if (isIncomeTab) {
              _showAddIncomeDialog(context);
            } else {
              _showAddExpenseDialog(context);
            }
          },
          backgroundColor: isIncomeTab ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          icon: Icon(isIncomeTab ? Icons.arrow_downward : Icons.arrow_upward),
          label: Text(isIncomeTab ? 'Add Income' : 'Add Expense'),
        );
      },
    );
  }

  void _showAddIncomeDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _TransactionEntryScreen(
          transactionType: TransactionType.income,
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _TransactionEntryScreen(
          transactionType: TransactionType.expense,
        ),
      ),
    );
  }

  Widget _buildTransactionList(TransactionType filterType, NumberFormat currencyFormatter) {
    return Consumer(
      builder: (context, ref, child) {
        final transactionState = ref.watch(transactionProvider);
        
        if (transactionState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${transactionState.error}'),
                ElevatedButton(
                  onPressed: () => ref.read(transactionProvider.notifier).loadAllTransactions(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter transactions by type
        final filteredTransactions = transactionState.transactions
            .where((transaction) => transaction.type == filterType)
            .toList();

        if (filteredTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterType == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${filterType.name} transactions found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a transaction to get started!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final transaction = filteredTransactions[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getTransactionColor(transaction.type),
                  child: Icon(
                    _getTransactionIcon(transaction.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(transaction.category ?? 'Transaction'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (transaction.description != null)
                      Text(transaction.description!),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
                  ],
                ),
                trailing: Text(
                  '${transaction.type == TransactionType.expense ? '-' : '+'}${currencyFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    color: _getTransactionColor(transaction.type),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onLongPress: () => _showDeleteTransactionDialog(context, transaction),
              ),
            );
          },
        );
      },
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }


  void _showDeleteTransactionDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?\n\nThis will adjust the account balance accordingly. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(transactionProvider.notifier).deleteTransaction(transaction.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TransactionEntryScreen extends ConsumerStatefulWidget {
  final TransactionType transactionType;

  const _TransactionEntryScreen({
    required this.transactionType,
  });

  @override
  ConsumerState<_TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<_TransactionEntryScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedAccountId;
  Category? _selectedCategory;
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.transactionType == TransactionType.income ? 'Income' : 'Expense'}'),
        backgroundColor: widget.transactionType == TransactionType.income ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Account',
                      ),
                      items: accountState.accounts.map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: Row(
                            children: [
                              Icon(
                                _getAccountIcon(account.type),
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(account.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = value;
                        });
                      },
                    ),
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
                      'Amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: widget.transactionType == TransactionType.income ? 'Income Amount' : 'Expense Amount',
                        prefixText: '৳ ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CategorySelector(
                  categoryType: widget.transactionType == TransactionType.income 
                      ? CategoryType.income 
                      : CategoryType.expense,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
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
                        labelText: 'Description',
                        hintText: 'Enter a description...',
                      ),
                      maxLines: 3,
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
                      'Date',
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

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSubmit() ? _submitTransaction : null,
                icon: Icon(widget.transactionType == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward),
                label: Text('Add ${widget.transactionType == TransactionType.income ? 'Income' : 'Expense'}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.transactionType == TransactionType.income ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _selectedAccountId != null && 
           _amountController.text.isNotEmpty && 
           double.tryParse(_amountController.text) != null &&
           double.parse(_amountController.text) > 0;
  }

  void _submitTransaction() {
    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();
    
    ref.read(transactionProvider.notifier).addTransaction(
      accountId: _selectedAccountId!,
      type: widget.transactionType,
      amount: amount,
      category: _selectedCategory?.name,
      description: description.isNotEmpty ? description : null,
      date: _selectedDate,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.transactionType == TransactionType.income ? 'Income' : 'Expense'} added successfully!'),
        backgroundColor: widget.transactionType == TransactionType.income ? Colors.green : Colors.red,
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