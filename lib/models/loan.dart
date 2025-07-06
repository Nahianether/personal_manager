class Loan {
  final String id;
  final String name;
  final LoanType type;
  final double principal;
  final double interestRate;
  final double remainingAmount;
  final double totalAmount;
  final String currency;
  final DateTime startDate;
  final DateTime? endDate;
  final LoanStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.name,
    required this.type,
    required this.principal,
    required this.interestRate,
    required this.remainingAmount,
    required this.totalAmount,
    this.currency = 'BDT',
    required this.startDate,
    this.endDate,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      name: json['name'],
      type: LoanType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      principal: json['principal'].toDouble(),
      interestRate: json['interestRate'].toDouble(),
      remainingAmount: json['remainingAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      currency: json['currency'] ?? 'BDT',
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: LoanStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'principal': principal,
      'interestRate': interestRate,
      'remainingAmount': remainingAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Loan copyWith({
    String? id,
    String? name,
    LoanType? type,
    double? principal,
    double? interestRate,
    double? remainingAmount,
    double? totalAmount,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    LoanStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get interestAmount => totalAmount - principal;
  double get paidAmount => totalAmount - remainingAmount;
  double get progressPercentage => (paidAmount / totalAmount) * 100;
}

enum LoanType {
  personal,
  home,
  car,
  education,
  business,
  other,
}

enum LoanStatus {
  active,
  completed,
  defaulted,
  cancelled,
}