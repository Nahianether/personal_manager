import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../providers/recurring_transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../utils/currency_utils.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rtState = ref.watch(recurringTransactionProvider);
    final accountState = ref.watch(accountProvider);
    final goalState = ref.watch(savingsGoalProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
      ),
      body: rtState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rtState.items.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rtState.items.length,
                  itemBuilder: (context, index) {
                    final rt = rtState.items[index];
                    final account = accountState.accounts
                        .where((a) => a.id == rt.accountId)
                        .firstOrNull;
                    final linkedGoal = rt.savingsGoalId != null
                        ? goalState.goals
                            .where((g) => g.id == rt.savingsGoalId)
                            .firstOrNull
                        : null;
                    return _buildRecurringCard(
                      context,
                      ref,
                      rt,
                      account?.name ?? 'Unknown',
                      CurrencyUtils.getFormatter(rt.currency),
                      linkedGoalName: linkedGoal?.name,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecurringForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No recurring transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up automatic transactions for\nsalary, rent, subscriptions, etc.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringCard(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction rt,
    String accountName,
    NumberFormat formatter, {
    String? linkedGoalName,
  }) {
    final isIncome = rt.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Dismissible(
      key: Key(rt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Recurring Transaction'),
            content: Text(
              'Delete "${rt.description ?? rt.category ?? 'this recurring transaction'}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(recurringTransactionProvider.notifier).deleteRecurringTransaction(rt.id);
      },
      child: GestureDetector(
        onTap: () => _showRecurringForm(context, ref, existing: rt),
        child: Container(
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color,
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
                        Expanded(
                          child: Text(
                            rt.description ?? rt.category ?? (isIncome ? 'Income' : 'Expense'),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _frequencyLabel(rt.frequency),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (linkedGoalName != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.savings_rounded, size: 12, color: Colors.teal),
                                    const SizedBox(width: 4),
                                    Text(
                                      linkedGoalName,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$accountName  ${formatter.format(rt.amount)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Next: ${dateFormat.format(rt.nextDueDate)}${rt.category != null ? '  \u2022  ${rt.category}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: rt.isActive,
                onChanged: (_) {
                  ref.read(recurringTransactionProvider.notifier).toggleActive(rt.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecurringForm(BuildContext context, WidgetRef ref, {RecurringTransaction? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => _RecurringFormSheet(existing: existing),
    );
  }

  String _frequencyLabel(RecurringFrequency freq) {
    switch (freq) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  final RecurringTransaction? existing;

  const _RecurringFormSheet({this.existing});

  @override
  ConsumerState<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategory;
  String? _selectedGoalId;
  RecurringFrequency _selectedFrequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final rt = widget.existing!;
      _selectedType = rt.type;
      _selectedAccountId = rt.accountId;
      _selectedCategory = rt.category;
      _selectedGoalId = rt.savingsGoalId;
      _amountController.text = rt.amount.toStringAsFixed(0);
      _descriptionController.text = rt.description ?? '';
      _selectedFrequency = rt.frequency;
      _startDate = rt.startDate;
      _endDate = rt.endDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _categoryOptions {
    return _selectedType == TransactionType.income
        ? TransactionCategory.incomeCategories
        : TransactionCategory.expenseCategories;
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _isEditing ? 'Edit Recurring Transaction' : 'Add Recurring Transaction',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Type selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (values) {
                setState(() {
                  _selectedType = values.first;
                  _selectedCategory = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Account dropdown
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Account',
              ),
              items: accountState.accounts.map((account) {
                return DropdownMenuItem(
                  value: account.id,
                  child: Text(account.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedAccountId = value),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Amount',
                prefixText: '${CurrencyUtils.getSymbol(_selectedAccountId != null ? (accountState.accounts.where((a) => a.id == _selectedAccountId).firstOrNull?.currency ?? 'BDT') : 'BDT')} ',
              ),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Category',
              ),
              items: _categoryOptions.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description (Optional)',
              ),
            ),
            const SizedBox(height: 16),

            // Savings Goal link
            Builder(
              builder: (context) {
                final activeGoals = ref.watch(savingsGoalProvider).activeGoals;
                if (activeGoals.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedGoalId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Auto-contribute to Goal (Optional)',
                        prefixIcon: Icon(Icons.savings_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...activeGoals.map((goal) {
                          return DropdownMenuItem<String>(
                            value: goal.id,
                            child: Text(goal.name, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (value) => setState(() => _selectedGoalId = value),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Frequency
            Text(
              'Frequency',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<RecurringFrequency>(
              segments: const [
                ButtonSegment(value: RecurringFrequency.daily, label: Text('Daily')),
                ButtonSegment(value: RecurringFrequency.weekly, label: Text('Weekly')),
                ButtonSegment(value: RecurringFrequency.monthly, label: Text('Monthly')),
                ButtonSegment(value: RecurringFrequency.yearly, label: Text('Yearly')),
              ],
              selected: {_selectedFrequency},
              onSelectionChanged: (values) {
                setState(() => _selectedFrequency = values.first);
              },
            ),
            const SizedBox(height: 16),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('Start Date: ${dateFormat.format(_startDate)}'),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),

            // End date (optional)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                _endDate != null ? 'End Date: ${dateFormat.format(_endDate!)}' : 'End Date: None (ongoing)',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  const Icon(Icons.keyboard_arrow_right),
                ],
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
                  firstDate: _startDate,
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _endDate = date);
              },
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isEditing ? 'Save Changes' : 'Add Recurring Transaction'),
              ),
            ),
            const SizedBox(height: 8),
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

  void _submit() {
    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();

    if (_isEditing) {
      ref.read(recurringTransactionProvider.notifier).updateRecurringTransaction(
            id: widget.existing!.id,
            accountId: _selectedAccountId!,
            type: _selectedType,
            amount: amount,
            category: _selectedCategory,
            description: description.isNotEmpty ? description : null,
            frequency: _selectedFrequency,
            startDate: _startDate,
            endDate: _endDate,
            savingsGoalId: _selectedGoalId,
          );
    } else {
      ref.read(recurringTransactionProvider.notifier).addRecurringTransaction(
            accountId: _selectedAccountId!,
            type: _selectedType,
            amount: amount,
            category: _selectedCategory,
            description: description.isNotEmpty ? description : null,
            frequency: _selectedFrequency,
            startDate: _startDate,
            endDate: _endDate,
            savingsGoalId: _selectedGoalId,
          );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Recurring transaction updated' : 'Recurring transaction added'),
      ),
    );
  }
}
