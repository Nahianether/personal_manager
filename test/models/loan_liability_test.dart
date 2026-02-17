import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/loan.dart';
import 'package:personal_manager/models/liability.dart';

void main() {
  group('Loan', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final loan = Loan(
        id: 'l1',
        personName: 'John',
        amount: 10000.0,
        loanDate: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(loan.id, 'l1');
      expect(loan.personName, 'John');
      expect(loan.amount, 10000.0);
      expect(loan.currency, 'BDT');
      expect(loan.isReturned, false);
      expect(loan.returnDate, isNull);
      expect(loan.description, isNull);
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final loan = Loan(
        id: 'l2',
        personName: 'Jane',
        amount: 5000.0,
        currency: 'USD',
        loanDate: now,
        isReturned: true,
        returnDate: now.add(const Duration(days: 30)),
        description: 'Lent for groceries',
        createdAt: now,
        updatedAt: now,
      );

      final json = loan.toJson();
      expect(json['id'], 'l2');
      expect(json['personName'], 'Jane');
      expect(json['amount'], 5000.0);
      expect(json['currency'], 'USD');
      expect(json['isReturned'], true);
      expect(json['description'], 'Lent for groceries');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'l3',
        'personName': 'Bob',
        'amount': 20000,
        'currency': 'BDT',
        'loanDate': '2026-01-01T00:00:00.000',
        'isReturned': false,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final loan = Loan.fromJson(json);
      expect(loan.personName, 'Bob');
      expect(loan.amount, 20000.0);
      expect(loan.isReturned, false);
    });

    test('should roundtrip JSON', () {
      final now = DateTime(2026, 2, 15);
      final original = Loan(
        id: 'roundtrip',
        personName: 'Alice',
        amount: 15000.0,
        currency: 'EUR',
        loanDate: now,
        description: 'Emergency loan',
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Loan.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.personName, original.personName);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
    });
  });

  group('Liability', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final liability = Liability(
        id: 'lib1',
        personName: 'Mike',
        amount: 8000.0,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      expect(liability.id, 'lib1');
      expect(liability.personName, 'Mike');
      expect(liability.amount, 8000.0);
      expect(liability.currency, 'BDT');
      expect(liability.isPaid, false);
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final liability = Liability(
        id: 'lib2',
        personName: 'Sarah',
        amount: 12000.0,
        currency: 'GBP',
        dueDate: DateTime(2026, 3, 1),
        isPaid: true,
        description: 'Rent',
        createdAt: now,
        updatedAt: now,
      );

      final json = liability.toJson();
      expect(json['id'], 'lib2');
      expect(json['personName'], 'Sarah');
      expect(json['amount'], 12000.0);
      expect(json['isPaid'], true);
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'lib3',
        'personName': 'Tom',
        'amount': 5000,
        'currency': 'BDT',
        'dueDate': '2026-04-01T00:00:00.000',
        'isPaid': false,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final liability = Liability.fromJson(json);
      expect(liability.personName, 'Tom');
      expect(liability.amount, 5000.0);
      expect(liability.isPaid, false);
    });

    test('should roundtrip JSON', () {
      final now = DateTime(2026, 2, 1);
      final original = Liability(
        id: 'roundtrip',
        personName: 'Dave',
        amount: 25000.0,
        currency: 'USD',
        dueDate: DateTime(2026, 5, 1),
        description: 'Credit card payment',
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Liability.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.personName, original.personName);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
    });
  });
}
