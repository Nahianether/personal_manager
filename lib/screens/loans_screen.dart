import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../models/loan.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 2,
    );

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
                    currencyFormatter.format(loan.amount),
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
                              Text('Amount: ${currencyFormatter.format(loan.amount)}'),
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
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mark Loan as Returned'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mark loan to "${loan.personName}" as returned?'),
              const SizedBox(height: 16),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(loanProvider.notifier).markLoanAsReturned(loan.id, returnDate);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan marked as returned!')),
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
    DateTime? selectedReturnDate;

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
                  decoration: const InputDecoration(
                    labelText: 'Loan Amount',
                    border: OutlineInputBorder(),
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 16),
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
                ListTile(
                  title: const Text('Return Date (optional)'),
                  subtitle: Text(selectedReturnDate != null ? DateFormat('dd/MM/yyyy').format(selectedReturnDate!) : 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedReturnDate ?? DateTime.now(),
                      firstDate: selectedLoanDate,
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        selectedReturnDate = date;
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

                if (personName.isNotEmpty && amount > 0) {
                  ref.read(loanProvider.notifier).addLoan(
                        personName: personName,
                        amount: amount,
                        loanDate: selectedLoanDate,
                        returnDate: selectedReturnDate,
                        description: description.isNotEmpty ? description : null,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loan added successfully!')),
                  );
                }
              },
              child: const Text('Add Loan'),
            ),
          ],
        ),
      ),
    );
  }
}