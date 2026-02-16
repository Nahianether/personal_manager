import 'transaction.dart';
import 'account.dart';
import 'loan.dart';
import 'liability.dart';

class PdfReportData {
  final String periodLabel;
  final String periodType;
  final DateTime generatedAt;

  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double totalAssets;

  final Map<String, double> expensesByCategory;
  final Map<String, double> incomesByCategory;

  final List<Transaction> transactions;
  final List<Account> accounts;

  final List<Loan> loans;
  final List<Liability> liabilities;

  final String displayCurrency;

  PdfReportData({
    required this.periodLabel,
    required this.periodType,
    required this.generatedAt,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.totalAssets,
    required this.expensesByCategory,
    required this.incomesByCategory,
    required this.transactions,
    required this.accounts,
    required this.loans,
    required this.liabilities,
    this.displayCurrency = 'BDT',
  });
}
