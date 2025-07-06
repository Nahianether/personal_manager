class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final double? creditLimit; // For credit cards
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'BDT',
    this.creditLimit, // Optional, only for credit cards
    required this.createdAt,
    required this.updatedAt,
  });

  // For credit cards: available credit = creditLimit - usedAmount (balance)
  double get availableCredit {
    if (type == AccountType.creditCard && creditLimit != null) {
      return creditLimit! - balance.abs();
    }
    return 0.0;
  }

  // For credit cards: used amount is stored as positive balance
  double get usedAmount {
    if (type == AccountType.creditCard) {
      return balance.abs();
    }
    return 0.0;
  }

  // For display: credit cards show available/limit, others show balance
  double get displayBalance {
    if (type == AccountType.creditCard && creditLimit != null) {
      return availableCredit;
    }
    return balance;
  }

  bool get isCreditCard => type == AccountType.creditCard;

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      type: AccountType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      balance: json['balance'].toDouble(),
      currency: json['currency'] ?? 'BDT',
      creditLimit: json['creditLimit']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'balance': balance,
      'currency': currency,
      'creditLimit': creditLimit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    double? creditLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      creditLimit: creditLimit ?? this.creditLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum AccountType {
  wallet,
  bank,
  mobileBanking,
  cash,
  investment,
  savings,
  creditCard,
}