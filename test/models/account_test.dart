import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/account.dart';

void main() {
  group('AccountType', () {
    test('should have 7 types', () {
      expect(AccountType.values.length, 7);
    });

    test('should have all expected types', () {
      expect(AccountType.values, contains(AccountType.wallet));
      expect(AccountType.values, contains(AccountType.bank));
      expect(AccountType.values, contains(AccountType.mobileBanking));
      expect(AccountType.values, contains(AccountType.cash));
      expect(AccountType.values, contains(AccountType.investment));
      expect(AccountType.values, contains(AccountType.savings));
      expect(AccountType.values, contains(AccountType.creditCard));
    });
  });

  group('Account', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final account = Account(
        id: 'a1',
        name: 'Main Account',
        type: AccountType.savings,
        balance: 50000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(account.id, 'a1');
      expect(account.name, 'Main Account');
      expect(account.type, AccountType.savings);
      expect(account.balance, 50000.0);
      expect(account.currency, 'BDT');
      expect(account.creditLimit, isNull);
    });

    test('should handle credit card with limit', () {
      final now = DateTime.now();
      final account = Account(
        id: 'a2',
        name: 'Credit Card',
        type: AccountType.creditCard,
        balance: -5000.0,
        currency: 'USD',
        creditLimit: 100000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(account.creditLimit, 100000.0);
      expect(account.currency, 'USD');
    });

    test('should serialize to JSON', () {
      final now = DateTime(2026, 1, 1);
      final account = Account(
        id: 'a3',
        name: 'Cash',
        type: AccountType.cash,
        balance: 1000.0,
        currency: 'EUR',
        createdAt: now,
        updatedAt: now,
      );

      final json = account.toJson();
      expect(json['id'], 'a3');
      expect(json['name'], 'Cash');
      expect(json['type'], 'cash');
      expect(json['balance'], 1000.0);
      expect(json['currency'], 'EUR');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'a4',
        'name': 'bKash',
        'type': 'mobileBanking',
        'balance': 15000,
        'currency': 'BDT',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final account = Account.fromJson(json);
      expect(account.id, 'a4');
      expect(account.name, 'bKash');
      expect(account.type, AccountType.mobileBanking);
      expect(account.balance, 15000.0);
    });

    test('should roundtrip JSON', () {
      final now = DateTime(2026, 3, 1);
      final original = Account(
        id: 'roundtrip',
        name: 'Test Account',
        type: AccountType.bank,
        balance: 25000.0,
        currency: 'GBP',
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Account.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.balance, original.balance);
      expect(restored.currency, original.currency);
    });

    test('should copyWith correctly', () {
      final now = DateTime.now();
      final account = Account(
        id: 'a5',
        name: 'Original',
        type: AccountType.savings,
        balance: 10000.0,
        createdAt: now,
        updatedAt: now,
      );

      final updated = account.copyWith(
        name: 'Updated',
        balance: 20000.0,
      );

      expect(updated.id, 'a5');
      expect(updated.name, 'Updated');
      expect(updated.balance, 20000.0);
      expect(updated.type, AccountType.savings);
    });
  });
}
