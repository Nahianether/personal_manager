import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/liability_provider.dart';
import '../providers/currency_provider.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/pdf_report_data.dart';
import '../services/pdf_report_service.dart';
import '../utils/currency_utils.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final displayCurrency = ref.watch(currencyProvider).displayCurrency;
    final currencyFormatter = CurrencyUtils.getFormatter(displayCurrency);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Reports'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF Report',
              onPressed: () => _exportPdfReport(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'Overview'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Accounts'),
              Tab(icon: Icon(Icons.trending_up), text: 'Loans & Debts'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(currencyFormatter),
                  _buildTransactionsTab(currencyFormatter),
                  _buildAccountsTab(currencyFormatter),
                  _buildLoansTab(currencyFormatter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<ReportPeriod>(
                  segments: const [
                    ButtonSegment(value: ReportPeriod.daily, label: Text('Daily')),
                    ButtonSegment(value: ReportPeriod.weekly, label: Text('Weekly')),
                    ButtonSegment(value: ReportPeriod.monthly, label: Text('Monthly')),
                    ButtonSegment(value: ReportPeriod.yearly, label: Text('Yearly')),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (value) {
                    setState(() {
                      _selectedPeriod = value.first;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_formatSelectedDate()),
                  subtitle: Text('Tap to change ${_selectedPeriod.name}'),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: _selectDate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(NumberFormat currencyFormatter) {
    return Consumer(
      builder: (context, ref, child) {
        final transactionState = ref.watch(transactionProvider);
        final accountState = ref.watch(accountProvider);
        final loanState = ref.watch(loanProvider);
        final liabilityState = ref.watch(liabilityProvider);

        if (transactionState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredTransactions = _getFilteredTransactions(transactionState.transactions);
        final overviewData = _calculateOverviewData(filteredTransactions, accountState, loanState, liabilityState);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(overviewData, currencyFormatter),
              const SizedBox(height: 24),
              _buildIncomeExpenseChart(filteredTransactions, currencyFormatter),
              const SizedBox(height: 24),
              _buildCategoryBreakdown(filteredTransactions, currencyFormatter),
              const SizedBox(height: 24),
              _buildTrendChart(transactionState.transactions, currencyFormatter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(NumberFormat currencyFormatter) {
    return Consumer(
      builder: (context, ref, child) {
        final transactionState = ref.watch(transactionProvider);
        final accountState = ref.watch(accountProvider);

        if (transactionState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredTransactions = _getFilteredTransactions(transactionState.transactions);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionStats(filteredTransactions, currencyFormatter),
              const SizedBox(height: 20),
              _buildTransactionsList(filteredTransactions, accountState.accounts, currencyFormatter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountsTab(NumberFormat currencyFormatter) {
    return Consumer(
      builder: (context, ref, child) {
        final accountState = ref.watch(accountProvider);
        final transactionState = ref.watch(transactionProvider);

        if (accountState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountsSummary(accountState.accounts, currencyFormatter),
              const SizedBox(height: 24),
              _buildAccountsChart(accountState.accounts, currencyFormatter),
              const SizedBox(height: 24),
              _buildAccountsDetails(accountState.accounts, transactionState.transactions, currencyFormatter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoansTab(NumberFormat currencyFormatter) {
    return Consumer(
      builder: (context, ref, child) {
        final loanState = ref.watch(loanProvider);
        final liabilityState = ref.watch(liabilityProvider);

        if (loanState.isLoading || liabilityState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLoansSummary(loanState.loans, liabilityState.liabilities, currencyFormatter),
              const SizedBox(height: 24),
              _buildLoansChart(loanState.loans, liabilityState.liabilities, currencyFormatter),
              const SizedBox(height: 24),
              _buildLoansDetails(loanState.loans, currencyFormatter),
              const SizedBox(height: 24),
              _buildLiabilitiesDetails(liabilityState.liabilities, currencyFormatter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data, NumberFormat currencyFormatter) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Income',
                currencyFormatter.format(data['totalIncome']),
                Icons.arrow_downward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Expense',
                currencyFormatter.format(data['totalExpense']),
                Icons.arrow_upward,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Net Balance',
                currencyFormatter.format(data['netBalance']),
                data['netBalance'] >= 0 ? Icons.trending_up : Icons.trending_down,
                data['netBalance'] >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Assets',
                currencyFormatter.format(data['totalAssets']),
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseChart(List<Transaction> transactions, NumberFormat currencyFormatter) {
    final income = transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expense - ${_formatSelectedDate()}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (income == 0 && expense == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No transactions found for selected period'),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: income,
                      color: Colors.green,
                      title: 'Income\n${currencyFormatter.format(income)}',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: expense,
                      color: Colors.red,
                      title: 'Expense\n${currencyFormatter.format(expense)}',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      radius: 80,
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<Transaction> transactions, NumberFormat currencyFormatter) {
    final categoryData = <String, double>{};
    
    for (final transaction in transactions.where((t) => t.type == TransactionType.expense)) {
      final category = transaction.category ?? 'Other';
      categoryData[category] = (categoryData[category] ?? 0) + transaction.amount;
    }

    final sortedCategories = categoryData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Categories - ${_formatSelectedDate()}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (sortedCategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No expense categories found'),
              ),
            )
          else
            Column(
              children: sortedCategories.take(5).map((entry) {
                final percentage = (entry.value / sortedCategories.fold(0.0, (sum, e) => sum + e.value)) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(entry.value),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Transaction> allTransactions, NumberFormat currencyFormatter) {
    final trendData = _getTrendData(allTransactions);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis - Last 6 Months',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < trendData.length) {
                          return Text(
                            DateFormat('MMM').format(trendData[value.toInt()]['date']),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['income'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['expense'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Income'),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Expense'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStats(List<Transaction> transactions, NumberFormat currencyFormatter) {
    final income = transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    final incomeCount = transactions.where((t) => t.type == TransactionType.income).length;
    final expenseCount = transactions.where((t) => t.type == TransactionType.expense).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Summary - ${_formatSelectedDate()}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Income', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(income),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('$incomeCount transactions', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Expense', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(expense),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('$expenseCount transactions', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Net', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(income - expense),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: (income - expense) >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${incomeCount + expenseCount} total', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, List<Account> accounts, NumberFormat currencyFormatter) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No transactions found for selected period',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Transactions - ${_formatSelectedDate()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final account = accounts.firstWhere((a) => a.id == transaction.accountId, orElse: () => Account(
                id: '',
                name: 'Unknown',
                type: AccountType.cash,
                balance: 0,
                currency: 'BDT',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                  child: Icon(
                    transaction.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                  ),
                ),
                title: Text(transaction.category ?? 'Transaction'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name),
                    if (transaction.description != null) Text(transaction.description!),
                    Text(DateFormat('dd MMM yyyy, HH:mm').format(transaction.date)),
                  ],
                ),
                trailing: Text(
                  '${transaction.type == TransactionType.expense ? '-' : '+'}${currencyFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsSummary(List<Account> accounts, NumberFormat currencyFormatter) {
    final totalBalance = accounts.fold(0.0, (sum, account) => sum + account.balance);
    final regularAccounts = accounts.where((a) => !a.isCreditCard).toList();
    final creditCards = accounts.where((a) => a.isCreditCard).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accounts Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Total Balance', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(totalBalance),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: totalBalance >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Regular Accounts', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${regularAccounts.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Credit Cards', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${creditCards.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildAccountsChart(List<Account> accounts, NumberFormat currencyFormatter) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No accounts found')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: accounts.map((account) {
                  final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.indigo];
                  final color = colors[accounts.indexOf(account) % colors.length];
                  
                  return PieChartSectionData(
                    value: account.balance.abs(),
                    color: color,
                    title: account.name,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    radius: 80,
                  );
                }).toList(),
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsDetails(List<Account> accounts, List<Transaction> transactions, NumberFormat currencyFormatter) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Account Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: accounts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final accountTransactions = transactions.where((t) => t.accountId == account.id).length;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    _getAccountIcon(account.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(account.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.type.toString().split('.').last.toUpperCase()),
                    if (account.isCreditCard && account.creditLimit != null)
                      Text('Limit: ${currencyFormatter.format(account.creditLimit!)}'),
                    Text('$accountTransactions transactions'),
                  ],
                ),
                trailing: Text(
                  currencyFormatter.format(account.balance),
                  style: TextStyle(
                    color: account.balance >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoansSummary(List<Loan> loans, List<Liability> liabilities, NumberFormat currencyFormatter) {
    final totalLoanAmount = loans.fold(0.0, (sum, loan) => sum + (loan.isReturned ? 0.0 : loan.amount));
    final totalLiabilityAmount = liabilities.fold(0.0, (sum, liability) => sum + liability.amount);
    final activeLoans = loans.where((l) => !l.isReturned).length;
    final overdueItems = liabilities.where((l) => l.dueDate.isBefore(DateTime.now())).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loans & Liabilities Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Total Loans', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(totalLoanAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('$activeLoans active', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Total Liabilities', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(totalLiabilityAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('$overdueItems overdue', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoansChart(List<Loan> loans, List<Liability> liabilities, NumberFormat currencyFormatter) {
    if (loans.isEmpty && liabilities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No loans or liabilities found')),
      );
    }

    final totalLoanAmount = loans.fold(0.0, (sum, loan) => sum + (loan.isReturned ? 0.0 : loan.amount));
    final totalLiabilityAmount = liabilities.fold(0.0, (sum, liability) => sum + liability.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debt Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  if (totalLoanAmount > 0)
                    PieChartSectionData(
                      value: totalLoanAmount,
                      color: Colors.orange,
                      title: 'Loans\n${currencyFormatter.format(totalLoanAmount)}',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      radius: 80,
                    ),
                  if (totalLiabilityAmount > 0)
                    PieChartSectionData(
                      value: totalLiabilityAmount,
                      color: Colors.red,
                      title: 'Liabilities\n${currencyFormatter.format(totalLiabilityAmount)}',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      radius: 80,
                    ),
                ],
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansDetails(List<Loan> loans, NumberFormat currencyFormatter) {
    if (loans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No loans found')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Loan Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: loans.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final loan = loans[index];
              final progress = loan.isReturned ? 1.0 : 0.0;
              
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.trending_up, color: Colors.white),
                ),
                title: Text('Loan to ${loan.personName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Due: ${loan.returnDate != null ? DateFormat('dd MMM yyyy').format(loan.returnDate!) : 'No due date'}'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    const SizedBox(height: 4),
                    Text('${(progress * 100).toStringAsFixed(1)}% paid'),
                  ],
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currencyFormatter.format(loan.isReturned ? 0.0 : loan.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    Text(
                      'of ${currencyFormatter.format(loan.amount)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesDetails(List<Liability> liabilities, NumberFormat currencyFormatter) {
    if (liabilities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No liabilities found')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Liability Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liabilities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final liability = liabilities[index];
              final isOverdue = liability.dueDate.isBefore(DateTime.now());
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOverdue ? Colors.red : Colors.blue,
                  child: Icon(
                    isOverdue ? Icons.warning : Icons.assignment,
                    color: Colors.white,
                  ),
                ),
                title: Text(liability.personName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(liability.description ?? 'Personal Liability'),
                    Text('Due: ${DateFormat('dd MMM yyyy').format(liability.dueDate)}'),
                    if (isOverdue)
                      const Text(
                        'OVERDUE',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: Text(
                  currencyFormatter.format(liability.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red : Colors.blue,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdfReport(BuildContext context) async {
    if (!context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF report...'),
            ],
          ),
        ),
      );

      final transactionState = ref.read(transactionProvider);
      final accountState = ref.read(accountProvider);
      final loanState = ref.read(loanProvider);
      final liabilityState = ref.read(liabilityProvider);

      final filteredTransactions =
          _getFilteredTransactions(transactionState.transactions);
      final overviewData = _calculateOverviewData(
        filteredTransactions,
        accountState,
        loanState,
        liabilityState,
      );

      final expensesByCategory = <String, double>{};
      for (final t in filteredTransactions
          .where((t) => t.type == TransactionType.expense)) {
        final cat = t.category ?? 'Other';
        expensesByCategory[cat] = (expensesByCategory[cat] ?? 0) + t.amount;
      }
      final incomesByCategory = <String, double>{};
      for (final t in filteredTransactions
          .where((t) => t.type == TransactionType.income)) {
        final cat = t.category ?? 'Other';
        incomesByCategory[cat] = (incomesByCategory[cat] ?? 0) + t.amount;
      }

      final displayCurrency = ref.read(currencyProvider).displayCurrency;

      final reportData = PdfReportData(
        periodLabel: _formatSelectedDate(),
        periodType: _selectedPeriod.name[0].toUpperCase() +
            _selectedPeriod.name.substring(1),
        generatedAt: DateTime.now(),
        totalIncome: overviewData['totalIncome'],
        totalExpense: overviewData['totalExpense'],
        netBalance: overviewData['netBalance'],
        totalAssets: overviewData['totalAssets'],
        expensesByCategory: expensesByCategory,
        incomesByCategory: incomesByCategory,
        transactions: filteredTransactions,
        accounts: accountState.accounts,
        loans: loanState.loans,
        liabilities: liabilityState.liabilities,
        displayCurrency: displayCurrency,
      );

      final success =
          await PdfReportService().generateAndShareReport(reportData);

      if (context.mounted) {
        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF report generated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case ReportPeriod.weekly:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
      case ReportPeriod.yearly:
        startDate = DateTime(_selectedDate.year, 1, 1);
        endDate = DateTime(_selectedDate.year + 1, 1, 1);
        break;
    }

    return transactions.where((transaction) {
      return transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transaction.date.isBefore(endDate);
    }).toList();
  }

  Map<String, dynamic> _calculateOverviewData(
    List<Transaction> transactions,
    dynamic accountState,
    dynamic loanState,
    dynamic liabilityState,
  ) {
    final totalIncome = transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpense;
    final totalAssets = accountState.totalBalance;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netBalance': netBalance,
      'totalAssets': totalAssets,
    };
  }

  List<Map<String, dynamic>> _getTrendData(List<Transaction> transactions) {
    final now = DateTime.now();
    final trendData = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 1);

      final monthTransactions = transactions.where((t) =>
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth)).toList();

      final income = monthTransactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
      final expense = monthTransactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);

      trendData.add({
        'date': monthDate,
        'income': income,
        'expense': expense,
      });
    }

    return trendData;
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

  String _formatSelectedDate() {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return DateFormat('dd MMM yyyy').format(_selectedDate);
      case ReportPeriod.weekly:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
      case ReportPeriod.monthly:
        return DateFormat('MMM yyyy').format(_selectedDate);
      case ReportPeriod.yearly:
        return DateFormat('yyyy').format(_selectedDate);
    }
  }

  void _selectDate() async {
    DateTime? selectedDate;
    
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        selectedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        break;
      case ReportPeriod.weekly:
        selectedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        break;
      case ReportPeriod.monthly:
        selectedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        break;
      case ReportPeriod.yearly:
        selectedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        break;
    }

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate!;
      });
    }
  }
}