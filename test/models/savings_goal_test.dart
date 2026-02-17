import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/savings_goal.dart';

void main() {
  group('SavingsGoal', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'sg1',
        name: 'Emergency Fund',
        targetAmount: 100000.0,
        targetDate: DateTime(2026, 12, 31),
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.id, 'sg1');
      expect(goal.name, 'Emergency Fund');
      expect(goal.targetAmount, 100000.0);
      expect(goal.currentAmount, 0.0);
      expect(goal.currency, 'BDT');
      expect(goal.priority, 'medium');
      expect(goal.isCompleted, false);
    });

    test('should calculate remaining amount', () {
      final goal = SavingsGoal(
        id: 'sg2',
        name: 'Vacation',
        targetAmount: 50000.0,
        currentAmount: 30000.0,
        targetDate: DateTime(2026, 6, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.remainingAmount, 20000.0);
    });

    test('should clamp remaining amount at 0', () {
      final goal = SavingsGoal(
        id: 'sg3',
        name: 'Overfunded',
        targetAmount: 10000.0,
        currentAmount: 15000.0,
        targetDate: DateTime(2026, 6, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.remainingAmount, 0.0);
    });

    test('should calculate progress percentage', () {
      final goal = SavingsGoal(
        id: 'sg4',
        name: 'Laptop',
        targetAmount: 100000.0,
        currentAmount: 75000.0,
        targetDate: DateTime(2026, 6, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressPercentage, 0.75);
    });

    test('should clamp progress at 1.0', () {
      final goal = SavingsGoal(
        id: 'sg5',
        name: 'Overfunded',
        targetAmount: 10000.0,
        currentAmount: 15000.0,
        targetDate: DateTime(2026, 6, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressPercentage, 1.0);
    });

    test('should handle zero target amount', () {
      final goal = SavingsGoal(
        id: 'sg6',
        name: 'Zero',
        targetAmount: 0.0,
        targetDate: DateTime(2026, 6, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressPercentage, 0.0);
    });

    test('should detect overdue goals', () {
      final goal = SavingsGoal(
        id: 'sg7',
        name: 'Overdue',
        targetAmount: 50000.0,
        targetDate: DateTime(2020, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.isOverdue, true);
    });

    test('should not be overdue if completed', () {
      final goal = SavingsGoal(
        id: 'sg8',
        name: 'Done',
        targetAmount: 50000.0,
        targetDate: DateTime(2020, 1, 1),
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.isOverdue, false);
    });

    test('should calculate days until target', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final goal = SavingsGoal(
        id: 'sg9',
        name: 'Future',
        targetAmount: 50000.0,
        targetDate: futureDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.daysUntilTarget, closeTo(30, 1));
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final goal = SavingsGoal(
        id: 'sg10',
        name: 'Car',
        targetAmount: 500000.0,
        currentAmount: 100000.0,
        currency: 'USD',
        targetDate: DateTime(2027, 1, 1),
        description: 'Save for new car',
        accountId: 'acc-1',
        priority: 'high',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = goal.toJson();
      expect(json['id'], 'sg10');
      expect(json['name'], 'Car');
      expect(json['targetAmount'], 500000.0);
      expect(json['currentAmount'], 100000.0);
      expect(json['currency'], 'USD');
      expect(json['description'], 'Save for new car');
      expect(json['accountId'], 'acc-1');
      expect(json['priority'], 'high');
      expect(json['isCompleted'], false);
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'sg11',
        'name': 'House',
        'targetAmount': 2000000,
        'currentAmount': 500000,
        'currency': 'BDT',
        'targetDate': '2028-01-01T00:00:00.000',
        'description': 'Dream house',
        'accountId': 'acc-2',
        'priority': 'high',
        'isCompleted': false,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final goal = SavingsGoal.fromJson(json);
      expect(goal.id, 'sg11');
      expect(goal.name, 'House');
      expect(goal.targetAmount, 2000000.0);
      expect(goal.currentAmount, 500000.0);
      expect(goal.description, 'Dream house');
    });

    test('should roundtrip JSON correctly', () {
      final original = SavingsGoal(
        id: 'roundtrip',
        name: 'Test Goal',
        targetAmount: 75000.0,
        currentAmount: 25000.0,
        currency: 'EUR',
        targetDate: DateTime(2027, 6, 15),
        description: 'Test description',
        priority: 'low',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final json = original.toJson();
      final restored = SavingsGoal.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.targetAmount, original.targetAmount);
      expect(restored.currentAmount, original.currentAmount);
      expect(restored.currency, original.currency);
      expect(restored.priority, original.priority);
    });

    test('should copyWith correctly', () {
      final goal = SavingsGoal(
        id: 'sg12',
        name: 'Original',
        targetAmount: 50000.0,
        targetDate: DateTime(2026, 12, 31),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = goal.copyWith(
        name: 'Updated',
        currentAmount: 10000.0,
        isCompleted: true,
      );

      expect(updated.id, 'sg12');
      expect(updated.name, 'Updated');
      expect(updated.currentAmount, 10000.0);
      expect(updated.isCompleted, true);
      expect(updated.targetAmount, 50000.0);
    });
  });
}
