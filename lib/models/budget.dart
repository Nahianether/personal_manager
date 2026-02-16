enum BudgetPeriod { weekly, monthly, yearly }

class Budget {
  final String id;
  final String category;
  final double amount;
  final String currency;
  final BudgetPeriod period;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    this.currency = 'BDT',
    this.period = BudgetPeriod.monthly,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'BDT',
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'currency': currency,
      'period': period.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    String? currency,
    BudgetPeriod? period,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetStatus {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentage;

  BudgetStatus({
    required this.budget,
    required this.spent,
  })  : remaining = budget.amount - spent,
        percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0;

  bool get isOverBudget => percentage > 100;
  bool get isWarning => percentage >= 80 && percentage <= 100;
  bool get isNearLimit => percentage >= 60 && percentage < 80;
}
