import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/liability_provider.dart';
import '../models/liability.dart';

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
                    backgroundColor: _getLiabilityStatusColor(liability.status),
                    child: Icon(
                      _getLiabilityIcon(liability.type),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(liability.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_getLiabilityTypeText(liability.type)} • ${_getLiabilityStatusText(liability.status)}'),
                      Text('Due: ${DateFormat('dd/MM/yyyy').format(liability.dueDate)}'),
                      if (liability.isOverdue)
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
                            color: _getLiabilityStatusColor(liability.status),
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
                            if (liability.status == LiabilityStatus.pending)
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

  Color _getLiabilityStatusColor(LiabilityStatus status) {
    switch (status) {
      case LiabilityStatus.pending:
        return Colors.orange;
      case LiabilityStatus.paid:
        return Colors.green;
      case LiabilityStatus.overdue:
        return Colors.red;
      case LiabilityStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getLiabilityIcon(LiabilityType type) {
    switch (type) {
      case LiabilityType.bill:
        return Icons.receipt;
      case LiabilityType.debt:
        return Icons.money_off;
      case LiabilityType.subscription:
        return Icons.subscriptions;
      case LiabilityType.insurance:
        return Icons.security;
      case LiabilityType.tax:
        return Icons.account_balance;
      case LiabilityType.other:
        return Icons.help_outline;
    }
  }

  String _getLiabilityTypeText(LiabilityType type) {
    switch (type) {
      case LiabilityType.bill:
        return 'Bill';
      case LiabilityType.debt:
        return 'Debt';
      case LiabilityType.subscription:
        return 'Subscription';
      case LiabilityType.insurance:
        return 'Insurance';
      case LiabilityType.tax:
        return 'Tax';
      case LiabilityType.other:
        return 'Other';
    }
  }

  String _getLiabilityStatusText(LiabilityStatus status) {
    switch (status) {
      case LiabilityStatus.pending:
        return 'Pending';
      case LiabilityStatus.paid:
        return 'Paid';
      case LiabilityStatus.overdue:
        return 'Overdue';
      case LiabilityStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _markAsPaid(BuildContext context, Liability liability) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Are you sure you want to mark "${liability.name}" as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(liabilityProvider.notifier).markAsPaid(liability.id);
              Navigator.pop(context);
            },
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
  }

  void _showAddLiabilityDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    LiabilityType selectedType = LiabilityType.bill;
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));

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
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Liability Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LiabilityType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Liability Type'),
                  items: LiabilityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getLiabilityTypeText(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
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
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0.0;
                final description = descriptionController.text.trim();
                
                if (name.isNotEmpty && amount > 0) {
                  ref.read(liabilityProvider.notifier).addLiability(
                    name: name,
                    type: selectedType,
                    amount: amount,
                    dueDate: selectedDueDate,
                    description: description.isNotEmpty ? description : null,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
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
        content: Text('Are you sure you want to delete "${liability.name}"?\n\nThis action cannot be undone.'),
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
                SnackBar(content: Text('${liability.name} deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}