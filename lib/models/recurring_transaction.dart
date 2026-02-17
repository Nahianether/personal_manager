import 'transaction.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final String accountId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String? category;
  final String? description;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;
  final bool isActive;
  final String? savingsGoalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringTransaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    this.currency = 'BDT',
    this.category,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    this.isActive = true,
    this.savingsGoalId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'],
      accountId: json['accountId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'BDT',
      category: json['category'],
      description: json['description'],
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      nextDueDate: DateTime.parse(json['nextDueDate']),
      isActive: json['isActive'] ?? true,
      savingsGoalId: json['savingsGoalId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      'frequency': frequency.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'isActive': isActive,
      'savingsGoalId': savingsGoalId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  RecurringTransaction copyWith({
    String? id,
    String? accountId,
    TransactionType? type,
    double? amount,
    String? currency,
    String? category,
    String? description,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    bool? isActive,
    String? savingsGoalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      savingsGoalId: savingsGoalId ?? this.savingsGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
