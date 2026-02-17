import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/category.dart';

void main() {
  group('CategoryType', () {
    test('should have 2 types', () {
      expect(CategoryType.values.length, 2);
    });

    test('should contain income and expense', () {
      expect(CategoryType.values, contains(CategoryType.income));
      expect(CategoryType.values, contains(CategoryType.expense));
    });
  });

  group('Category', () {
    test('should create with required fields', () {
      final cat = Category(
        id: 'cat1',
        name: 'Food',
        type: CategoryType.expense,
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFFF5722),
        createdAt: DateTime.now(),
      );

      expect(cat.id, 'cat1');
      expect(cat.name, 'Food');
      expect(cat.type, CategoryType.expense);
      expect(cat.isDefault, false);
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final cat = Category(
        id: 'cat2',
        name: 'Salary',
        type: CategoryType.income,
        icon: Icons.work_rounded,
        color: const Color(0xFF4CAF50),
        isDefault: true,
        createdAt: now,
      );

      final json = cat.toJson();
      expect(json['id'], 'cat2');
      expect(json['name'], 'Salary');
      expect(json['type'], 'income');
      expect(json['isDefault'], true);
      expect(json['iconCodePoint'], isA<int>());
      expect(json['colorValue'], isA<int>());
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'cat3',
        'name': 'Transport',
        'type': 'expense',
        'iconCodePoint': 0xe1ba,
        'colorValue': 0xFF3F51B5,
        'isDefault': false,
        'createdAt': '2026-01-01T00:00:00.000',
      };

      final cat = Category.fromJson(json);
      expect(cat.id, 'cat3');
      expect(cat.name, 'Transport');
      expect(cat.type, CategoryType.expense);
      expect(cat.isDefault, false);
    });

    test('should copyWith correctly', () {
      final cat = Category(
        id: 'cat4',
        name: 'Original',
        type: CategoryType.expense,
        icon: Icons.category_rounded,
        color: Colors.blue,
        createdAt: DateTime.now(),
      );

      final updated = cat.copyWith(name: 'Updated', type: CategoryType.income);
      expect(updated.id, 'cat4');
      expect(updated.name, 'Updated');
      expect(updated.type, CategoryType.income);
    });
  });

  group('DefaultCategories', () {
    test('should have income categories', () {
      final income = DefaultCategories.incomeCategories;
      expect(income.isNotEmpty, true);
      for (final cat in income) {
        expect(cat.type, CategoryType.income);
        expect(cat.isDefault, true);
      }
    });

    test('should have expense categories', () {
      final expense = DefaultCategories.expenseCategories;
      expect(expense.isNotEmpty, true);
      for (final cat in expense) {
        expect(cat.type, CategoryType.expense);
        expect(cat.isDefault, true);
      }
    });

    test('should get all default categories', () {
      final all = DefaultCategories.getAllDefaultCategories();
      final income = DefaultCategories.incomeCategories;
      final expense = DefaultCategories.expenseCategories;

      expect(all.length, income.length + expense.length);
    });

    test('should have unique IDs in default categories', () {
      final all = DefaultCategories.getAllDefaultCategories();
      final ids = all.map((c) => c.id).toSet();
      expect(ids.length, all.length);
    });

    test('should have non-empty names', () {
      final all = DefaultCategories.getAllDefaultCategories();
      for (final cat in all) {
        expect(cat.name.isNotEmpty, true);
      }
    });
  });
}
