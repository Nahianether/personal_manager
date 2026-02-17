import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/transaction.dart';

void main() {
  group('TransactionType', () {
    test('should have 3 types', () {
      expect(TransactionType.values.length, 3);
    });

    test('should contain income, expense, and transfer', () {
      expect(TransactionType.values, contains(TransactionType.income));
      expect(TransactionType.values, contains(TransactionType.expense));
      expect(TransactionType.values, contains(TransactionType.transfer));
    });
  });

  group('Transaction', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final t = Transaction(
        id: 't1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 500.0,
        date: now,
        createdAt: now,
      );

      expect(t.id, 't1');
      expect(t.accountId, 'acc-1');
      expect(t.type, TransactionType.expense);
      expect(t.amount, 500.0);
      expect(t.currency, 'BDT');
      expect(t.category, isNull);
      expect(t.description, isNull);
    });

    test('should create with all fields', () {
      final now = DateTime.now();
      final t = Transaction(
        id: 't2',
        accountId: 'acc-2',
        type: TransactionType.income,
        amount: 50000.0,
        currency: 'USD',
        category: 'Salary',
        description: 'Monthly salary',
        date: now,
        createdAt: now,
      );

      expect(t.currency, 'USD');
      expect(t.category, 'Salary');
      expect(t.description, 'Monthly salary');
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final t = Transaction(
        id: 't3',
        accountId: 'acc-3',
        type: TransactionType.expense,
        amount: 1500.0,
        currency: 'BDT',
        category: 'Food',
        description: 'Lunch',
        date: now,
        createdAt: now,
      );

      final json = t.toJson();
      expect(json['id'], 't3');
      expect(json['accountId'], 'acc-3');
      expect(json['type'], 'expense');
      expect(json['amount'], 1500.0);
      expect(json['currency'], 'BDT');
      expect(json['category'], 'Food');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 't4',
        'accountId': 'acc-4',
        'type': 'income',
        'amount': 75000,
        'currency': 'EUR',
        'category': 'Freelance',
        'description': 'Web project',
        'date': '2026-01-15T00:00:00.000',
        'createdAt': '2026-01-15T00:00:00.000',
      };

      final t = Transaction.fromJson(json);
      expect(t.id, 't4');
      expect(t.type, TransactionType.income);
      expect(t.amount, 75000.0);
      expect(t.currency, 'EUR');
    });

    test('should roundtrip JSON', () {
      final now = DateTime(2026, 5, 20);
      final original = Transaction(
        id: 'roundtrip',
        accountId: 'acc-rt',
        type: TransactionType.expense,
        amount: 3500.0,
        currency: 'GBP',
        category: 'Shopping',
        description: 'Clothes',
        date: now,
        createdAt: now,
      );

      final json = original.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.accountId, original.accountId);
      expect(restored.type, original.type);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.category, original.category);
      expect(restored.description, original.description);
    });

    test('should copyWith correctly', () {
      final now = DateTime.now();
      final t = Transaction(
        id: 't5',
        accountId: 'acc-5',
        type: TransactionType.expense,
        amount: 500.0,
        date: now,
        createdAt: now,
      );

      final updated = t.copyWith(
        amount: 750.0,
        category: 'Food',
        currency: 'USD',
      );

      expect(updated.id, 't5');
      expect(updated.amount, 750.0);
      expect(updated.category, 'Food');
      expect(updated.currency, 'USD');
      expect(updated.accountId, 'acc-5');
    });

    test('should handle null optional fields in JSON', () {
      final json = {
        'id': 't6',
        'accountId': 'acc-6',
        'type': 'expense',
        'amount': 100,
        'date': '2026-01-01T00:00:00.000',
        'createdAt': '2026-01-01T00:00:00.000',
      };

      final t = Transaction.fromJson(json);
      expect(t.category, isNull);
      expect(t.description, isNull);
      expect(t.currency, 'BDT');
    });
  });
}
