class Liability {
  final String id;
  final String personName; // Person to whom you owe money
  final double amount;
  final String currency;
  final DateTime dueDate;
  final bool isPaid;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isHistoricalEntry; // true for past entries, false for new liabilities
  final String? accountId; // Account to debit/credit when settling liability
  final String? transactionId; // Associated transaction ID for account operations

  Liability({
    required this.id,
    required this.personName,
    required this.amount,
    this.currency = 'BDT',
    required this.dueDate,
    this.isPaid = false,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isHistoricalEntry = false,
    this.accountId,
    this.transactionId,
  });

  factory Liability.fromJson(Map<String, dynamic> json) {
    return Liability(
      id: json['id'],
      personName: json['personName'],
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'BDT',
      dueDate: DateTime.parse(json['dueDate']),
      isPaid: json['isPaid'] ?? false,
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isHistoricalEntry: json['isHistoricalEntry'] ?? false,
      accountId: json['accountId'],
      transactionId: json['transactionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'currency': currency,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isHistoricalEntry': isHistoricalEntry,
      'accountId': accountId,
      'transactionId': transactionId,
    };
  }

  Liability copyWith({
    String? id,
    String? personName,
    double? amount,
    String? currency,
    DateTime? dueDate,
    bool? isPaid,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isHistoricalEntry,
    String? accountId,
    String? transactionId,
  }) {
    return Liability(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHistoricalEntry: isHistoricalEntry ?? this.isHistoricalEntry,
      accountId: accountId ?? this.accountId,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isPaid;
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}