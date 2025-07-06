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
                    backgroundColor: _getLoanStatusColor(loan.status),
                    child: Icon(
                      _getLoanIcon(loan.type),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(loan.name),
                  subtitle: Text(
                    '${_getLoanTypeText(loan.type)} • ${_getLoanStatusText(loan.status)}',
                  ),
                  trailing: Text(
                    currencyFormatter.format(loan.remainingAmount),
                    style: TextStyle(
                      color: _getLoanStatusColor(loan.status),
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
                              Text('Principal: ${currencyFormatter.format(loan.principal)}'),
                              Text('Interest Rate: ${loan.interestRate}%'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount: ${currencyFormatter.format(loan.totalAmount)}'),
                              Text('Paid: ${currencyFormatter.format(loan.paidAmount)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Progress: ${loan.progressPercentage.toStringAsFixed(1)}%'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: loan.progressPercentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getLoanStatusColor(loan.status),
                            ),
                          ),
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
                              if (loan.status == LoanStatus.active) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _showPaymentDialog(context, loan),
                                  child: const Text('Make Payment'),
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

  Color _getLoanStatusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return Colors.orange;
      case LoanStatus.completed:
        return Colors.green;
      case LoanStatus.defaulted:
        return Colors.red;
      case LoanStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getLoanIcon(LoanType type) {
    switch (type) {
      case LoanType.personal:
        return Icons.person;
      case LoanType.home:
        return Icons.home;
      case LoanType.car:
        return Icons.directions_car;
      case LoanType.education:
        return Icons.school;
      case LoanType.business:
        return Icons.business;
      case LoanType.other:
        return Icons.help_outline;
    }
  }

  String _getLoanTypeText(LoanType type) {
    switch (type) {
      case LoanType.personal:
        return 'Personal';
      case LoanType.home:
        return 'Home';
      case LoanType.car:
        return 'Car';
      case LoanType.education:
        return 'Education';
      case LoanType.business:
        return 'Business';
      case LoanType.other:
        return 'Other';
    }
  }

  String _getLoanStatusText(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.completed:
        return 'Completed';
      case LoanStatus.defaulted:
        return 'Defaulted';
      case LoanStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showAddLoanDialog(BuildContext context) {
    final nameController = TextEditingController();
    final principalController = TextEditingController();
    final interestRateController = TextEditingController();
    final descriptionController = TextEditingController();
    LoanType selectedType = LoanType.personal;
    DateTime selectedStartDate = DateTime.now();
    DateTime? selectedEndDate;

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
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Loan Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LoanType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Loan Type'),
                  items: LoanType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getLoanTypeText(type)),
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
                  controller: principalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Principal Amount'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: interestRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Interest Rate (%)'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedStartDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        selectedStartDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date (optional)'),
                  subtitle: Text(selectedEndDate != null 
                      ? DateFormat('dd/MM/yyyy').format(selectedEndDate!)
                      : 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: selectedStartDate,
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        selectedEndDate = date;
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
                final principal = double.tryParse(principalController.text) ?? 0.0;
                final interestRate = double.tryParse(interestRateController.text) ?? 0.0;
                final description = descriptionController.text.trim();
                
                if (name.isNotEmpty && principal > 0) {
                  ref.read(loanProvider.notifier).addLoan(
                    name: name,
                    type: selectedType,
                    principal: principal,
                    interestRate: interestRate,
                    startDate: selectedStartDate,
                    endDate: selectedEndDate,
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

  void _showPaymentDialog(BuildContext context, Loan loan) {
    final paymentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Make Payment - ${loan.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Remaining Amount: ${NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(loan.remainingAmount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Payment Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final payment = double.tryParse(paymentController.text) ?? 0.0;
              
              if (payment > 0 && payment <= loan.remainingAmount) {
                ref.read(loanProvider.notifier).makePayment(loan.id, payment);
                Navigator.pop(context);
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLoanDialog(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Text('Are you sure you want to delete "${loan.name}"?\n\nThis action cannot be undone.'),
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
                SnackBar(content: Text('${loan.name} deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}