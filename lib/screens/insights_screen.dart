import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_utils.dart';
import 'budget_screen.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const _categoryColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayCurrency = ref.watch(currencyProvider).displayCurrency;
    final currencyFormatter = CurrencyUtils.getFormatter(displayCurrency);
    final txnNotifier = ref.read(transactionProvider.notifier);
    final budgets = ref.watch(budgetProvider).budgets;

    final monthlySummary = txnNotifier.getMonthlySpendingSummary();
    final categoryTrends = txnNotifier.getCategorySpendingOverTime();
    final budgetSuggestions = txnNotifier.getSmartBudgetSuggestions(budgets);
    final unusualAlerts = txnNotifier.getUnusualSpendingAlerts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlySummarySection(context, monthlySummary, currencyFormatter),
            const SizedBox(height: 28),
            _buildCategoryTrendsSection(context, categoryTrends, currencyFormatter),
            const SizedBox(height: 28),
            _buildBudgetSuggestionsSection(context, budgetSuggestions, currencyFormatter),
            const SizedBox(height: 28),
            _buildUnusualSpendingSection(context, unusualAlerts, currencyFormatter),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section 1: Monthly Summary ──

  Widget _buildMonthlySummarySection(
    BuildContext context,
    List<Map<String, dynamic>> summary,
    NumberFormat formatter,
  ) {
    final currentMonth = summary.isNotEmpty ? summary.last : null;
    final monthName = currentMonth != null
        ? DateFormat('MMMM yyyy').format(currentMonth['month'] as DateTime)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Monthly Summary', monthName),
        const SizedBox(height: 12),
        if (currentMonth != null) _buildStatCards(context, currentMonth, formatter),
        const SizedBox(height: 16),
        _buildMonthlyBarChart(context, summary, formatter),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, Map<String, dynamic> data, NumberFormat formatter) {
    final income = data['income'] as double;
    final expense = data['expense'] as double;
    final net = data['net'] as double;
    final changePercent = data['changePercent'] as double?;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Income',
            formatter.format(income),
            Icons.arrow_downward_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Expense',
            formatter.format(expense),
            Icons.arrow_upward_rounded,
            Colors.red,
            changePercent: changePercent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Net',
            formatter.format(net.abs()),
            net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            net >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    double? changePercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (changePercent != null) ...[
            const SizedBox(height: 2),
            Text(
              '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: changePercent > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(
    BuildContext context,
    List<Map<String, dynamic>> summary,
    NumberFormat formatter,
  ) {
    if (summary.isEmpty) {
      return _buildEmptyMessage(context, 'No transaction data yet');
    }

    double maxY = 0;
    for (final m in summary) {
      final income = m['income'] as double;
      final expense = m['expense'] as double;
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLegendDot(Colors.green, 'Income'),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.red, 'Expense'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < summary.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('MMM').format(summary[idx]['month'] as DateTime),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: List.generate(summary.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: summary[i]['income'] as double,
                        color: Colors.green.withValues(alpha: 0.8),
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: summary[i]['expense'] as double,
                        color: Colors.red.withValues(alpha: 0.8),
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: Category Trends ──

  Widget _buildCategoryTrendsSection(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> categoryTrends,
    NumberFormat formatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Category Trends', '6 Months'),
        const SizedBox(height: 12),
        _buildCategoryLineChart(context, categoryTrends),
        const SizedBox(height: 12),
        _buildCategoryLegend(context, categoryTrends, formatter),
      ],
    );
  }

  Widget _buildCategoryLineChart(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> categoryTrends,
  ) {
    if (categoryTrends.isEmpty) {
      return _buildEmptyMessage(context, 'No category data yet');
    }

    double maxY = 0;
    for (final months in categoryTrends.values) {
      for (final m in months) {
        final amount = m['amount'] as double;
        if (amount > maxY) maxY = amount;
      }
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    final categories = categoryTrends.keys.toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          maxY: maxY,
          minY: 0,
          lineTouchData: LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  // Use first category's month data for labels
                  final firstCatData = categoryTrends.values.first;
                  if (idx >= 0 && idx < firstCatData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('MMM').format(firstCatData[idx]['month'] as DateTime),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          lineBarsData: List.generate(categories.length, (catIdx) {
            final catData = categoryTrends[categories[catIdx]]!;
            return LineChartBarData(
              spots: List.generate(catData.length, (i) {
                return FlSpot(i.toDouble(), catData[i]['amount'] as double);
              }),
              isCurved: true,
              color: _categoryColors[catIdx % _categoryColors.length],
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> categoryTrends,
    NumberFormat formatter,
  ) {
    if (categoryTrends.isEmpty) return const SizedBox.shrink();

    final categories = categoryTrends.keys.toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(categories.length, (i) {
        // Sum current month total for this category
        final data = categoryTrends[categories[i]]!;
        final currentAmount = data.isNotEmpty ? data.last['amount'] as double : 0.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _categoryColors[i % _categoryColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${categories[i]} (${formatter.format(currentAmount)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }),
    );
  }

  // ── Section 3: Budget Suggestions ──

  Widget _buildBudgetSuggestionsSection(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
    NumberFormat formatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Smart Budget Suggestions', ''),
        const SizedBox(height: 12),
        if (suggestions.isEmpty)
          _buildEmptyMessage(context, 'Your budgets look great! No suggestions right now.')
        else
          ...suggestions.map((s) => _buildSuggestionCard(context, s, formatter)),
      ],
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    Map<String, dynamic> suggestion,
    NumberFormat formatter,
  ) {
    final category = suggestion['category'] as String;
    final text = suggestion['suggestion'] as String;
    final hasExistingBudget = suggestion['currentBudget'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasExistingBudget
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (hasExistingBudget ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasExistingBudget ? Icons.tune_rounded : Icons.add_circle_outline_rounded,
              color: hasExistingBudget ? Colors.orange : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            tooltip: 'Go to Budgets',
          ),
        ],
      ),
    );
  }

  // ── Section 4: Unusual Spending ──

  Widget _buildUnusualSpendingSection(
    BuildContext context,
    List<Map<String, dynamic>> alerts,
    NumberFormat formatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Unusual Spending Alerts', ''),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          _buildEmptyMessage(context, 'No unusual spending detected this month.')
        else
          ...alerts.map((a) => _buildAlertCard(context, a, formatter)),
      ],
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    Map<String, dynamic> alert,
    NumberFormat formatter,
  ) {
    final category = alert['category'] as String;
    final current = alert['currentAmount'] as double;
    final average = alert['averageAmount'] as double;
    final percentAbove = alert['percentAbove'] as double;
    final isCritical = percentAbove > 100;

    final badgeColor = isCritical ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: badgeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${percentAbove.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This month: ${formatter.format(current)}  |  Avg: ${formatter.format(average)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Helpers ──

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (subtitle.isNotEmpty) ...[
          const Spacer(),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyMessage(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 40,
            color: Colors.green.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
