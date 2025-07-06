class Transaction {
  final String id;
  final String accountId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String? category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    this.currency = 'BDT',
    this.category,
    this.description,
    required this.date,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      accountId: json['accountId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'BDT',
      category: json['category'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'currency': currency,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? accountId,
    TransactionType? type,
    double? amount,
    String? currency,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum TransactionType {
  income,
  expense,
  transfer,
}

class TransactionCategory {
  static const List<String> incomeCategories = [
    'Salary',
    'Business',
    'Investment',
    'Gift',
    'Other Income',
  ];

  static const List<String> expenseCategories = [
    'Food',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills',
    'Medical',
    'Education',
    'Other Expense',
  ];
}