import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_utils.dart';
import '../models/savings_goal.dart';
import '../models/account.dart';

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen>
    with TickerProviderStateMixin {
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
    final currencyState = ref.watch(currencyProvider);
    final currencyFormatter =
        CurrencyUtils.getFormatter(currencyState.displayCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.flag), text: 'Active'),
            Tab(icon: Icon(Icons.check_circle), text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(currencyFormatter),
          _buildCompletedTab(currencyFormatter),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "goals_fab",
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.savings),
        label: const Text('Add Goal'),
      ),
    );
  }

  Widget _buildActiveTab(NumberFormat currencyFormatter) {
    return Consumer(
      builder: (context, ref, child) {
        final goalState = ref.watch(savingsGoalProvider);

        if (goalState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (goalState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${goalState.error}'),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(savingsGoalProvider.notifier).loadGoals(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final activeGoals = goalState.activeGoals;

        if (activeGoals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_rounded, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No active goals',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Create a savings goal to start tracking',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSummaryCard(goalState, currencyFormatter),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeGoals.length,
                itemBuilder: (context, index) {
                  return _buildGoalCard(activeGoals[index], currencyFormatter);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedTab(NumberFormat currencyFormatter) {
    return Consumer(
      builder: (context, ref, child) {
        final goalState = ref.watch(savingsGoalProvider);

        if (goalState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedGoals = goalState.completedGoals;

        if (completedGoals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No completed goals',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Completed goals will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedGoals.length,
          itemBuilder: (context, index) {
            return _buildGoalCard(completedGoals[index], currencyFormatter);
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
      SavingsGoalState goalState, NumberFormat currencyFormatter) {
    final activeGoals = goalState.activeGoals;
    final totalTarget = activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final overallProgress = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal,
            Colors.teal.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Savings Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${currencyFormatter.format(totalSaved)} / ${currencyFormatter.format(totalTarget)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Goals',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8))),
                    Text('${activeGoals.length} goals',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overall',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8))),
                    Text('${(overallProgress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal, NumberFormat currencyFormatter) {
    final priorityColor = _getPriorityColor(goal.priority);
    final daysLeft = goal.daysUntilTarget;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal.isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    goal.isCompleted ? Icons.check_circle : Icons.flag,
                    color: goal.isCompleted ? Colors.green : Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(goal.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              goal.priority.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: priorityColor,
                                      fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormatter.format(goal.currentAmount)} / ${currencyFormatter.format(goal.targetAmount)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progressPercentage,
                minHeight: 10,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted
                      ? Colors.green
                      : goal.isOverdue
                          ? Colors.red
                          : Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(goal.progressPercentage * 100).toStringAsFixed(1)}% saved',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: goal.isCompleted ? Colors.green : Colors.teal),
                ),
                Text(
                  goal.isCompleted
                      ? 'Completed'
                      : goal.isOverdue
                          ? 'Overdue'
                          : daysLeft == 0
                              ? 'Due today'
                              : '$daysLeft days left',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: goal.isCompleted
                          ? Colors.green
                          : goal.isOverdue
                              ? Colors.red
                              : daysLeft <= 30
                                  ? Colors.orange
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                ),
              ],
            ),
            // Target date
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Target: ${DateFormat('dd MMM yyyy').format(goal.targetDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (goal.description != null && goal.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(goal.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!goal.isCompleted) ...[
                  TextButton.icon(
                    onPressed: () => _showAddMoneyDialog(context, goal),
                    icon: const Icon(Icons.add_circle, size: 16),
                    label: const Text('Add Money'),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showEditGoalDialog(context, goal),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ],
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteGoalDialog(context, goal),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 90));
    String priority = 'medium';
    Account? selectedAccount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Emergency Fund',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    border: const OutlineInputBorder(),
                    prefixText:
                        '${CurrencyUtils.getSymbol(selectedAccount?.currency ?? ref.read(currencyProvider).displayCurrency)} ',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Target Date'),
                  subtitle:
                      Text(DateFormat('dd/MM/yyyy').format(targetDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => targetDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text('Priority',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'low', label: Text('Low')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'high', label: Text('High')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (selected) {
                    setState(() => priority = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final accountState = ref.watch(accountProvider);
                    final accounts = accountState.accounts;
                    if (accounts.isEmpty) return const SizedBox.shrink();

                    return DropdownButtonFormField<Account>(
                      value: selectedAccount,
                      decoration: const InputDecoration(
                        labelText: 'Link to Account (optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<Account>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...accounts.map((account) {
                          return DropdownMenuItem<Account>(
                            value: account,
                            child: Text(
                              '${account.name} (${CurrencyUtils.formatCurrency(account.balance, account.currency)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (Account? account) {
                        setState(() => selectedAccount = account);
                      },
                    );
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
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text) ?? 0.0;
                final description = descriptionController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a goal name')),
                  );
                  return;
                }
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid target amount')),
                  );
                  return;
                }

                final currency = selectedAccount?.currency ??
                    ref.read(currencyProvider).displayCurrency;

                ref.read(savingsGoalProvider.notifier).addGoal(
                      name: name,
                      targetAmount: amount,
                      targetDate: targetDate,
                      currency: currency,
                      description:
                          description.isNotEmpty ? description : null,
                      accountId: selectedAccount?.id,
                      priority: priority,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Savings goal created!')),
                );
              },
              child: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, SavingsGoal goal) {
    final nameController = TextEditingController(text: goal.name);
    final amountController =
        TextEditingController(text: goal.targetAmount.toString());
    final descriptionController =
        TextEditingController(text: goal.description ?? '');
    DateTime targetDate = goal.targetDate;
    String priority = goal.priority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    border: const OutlineInputBorder(),
                    prefixText:
                        '${CurrencyUtils.getSymbol(goal.currency)} ',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Target Date'),
                  subtitle:
                      Text(DateFormat('dd/MM/yyyy').format(targetDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => targetDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text('Priority',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'low', label: Text('Low')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'high', label: Text('High')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (selected) {
                    setState(() => priority = selected.first);
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
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text) ?? 0.0;
                final description = descriptionController.text.trim();

                if (name.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please fill in name and valid amount')),
                  );
                  return;
                }

                final updated = goal.copyWith(
                  name: name,
                  targetAmount: amount,
                  targetDate: targetDate,
                  priority: priority,
                  description:
                      description.isNotEmpty ? description : null,
                );
                ref.read(savingsGoalProvider.notifier).updateGoal(updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal updated!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, SavingsGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money to Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Goal: ${goal.name}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining: ${CurrencyUtils.formatCurrency(goal.remainingAmount, goal.currency)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: '${CurrencyUtils.getSymbol(goal.currency)} ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount =
                  double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid amount')),
                );
                return;
              }

              ref
                  .read(savingsGoalProvider.notifier)
                  .addToGoal(goal.id, amount);
              Navigator.pop(context);

              final newTotal = goal.currentAmount + amount;
              if (newTotal >= goal.targetAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Congratulations! Goal completed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Added ${CurrencyUtils.formatCurrency(amount, goal.currency)} to ${goal.name}')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGoalDialog(BuildContext context, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
            'Are you sure you want to delete "${goal.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(savingsGoalProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
