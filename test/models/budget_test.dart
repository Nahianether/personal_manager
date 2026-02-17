import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/budget.dart';

void main() {
  group('Budget', () {
    test('should create from constructor', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'b1',
        category: 'Food',
        amount: 5000.0,
        currency: 'BDT',
        period: BudgetPeriod.monthly,
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.id, 'b1');
      expect(budget.category, 'Food');
      expect(budget.amount, 5000.0);
      expect(budget.currency, 'BDT');
      expect(budget.period, BudgetPeriod.monthly);
    });

    test('should default currency to BDT', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'b2',
        category: 'Transport',
        amount: 2000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.currency, 'BDT');
    });

    test('should default period to monthly', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'b3',
        category: 'Entertainment',
        amount: 1000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.period, BudgetPeriod.monthly);
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final budget = Budget(
        id: 'b4',
        category: 'Food',
        amount: 5000.0,
        currency: 'USD',
        period: BudgetPeriod.weekly,
        createdAt: now,
        updatedAt: now,
      );

      final json = budget.toJson();
      expect(json['id'], 'b4');
      expect(json['category'], 'Food');
      expect(json['amount'], 5000.0);
      expect(json['currency'], 'USD');
      expect(json['period'], 'weekly');
      expect(json['createdAt'], now.toIso8601String());
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'b5',
        'category': 'Shopping',
        'amount': 3000,
        'currency': 'EUR',
        'period': 'yearly',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final budget = Budget.fromJson(json);
      expect(budget.id, 'b5');
      expect(budget.category, 'Shopping');
      expect(budget.amount, 3000.0);
      expect(budget.currency, 'EUR');
      expect(budget.period, BudgetPeriod.yearly);
    });

    test('should handle missing currency in JSON (defaults to BDT)', () {
      final json = {
        'id': 'b6',
        'category': 'Bills',
        'amount': 1500,
        'period': 'monthly',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final budget = Budget.fromJson(json);
      expect(budget.currency, 'BDT');
    });

    test('should copyWith correctly', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'b7',
        category: 'Food',
        amount: 5000.0,
        createdAt: now,
        updatedAt: now,
      );

      final updated = budget.copyWith(amount: 7000.0, currency: 'USD');
      expect(updated.id, 'b7');
      expect(updated.category, 'Food');
      expect(updated.amount, 7000.0);
      expect(updated.currency, 'USD');
    });

    test('should roundtrip JSON correctly', () {
      final now = DateTime(2026, 6, 15, 10, 30);
      final original = Budget(
        id: 'roundtrip',
        category: 'Health',
        amount: 2500.0,
        currency: 'GBP',
        period: BudgetPeriod.monthly,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Budget.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.category, original.category);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.period, original.period);
    });
  });

  group('BudgetPeriod', () {
    test('should have 3 periods', () {
      expect(BudgetPeriod.values.length, 3);
    });

    test('should contain weekly, monthly, yearly', () {
      expect(BudgetPeriod.values, contains(BudgetPeriod.weekly));
      expect(BudgetPeriod.values, contains(BudgetPeriod.monthly));
      expect(BudgetPeriod.values, contains(BudgetPeriod.yearly));
    });
  });

  group('BudgetStatus', () {
    test('should calculate remaining and percentage', () {
      final budget = Budget(
        id: 'bs1',
        category: 'Food',
        amount: 5000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final status = BudgetStatus(budget: budget, spent: 3000.0);
      expect(status.remaining, 2000.0);
      expect(status.percentage, 60.0);
      expect(status.isOverBudget, false);
      expect(status.isWarning, false);
      expect(status.isNearLimit, true);
    });

    test('should detect over budget', () {
      final budget = Budget(
        id: 'bs2',
        category: 'Food',
        amount: 5000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final status = BudgetStatus(budget: budget, spent: 6000.0);
      expect(status.remaining, -1000.0);
      expect(status.percentage, 120.0);
      expect(status.isOverBudget, true);
    });

    test('should detect warning zone (80-100%)', () {
      final budget = Budget(
        id: 'bs3',
        category: 'Food',
        amount: 5000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final status = BudgetStatus(budget: budget, spent: 4500.0);
      expect(status.percentage, 90.0);
      expect(status.isWarning, true);
      expect(status.isOverBudget, false);
    });

    test('should handle zero budget amount', () {
      final budget = Budget(
        id: 'bs4',
        category: 'Food',
        amount: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final status = BudgetStatus(budget: budget, spent: 0.0);
      expect(status.percentage, 0.0);
    });
  });
}
