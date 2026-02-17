import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/models/calendar_event.dart';

void main() {
  group('CalendarEventType', () {
    test('should have 5 event types', () {
      expect(CalendarEventType.values.length, 5);
    });

    test('should contain all expected types', () {
      expect(CalendarEventType.values, contains(CalendarEventType.transaction));
      expect(CalendarEventType.values, contains(CalendarEventType.recurringTransaction));
      expect(CalendarEventType.values, contains(CalendarEventType.liabilityDue));
      expect(CalendarEventType.values, contains(CalendarEventType.savingsGoalDeadline));
      expect(CalendarEventType.values, contains(CalendarEventType.loanDate));
    });
  });

  group('CalendarEvent', () {
    test('should create with required fields', () {
      final event = CalendarEvent(
        id: 'test-1',
        title: 'Test Event',
        date: DateTime(2026, 1, 15),
        type: CalendarEventType.transaction,
        color: Colors.blue,
        icon: Icons.arrow_upward_rounded,
      );

      expect(event.id, 'test-1');
      expect(event.title, 'Test Event');
      expect(event.date, DateTime(2026, 1, 15));
      expect(event.type, CalendarEventType.transaction);
      expect(event.color, Colors.blue);
      expect(event.icon, Icons.arrow_upward_rounded);
      expect(event.subtitle, isNull);
      expect(event.amount, isNull);
      expect(event.currency, isNull);
    });

    test('should create with all optional fields', () {
      final event = CalendarEvent(
        id: 'test-2',
        title: 'Salary',
        subtitle: 'Monthly salary',
        date: DateTime(2026, 2, 1),
        type: CalendarEventType.recurringTransaction,
        color: Colors.purple,
        icon: Icons.repeat_rounded,
        amount: 50000.0,
        currency: 'BDT',
      );

      expect(event.subtitle, 'Monthly salary');
      expect(event.amount, 50000.0);
      expect(event.currency, 'BDT');
    });

    test('should handle different event types', () {
      final types = [
        CalendarEventType.transaction,
        CalendarEventType.recurringTransaction,
        CalendarEventType.liabilityDue,
        CalendarEventType.savingsGoalDeadline,
        CalendarEventType.loanDate,
      ];

      for (final type in types) {
        final event = CalendarEvent(
          id: 'test-${type.name}',
          title: 'Event ${type.name}',
          date: DateTime.now(),
          type: type,
          color: Colors.red,
          icon: Icons.event,
        );
        expect(event.type, type);
      }
    });

    test('should handle zero amount', () {
      final event = CalendarEvent(
        id: 'test-zero',
        title: 'Zero Amount',
        date: DateTime.now(),
        type: CalendarEventType.transaction,
        color: Colors.blue,
        icon: Icons.event,
        amount: 0.0,
        currency: 'USD',
      );

      expect(event.amount, 0.0);
    });

    test('should handle empty subtitle', () {
      final event = CalendarEvent(
        id: 'test-empty',
        title: 'Empty Sub',
        subtitle: '',
        date: DateTime.now(),
        type: CalendarEventType.transaction,
        color: Colors.blue,
        icon: Icons.event,
      );

      expect(event.subtitle, '');
    });
  });
}
