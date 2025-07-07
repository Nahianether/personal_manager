import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../providers/liability_provider.dart';
import '../models/loan.dart';
import '../models/liability.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with TickerProviderStateMixin {
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
        title: const Text('Debts & Liabilities'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.trending_up),
              text: 'Loans',
            ),
            Tab(
              icon: Icon(Icons.assignment),
              text: 'Liabilities',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoansTab(currencyFormatter),
          _buildLiabilitiesTab(currencyFormatter),
        ],
      ),
      floatingActionButton: _buildTabSpecificFAB(),
    );
  }

  Widget _buildTabSpecificFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isLoansTab = _tabController.index == 0;
        return FloatingActionButton.extended(
          heroTag: "debts_fab",
          onPressed: () {
            if (isLoansTab) {
              _showAddLoanDialog(context);
            } else {
              _showAddLiabilityDialog(context);
            }
          },
          backgroundColor: isLoansTab ? Colors.orange : Colors.red,
          foregroundColor: Colors.white,
          icon: Icon(isLoansTab ? Icons.trending_up : Icons.assignment),
          label: Text(isLoansTab ? 'Add Loan' : 'Add Liability'),
        );
      },
    );
  }

  Widget _buildLoansTab(NumberFormat currencyFormatter) {
    return Consumer(
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No loans found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a loan to track your borrowings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildLoansSummaryCard(loanState, currencyFormatter),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: loanState.loans.length,
                itemBuilder: (context, index) {
                  final loan = loanState.loans[index];
                  return _buildLoanCard(loan, currencyFormatter);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiabilitiesTab(NumberFormat currencyFormatter) {
    return Consumer(
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No liabilities found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a liability to track your obligations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildLiabilitiesSummaryCard(liabilityState, currencyFormatter),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: liabilityState.liabilities.length,
                itemBuilder: (context, index) {
                  final liability = liabilityState.liabilities[index];
                  return _buildLiabilityCard(liability, currencyFormatter);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoansSummaryCard(dynamic loanState, NumberFormat currencyFormatter) {
    final totalLoanAmount = loanState.totalLoanAmount;
    final activeLoans = loanState.loans.where((l) => l.status.name == 'active').length;
    final completedLoans = loanState.loans.where((l) => l.status.name == 'completed').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange,
            Colors.orange.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
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
              Text(
                'Total Loans',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormatter.format(totalLoanAmount),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                    Text(
                      '$activeLoans loans',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                    Text(
                      '$completedLoans loans',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesSummaryCard(dynamic liabilityState, NumberFormat currencyFormatter) {
    final totalLiabilityAmount = liabilityState.totalLiabilityAmount;
    final overdueItems = liabilityState.overdueItems.length;
    final upcomingItems = liabilityState.upcomingItems.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red,
            Colors.red.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
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
              Text(
                'Total Liabilities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormatter.format(totalLiabilityAmount),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overdue',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                    Text(
                      '$overdueItems items',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                    Text(
                      '$upcomingItems items',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Loan loan, NumberFormat currencyFormatter) {
    final isActive = !loan.isReturned;

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
                    color: isActive ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: isActive ? Colors.orange : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You lent to: ${loan.personName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Status: ${loan.isReturned ? 'Returned' : 'Outstanding'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(loan.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isActive ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      isActive ? 'Outstanding' : 'Returned',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loan.description != null && loan.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                loan.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Loan Date: ${DateFormat('dd MMM yyyy').format(loan.loanDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (loan.returnDate != null)
                  Expanded(
                    child: Text(
                      'Returned: ${DateFormat('dd MMM yyyy').format(loan.returnDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActive)
                  TextButton.icon(
                    onPressed: () => _showMarkLoanReturnedDialog(context, loan),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Mark Returned'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteLoanDialog(context, loan),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiabilityCard(Liability liability, NumberFormat currencyFormatter) {
    final isOverdue = liability.isOverdue;
    final daysUntilDue = liability.daysUntilDue;
    final isPaid = liability.isPaid;

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
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.1)
                        : isOverdue
                            ? Colors.red.withValues(alpha: 0.1)
                            : daysUntilDue <= 7
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPaid 
                        ? Icons.check_circle
                        : isOverdue 
                            ? Icons.warning 
                            : Icons.assignment,
                    color: isPaid
                        ? Colors.green
                        : isOverdue
                            ? Colors.red
                            : daysUntilDue <= 7
                                ? Colors.orange
                                : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To: ${liability.personName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        isPaid ? 'PAID' : isOverdue ? 'OVERDUE' : 'PENDING',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isPaid 
                                  ? Colors.green
                                  : isOverdue 
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormatter.format(liability.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isPaid 
                            ? Colors.green 
                            : isOverdue 
                                ? Colors.red 
                                : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withValues(alpha: 0.1)
                    : daysUntilDue <= 7
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue
                        ? Colors.red
                        : daysUntilDue <= 7
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(liability.dueDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isOverdue
                              ? Colors.red
                              : daysUntilDue <= 7
                                  ? Colors.orange
                                  : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  if (isOverdue)
                    Text(
                      'OVERDUE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  else if (daysUntilDue <= 7)
                    Text(
                      'Due in $daysUntilDue days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  else
                    Text(
                      'Due in $daysUntilDue days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                ],
              ),
            ),
            if (liability.description != null && liability.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                liability.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDeleteLiabilityDialog(context, liability),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
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
                  decoration: const InputDecoration(
                    labelText: 'Person Name (Who you owe money to)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '৳ ',
                  ),
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
                  ref.read(liabilityProvider.notifier).addLiability(
                        personName: personName,
                        amount: amount,
                        dueDate: selectedDueDate,
                        description: description.isNotEmpty ? description : null,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Liability added successfully!')),
                  );
                }
              },
              child: const Text('Add Liability'),
            ),
          ],
        ),
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
                const SnackBar(content: Text('Liability deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMarkLoanReturnedDialog(BuildContext context, Loan loan) {
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
}
