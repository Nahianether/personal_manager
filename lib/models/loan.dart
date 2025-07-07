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
    );
  }

}