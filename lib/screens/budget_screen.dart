import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_utils.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final transactionState = ref.watch(transactionProvider);
    final budgetNotifier = ref.read(budgetProvider.notifier);
    final statuses = budgetNotifier.getBudgetStatuses(transactionState.transactions);
    // Sort by percentage descending (highest usage first)
    statuses.sort((a, b) => b.percentage.compareTo(a.percentage));

    final displayCurrency = ref.watch(currencyProvider).displayCurrency;
    final currencyFormatter = CurrencyUtils.getFormatter(displayCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : statuses.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: statuses.length,
                  itemBuilder: (context, index) {
                    return _buildBudgetCard(
                      context,
                      ref,
                      statuses[index],
                      currencyFormatter,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set budgets for your expense categories\nto track your spending',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    BudgetStatus status,
    NumberFormat formatter,
  ) {
    final color = _getProgressColor(status.percentage);
    final clampedProgress = (status.percentage / 100).clamp(0.0, 1.0);

    return Dismissible(
      key: Key(status.budget.id),
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
            title: const Text('Delete Budget'),
            content: Text('Delete budget for "${status.budget.category}"?'),
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
        ref.read(budgetProvider.notifier).deleteBudget(status.budget.id);
      },
      child: GestureDetector(
        onTap: () => _showBudgetDialog(context, ref, existingBudget: status.budget),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      status.budget.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _periodLabel(status.budget.period),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatter.format(status.spent)} / ${formatter.format(status.budget.amount)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${status.percentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (status.isOverBudget) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.warning_rounded, color: Colors.red, size: 18),
                      ] else if (status.isWarning) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.info_rounded, color: Colors.orange, size: 18),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: clampedProgress,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              if (status.remaining > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${formatter.format(status.remaining)} remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ] else if (status.isOverBudget) ...[
                const SizedBox(height: 6),
                Text(
                  '${formatter.format(-status.remaining)} over budget',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, {Budget? existingBudget}) {
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
      builder: (context) => _BudgetFormSheet(existingBudget: existingBudget),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage > 100) return Colors.red;
    if (percentage >= 80) return Colors.orange;
    if (percentage >= 60) return Colors.amber.shade700;
    return Colors.green;
  }

  String _periodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final Budget? existingBudget;

  const _BudgetFormSheet({this.existingBudget});

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _amountController = TextEditingController();
  String? _selectedCategory;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;

  bool get _isEditing => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedCategory = widget.existingBudget!.category;
      _amountController.text = widget.existingBudget!.amount.toStringAsFixed(0);
      _selectedPeriod = widget.existingBudget!.period;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
            _isEditing ? 'Edit Budget' : 'Add Budget',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Category',
            ),
            items: TransactionCategory.expenseCategories.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Budget Amount',
              prefixText: '${CurrencyUtils.getSymbol(ref.watch(currencyProvider).displayCurrency)} ',
            ),
          ),
          const SizedBox(height: 16),

          // Period selector
          Text(
            'Period',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<BudgetPeriod>(
            segments: const [
              ButtonSegment(value: BudgetPeriod.weekly, label: Text('Weekly')),
              ButtonSegment(value: BudgetPeriod.monthly, label: Text('Monthly')),
              ButtonSegment(value: BudgetPeriod.yearly, label: Text('Yearly')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (values) {
              setState(() => _selectedPeriod = values.first);
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
              child: Text(_isEditing ? 'Save Changes' : 'Add Budget'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _selectedCategory != null &&
        _amountController.text.isNotEmpty &&
        double.tryParse(_amountController.text) != null &&
        double.parse(_amountController.text) > 0;
  }

  void _submit() {
    final amount = double.parse(_amountController.text);

    if (_isEditing) {
      ref.read(budgetProvider.notifier).updateBudget(
            budgetId: widget.existingBudget!.id,
            category: _selectedCategory!,
            amount: amount,
            period: _selectedPeriod,
          );
    } else {
      ref.read(budgetProvider.notifier).addBudget(
            category: _selectedCategory!,
            amount: amount,
            period: _selectedPeriod,
          );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Budget updated' : 'Budget added'),
      ),
    );
  }
}
