class Loan {
  final String id;
  final String personName; // Person who received the loan from you
  final double amount;
  final String currency;
  final DateTime loanDate;
  final DateTime? returnDate;
  final bool isReturned;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isHistoricalEntry; // true for past entries, false for new loans
  final String? accountId; // Account to debit/credit when giving/settling loan
  final String? transactionId; // Associated transaction ID for account operations

  Loan({
    required this.id,
    required this.personName,
    required this.amount,
    this.currency = 'BDT',
    required this.loanDate,
    this.returnDate,
    this.isReturned = false,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isHistoricalEntry = false,
    this.accountId,
    this.transactionId,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      personName: json['personName'] ?? json['borrowerName'] ?? '', // Handle legacy data
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'BDT',
      loanDate: DateTime.parse(json['loanDate']),
      returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
      isReturned: json['isReturned'] ?? false,
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
      'loanDate': loanDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'isReturned': isReturned,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isHistoricalEntry': isHistoricalEntry,
      'accountId': accountId,
      'transactionId': transactionId,
    };
  }

  Loan copyWith({
    String? id,
    String? personName,
    double? amount,
    String? currency,
    DateTime? loanDate,
    DateTime? returnDate,
    bool? isReturned,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isHistoricalEntry,
    String? accountId,
    String? transactionId,
  }) {
    return Loan(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      loanDate: loanDate ?? this.loanDate,
      returnDate: returnDate ?? this.returnDate,
      isReturned: isReturned ?? this.isReturned,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHistoricalEntry: isHistoricalEntry ?? this.isHistoricalEntry,
      accountId: accountId ?? this.accountId,
      transactionId: transactionId ?? this.transactionId,
    );
  }

}