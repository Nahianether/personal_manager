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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Are you sure you want to mark liability to "${liability.personName}" as paid?'),
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
    final personNameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
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
                  controller: personNameController,
                  decoration: const InputDecoration(labelText: 'Person Name (Who you owe money to)'),
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
                final personName = personNameController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0.0;
                final description = descriptionController.text.trim();
                
                if (personName.isNotEmpty && amount > 0) {
                  ref.read(liabilityProvider.notifier).addLiability(
                    personName: personName,
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
}