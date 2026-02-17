import 'package:flutter_test/flutter_test.dart';
import 'package:personal_manager/providers/calendar_provider.dart';
import 'package:personal_manager/models/calendar_event.dart';
import 'package:flutter/material.dart';

void main() {
  group('CalendarState', () {
    test('should create with default values', () {
      final state = CalendarState();

      expect(state.events, isEmpty);
      expect(state.focusedDay.day, DateTime.now().day);
      expect(state.selectedDay, isNull);
    });

    test('should create with custom focused day', () {
      final day = DateTime(2026, 6, 15);
      final state = CalendarState(focusedDay: day);

      expect(state.focusedDay, day);
    });

    test('should return empty list for day with no events', () {
      final state = CalendarState();
      final events = state.getEventsForDay(DateTime(2026, 3, 15));
      expect(events, isEmpty);
    });

    test('should return events for day with events', () {
      final day = DateTime(2026, 3, 15);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final event = CalendarEvent(
        id: 'e1',
        title: 'Test',
        date: day,
        type: CalendarEventType.transaction,
        color: Colors.blue,
        icon: Icons.event,
      );

      final state = CalendarState(events: {
        normalizedDay: [event],
      });

      final events = state.getEventsForDay(day);
      expect(events.length, 1);
      expect(events.first.id, 'e1');
    });

    test('should normalize dates when getting events', () {
      final normalizedDay = DateTime(2026, 3, 15);
      final event = CalendarEvent(
        id: 'e2',
        title: 'Test',
        date: normalizedDay,
        type: CalendarEventType.transaction,
        color: Colors.blue,
        icon: Icons.event,
      );

      final state = CalendarState(events: {
        normalizedDay: [event],
      });

      // Even with time component, should find the event
      final dayWithTime = DateTime(2026, 3, 15, 14, 30, 45);
      final events = state.getEventsForDay(dayWithTime);
      expect(events.length, 1);
    });

    test('should return multiple events for same day', () {
      final day = DateTime(2026, 3, 15);
      final events = [
        CalendarEvent(
          id: 'e3',
          title: 'Event 1',
          date: day,
          type: CalendarEventType.transaction,
          color: Colors.blue,
          icon: Icons.event,
        ),
        CalendarEvent(
          id: 'e4',
          title: 'Event 2',
          date: day,
          type: CalendarEventType.liabilityDue,
          color: Colors.red,
          icon: Icons.warning,
        ),
        CalendarEvent(
          id: 'e5',
          title: 'Event 3',
          date: day,
          type: CalendarEventType.savingsGoalDeadline,
          color: Colors.green,
          icon: Icons.flag,
        ),
      ];

      final state = CalendarState(events: {day: events});
      expect(state.getEventsForDay(day).length, 3);
    });

    test('should copyWith events', () {
      final state = CalendarState();
      final day = DateTime(2026, 3, 15);
      final event = CalendarEvent(
        id: 'e6',
        title: 'Test',
        date: day,
        type: CalendarEventType.transaction,
        color: Colors.blue,
        icon: Icons.event,
      );

      final updated = state.copyWith(events: {
        day: [event],
      });

      expect(updated.events.length, 1);
      expect(state.events.length, 0); // original unchanged
    });

    test('should copyWith focused day', () {
      final state = CalendarState();
      final newDay = DateTime(2026, 6, 1);
      final updated = state.copyWith(focusedDay: newDay);

      expect(updated.focusedDay, newDay);
    });

    test('should copyWith selected day', () {
      final state = CalendarState();
      final newDay = DateTime(2026, 6, 1);
      final updated = state.copyWith(selectedDay: newDay);

      expect(updated.selectedDay, newDay);
    });

    test('should handle events on different days independently', () {
      final day1 = DateTime(2026, 3, 15);
      final day2 = DateTime(2026, 3, 16);

      final event1 = CalendarEvent(
        id: 'e7',
        title: 'Day 1 Event',
        date: day1,
        type: CalendarEventType.transaction,
        color: Colors.blue,
        icon: Icons.event,
      );

      final event2 = CalendarEvent(
        id: 'e8',
        title: 'Day 2 Event',
        date: day2,
        type: CalendarEventType.loanDate,
        color: Colors.amber,
        icon: Icons.person,
      );

      final state = CalendarState(events: {
        day1: [event1],
        day2: [event2],
      });

      expect(state.getEventsForDay(day1).length, 1);
      expect(state.getEventsForDay(day1).first.id, 'e7');
      expect(state.getEventsForDay(day2).length, 1);
      expect(state.getEventsForDay(day2).first.id, 'e8');
    });
  });
}
