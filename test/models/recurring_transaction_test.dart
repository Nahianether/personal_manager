import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/recurring_transaction.dart';
import 'package:personal_manager/models/transaction.dart';

void main() {
  group('RecurringFrequency', () {
    test('should have 4 frequencies', () {
      expect(RecurringFrequency.values.length, 4);
    });

    test('should contain all expected types', () {
      expect(RecurringFrequency.values, contains(RecurringFrequency.daily));
      expect(RecurringFrequency.values, contains(RecurringFrequency.weekly));
      expect(RecurringFrequency.values, contains(RecurringFrequency.monthly));
      expect(RecurringFrequency.values, contains(RecurringFrequency.yearly));
    });
  });

  group('RecurringTransaction', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final rt = RecurringTransaction(
        id: 'rt1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 500.0,
        frequency: RecurringFrequency.monthly,
        startDate: now,
        nextDueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      expect(rt.id, 'rt1');
      expect(rt.accountId, 'acc-1');
      expect(rt.type, TransactionType.expense);
      expect(rt.amount, 500.0);
      expect(rt.currency, 'BDT');
      expect(rt.isActive, true);
      expect(rt.category, isNull);
      expect(rt.description, isNull);
      expect(rt.endDate, isNull);
      expect(rt.savingsGoalId, isNull);
    });

    test('should create with all optional fields', () {
      final now = DateTime.now();
      final rt = RecurringTransaction(
        id: 'rt2',
        accountId: 'acc-2',
        type: TransactionType.income,
        amount: 50000.0,
        currency: 'USD',
        category: 'Salary',
        description: 'Monthly salary',
        frequency: RecurringFrequency.monthly,
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        nextDueDate: now.add(const Duration(days: 30)),
        isActive: true,
        savingsGoalId: 'sg-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(rt.currency, 'USD');
      expect(rt.category, 'Salary');
      expect(rt.description, 'Monthly salary');
      expect(rt.endDate, isNotNull);
      expect(rt.savingsGoalId, 'sg-1');
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final rt = RecurringTransaction(
        id: 'rt3',
        accountId: 'acc-3',
        type: TransactionType.expense,
        amount: 1000.0,
        currency: 'BDT',
        category: 'Bills',
        description: 'Electric bill',
        frequency: RecurringFrequency.monthly,
        startDate: now,
        nextDueDate: now.add(const Duration(days: 30)),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = rt.toJson();
      expect(json['id'], 'rt3');
      expect(json['accountId'], 'acc-3');
      expect(json['type'], 'expense');
      expect(json['amount'], 1000.0);
      expect(json['currency'], 'BDT');
      expect(json['category'], 'Bills');
      expect(json['frequency'], 'monthly');
      expect(json['isActive'], true);
      expect(json['endDate'], isNull);
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'rt4',
        'accountId': 'acc-4',
        'type': 'income',
        'amount': 75000,
        'currency': 'USD',
        'category': 'Salary',
        'description': 'Monthly pay',
        'frequency': 'monthly',
        'startDate': '2026-01-01T00:00:00.000',
        'nextDueDate': '2026-02-01T00:00:00.000',
        'isActive': true,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final rt = RecurringTransaction.fromJson(json);
      expect(rt.id, 'rt4');
      expect(rt.type, TransactionType.income);
      expect(rt.amount, 75000.0);
      expect(rt.frequency, RecurringFrequency.monthly);
      expect(rt.isActive, true);
    });

    test('should handle default frequency in JSON', () {
      final json = {
        'id': 'rt5',
        'accountId': 'acc-5',
        'type': 'expense',
        'amount': 100,
        'frequency': 'invalid_frequency',
        'startDate': '2026-01-01T00:00:00.000',
        'nextDueDate': '2026-02-01T00:00:00.000',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final rt = RecurringTransaction.fromJson(json);
      expect(rt.frequency, RecurringFrequency.monthly); // orElse default
    });

    test('should roundtrip JSON correctly', () {
      final now = DateTime(2026, 3, 15);
      final original = RecurringTransaction(
        id: 'roundtrip',
        accountId: 'acc-rt',
        type: TransactionType.expense,
        amount: 2500.0,
        currency: 'EUR',
        category: 'Subscription',
        description: 'Netflix',
        frequency: RecurringFrequency.monthly,
        startDate: now,
        nextDueDate: now.add(const Duration(days: 30)),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = RecurringTransaction.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.accountId, original.accountId);
      expect(restored.type, original.type);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.category, original.category);
      expect(restored.frequency, original.frequency);
    });

    test('should copyWith correctly', () {
      final now = DateTime.now();
      final rt = RecurringTransaction(
        id: 'rt6',
        accountId: 'acc-6',
        type: TransactionType.expense,
        amount: 500.0,
        frequency: RecurringFrequency.monthly,
        startDate: now,
        nextDueDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final updated = rt.copyWith(
        amount: 750.0,
        isActive: false,
        category: 'Updated Category',
      );

      expect(updated.id, 'rt6');
      expect(updated.amount, 750.0);
      expect(updated.isActive, false);
      expect(updated.category, 'Updated Category');
      expect(updated.accountId, 'acc-6');
    });

    test('should handle all frequency types', () {
      final now = DateTime.now();
      for (final freq in RecurringFrequency.values) {
        final rt = RecurringTransaction(
          id: 'rt-${freq.name}',
          accountId: 'acc',
          type: TransactionType.expense,
          amount: 100.0,
          frequency: freq,
          startDate: now,
          nextDueDate: now,
          createdAt: now,
          updatedAt: now,
        );

        final json = rt.toJson();
        final restored = RecurringTransaction.fromJson(json);
        expect(restored.frequency, freq);
      }
    });
  });
}
