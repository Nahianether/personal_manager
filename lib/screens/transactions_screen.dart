import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/currency_utils.dart';
import '../widgets/category_selector.dart';
import 'recurring_transactions_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  // Filter state
  String _searchQuery = '';
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  String? _filterCategory;
  double? _filterAmountMin;
  double? _filterAmountMax;
  String? _filterAccountId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterDateFrom != null || _filterDateTo != null) count++;
    if (_filterCategory != null) count++;
    if (_filterAmountMin != null || _filterAmountMax != null) count++;
    if (_filterAccountId != null) count++;
    return count;
  }

  bool get _hasAnyFilter =>
      _searchQuery.isNotEmpty || _activeFilterCount > 0;

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filterDateFrom = null;
      _filterDateTo = null;
      _filterCategory = null;
      _filterAmountMin = null;
      _filterAmountMax = null;
      _filterAccountId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleMedium,
              )
            : const Text('Transactions'),
        centerTitle: !_isSearching,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterBottomSheet(context),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.repeat_rounded),
            tooltip: 'Recurring Transactions',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All'),
            Tab(icon: Icon(Icons.arrow_downward), text: 'Income'),
            Tab(icon: Icon(Icons.arrow_upward), text: 'Expense'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Active filter chips
          if (_hasAnyFilter) _buildFilterChips(),
          // Transaction list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(null),   // All
                _buildTransactionList(TransactionType.income),
                _buildTransactionList(TransactionType.expense),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildTabSpecificFAB(),
    );
  }

  Widget _buildFilterChips() {
    final dateFormatter = DateFormat('dd MMM');
    final currencyFormatter = CurrencyUtils.getFormatter(ref.watch(currencyProvider).displayCurrency);
    final accountState = ref.watch(accountProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_searchQuery.isNotEmpty)
            Chip(
              label: Text('"$_searchQuery"'),
              avatar: const Icon(Icons.search, size: 16),
              onDeleted: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
            ),
          if (_filterDateFrom != null || _filterDateTo != null)
            Chip(
              label: Text(
                _filterDateFrom != null && _filterDateTo != null
                    ? '${dateFormatter.format(_filterDateFrom!)} - ${dateFormatter.format(_filterDateTo!)}'
                    : _filterDateFrom != null
                        ? 'From ${dateFormatter.format(_filterDateFrom!)}'
                        : 'Until ${dateFormatter.format(_filterDateTo!)}',
              ),
              avatar: const Icon(Icons.date_range, size: 16),
              onDeleted: () => setState(() {
                _filterDateFrom = null;
                _filterDateTo = null;
              }),
            ),
          if (_filterCategory != null)
            Chip(
              label: Text(_filterCategory!),
              avatar: const Icon(Icons.category, size: 16),
              onDeleted: () => setState(() => _filterCategory = null),
            ),
          if (_filterAmountMin != null || _filterAmountMax != null)
            Chip(
              label: Text(
                _filterAmountMin != null && _filterAmountMax != null
                    ? '${currencyFormatter.format(_filterAmountMin)} - ${currencyFormatter.format(_filterAmountMax)}'
                    : _filterAmountMin != null
                        ? '>= ${currencyFormatter.format(_filterAmountMin)}'
                        : '<= ${currencyFormatter.format(_filterAmountMax)}',
              ),
              avatar: const Icon(Icons.attach_money, size: 16),
              onDeleted: () => setState(() {
                _filterAmountMin = null;
                _filterAmountMax = null;
              }),
            ),
          if (_filterAccountId != null)
            Chip(
              label: Text(
                accountState.accounts
                    .where((a) => a.id == _filterAccountId)
                    .map((a) => a.name)
                    .firstOrNull ?? 'Account',
              ),
              avatar: const Icon(Icons.account_balance_wallet, size: 16),
              onDeleted: () => setState(() => _filterAccountId = null),
            ),
          ActionChip(
            label: const Text('Clear All'),
            avatar: const Icon(Icons.clear_all, size: 16),
            onPressed: _clearAllFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSpecificFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final tabIndex = _tabController.index;
        final isIncomeTab = tabIndex == 1;
        final isAllTab = tabIndex == 0;
        return FloatingActionButton.extended(
          heroTag: "transactions_fab",
          onPressed: () {
            if (isIncomeTab || isAllTab) {
              _showAddIncomeDialog(context);
            } else {
              _showAddExpenseDialog(context);
            }
          },
          backgroundColor: (isIncomeTab || isAllTab) ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          icon: Icon((isIncomeTab || isAllTab) ? Icons.arrow_downward : Icons.arrow_upward),
          label: Text((isIncomeTab || isAllTab) ? 'Add Income' : 'Add Expense'),
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

  Widget _buildTransactionList(TransactionType? filterType) {
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

        final filteredTransactions = ref.read(transactionProvider.notifier).searchAndFilter(
          query: _searchQuery.isNotEmpty ? _searchQuery : null,
          dateFrom: _filterDateFrom,
          dateTo: _filterDateTo,
          category: _filterCategory,
          amountMin: _filterAmountMin,
          amountMax: _filterAmountMax,
          accountId: _filterAccountId,
          type: filterType,
        );

        final totalCount = filterType != null
            ? transactionState.transactions.where((t) => t.type == filterType).length
            : transactionState.transactions.length;

        if (filteredTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasAnyFilter ? Icons.search_off : Icons.receipt_long,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _hasAnyFilter
                      ? 'No transactions match your filters'
                      : filterType != null
                          ? 'No ${filterType.name} transactions found'
                          : 'No transactions found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _hasAnyFilter
                      ? 'Try adjusting your search or filters'
                      : 'Add a transaction to get started!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_hasAnyFilter) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            if (_hasAnyFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Showing ${filteredTransactions.length} of $totalCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = filteredTransactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          if (transaction.description != null && transaction.description!.isNotEmpty)
                            Text(transaction.description!),
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
                        ],
                      ),
                      trailing: Text(
                        '${transaction.type == TransactionType.expense ? '-' : '+'}${CurrencyUtils.formatCurrency(transaction.amount.abs(), transaction.currency)}',
                        style: TextStyle(
                          color: _getTransactionColor(transaction.type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        if (transaction.type != TransactionType.transfer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _TransactionEntryScreen(
                                transactionType: transaction.type,
                                existingTransaction: transaction,
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: () => _showDeleteTransactionDialog(context, transaction),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Temporary filter values for the bottom sheet
    DateTime? tempDateFrom = _filterDateFrom;
    DateTime? tempDateTo = _filterDateTo;
    String? tempCategory = _filterCategory;
    double? tempAmountMin = _filterAmountMin;
    double? tempAmountMax = _filterAmountMax;
    String? tempAccountId = _filterAccountId;

    final amountMinController = TextEditingController(
      text: _filterAmountMin?.toStringAsFixed(0) ?? '',
    );
    final amountMaxController = TextEditingController(
      text: _filterAmountMax?.toStringAsFixed(0) ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final accountState = ref.read(accountProvider);
            final allCategories = <String>{};
            for (final t in ref.read(transactionProvider).transactions) {
              if (t.category != null) allCategories.add(t.category!);
            }
            final sortedCategories = allCategories.toList()..sort();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date Range
                    Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              tempDateFrom != null
                                  ? DateFormat('dd MMM yyyy').format(tempDateFrom!)
                                  : 'From',
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: tempDateFrom ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setSheetState(() => tempDateFrom = date);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('-'),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              tempDateTo != null
                                  ? DateFormat('dd MMM yyyy').format(tempDateTo!)
                                  : 'To',
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: tempDateTo ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setSheetState(() => tempDateTo = date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Text('Category', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'All categories',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All categories')),
                        ...sortedCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                      ],
                      onChanged: (value) {
                        setSheetState(() => tempCategory = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Range
                    Text('Amount Range', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Min',
                              prefixText: '${CurrencyUtils.getSymbol(ref.read(currencyProvider).displayCurrency)} ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (v) {
                              tempAmountMin = double.tryParse(v);
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('-'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: amountMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Max',
                              prefixText: '${CurrencyUtils.getSymbol(ref.read(currencyProvider).displayCurrency)} ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (v) {
                              tempAmountMax = double.tryParse(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Account
                    Text('Account', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempAccountId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'All accounts',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All accounts')),
                        ...accountState.accounts.map((acc) => DropdownMenuItem(
                          value: acc.id,
                          child: Text(acc.name),
                        )),
                      ],
                      onChanged: (value) {
                        setSheetState(() => tempAccountId = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _filterDateFrom = null;
                                _filterDateTo = null;
                                _filterCategory = null;
                                _filterAmountMin = null;
                                _filterAmountMax = null;
                                _filterAccountId = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _filterDateFrom = tempDateFrom;
                                _filterDateTo = tempDateTo;
                                _filterCategory = tempCategory;
                                _filterAmountMin = tempAmountMin;
                                _filterAmountMax = tempAmountMax;
                                _filterAccountId = tempAccountId;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
  final Transaction? existingTransaction;

  const _TransactionEntryScreen({
    required this.transactionType,
    this.existingTransaction,
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

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTransaction!;
      _amountController.text = t.amount.abs().toStringAsFixed(
        t.amount.abs() == t.amount.abs().roundToDouble() ? 0 : 2,
      );
      _descriptionController.text = t.description ?? '';
      _selectedAccountId = t.accountId;
      _selectedDate = t.date;
      // _selectedCategory will be matched in build() after categories load
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final typeLabel = widget.transactionType == TransactionType.income ? 'Income' : 'Expense';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit $typeLabel' : 'Add $typeLabel'),
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
                          child: Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
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
                        prefixText: '${CurrencyUtils.getSymbol(accountState.accounts.where((a) => a.id == _selectedAccountId).firstOrNull?.currency ?? 'BDT')} ',
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
                icon: Icon(_isEditing ? Icons.check : (widget.transactionType == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward)),
                label: Text(_isEditing ? 'Save Changes' : 'Add ${widget.transactionType == TransactionType.income ? 'Income' : 'Expense'}'),
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
    final typeLabel = widget.transactionType == TransactionType.income ? 'Income' : 'Expense';

    if (_isEditing) {
      ref.read(transactionProvider.notifier).editTransaction(
        transactionId: widget.existingTransaction!.id,
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
          content: Text('$typeLabel updated successfully!'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
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
          content: Text('$typeLabel added successfully!'),
          backgroundColor: widget.transactionType == TransactionType.income ? Colors.green : Colors.red,
        ),
      );
    }
  }

}