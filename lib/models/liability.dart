class Liability {
  final String id;
  final String name;
  final LiabilityType type;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final LiabilityStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Liability({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.currency = 'BDT',
    required this.dueDate,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Liability.fromJson(Map<String, dynamic> json) {
    return Liability(
      id: json['id'],
      name: json['name'],
      type: LiabilityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      amount: json['amount'].toDouble(),
      currency: json['currency'] ?? 'BDT',
      dueDate: DateTime.parse(json['dueDate']),
      status: LiabilityStatus.values.firstWhere(
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
      'amount': amount,
      'currency': currency,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Liability copyWith({
    String? id,
    String? name,
    LiabilityType? type,
    double? amount,
    String? currency,
    DateTime? dueDate,
    LiabilityStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Liability(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == LiabilityStatus.pending;
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}

enum LiabilityType {
  bill,
  debt,
  subscription,
  insurance,
  tax,
  other,
}

enum LiabilityStatus {
  pending,
  paid,
  overdue,
  cancelled,
}