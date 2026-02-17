import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_event.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/recurring_transaction_provider.dart';
import '../providers/liability_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/loan_provider.dart';

class CalendarState {
  final Map<DateTime, List<CalendarEvent>> events;
  final DateTime focusedDay;
  final DateTime? selectedDay;

  CalendarState({
    this.events = const {},
    DateTime? focusedDay,
    this.selectedDay,
  }) : focusedDay = focusedDay ?? DateTime.now();

  CalendarState copyWith({
    Map<DateTime, List<CalendarEvent>>? events,
    DateTime? focusedDay,
    DateTime? selectedDay,
  }) {
    return CalendarState(
      events: events ?? this.events,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return events[normalized] ?? [];
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final Ref _ref;

  CalendarNotifier(this._ref) : super(CalendarState()) {
    buildEvents();
  }

  void buildEvents() {
    final Map<DateTime, List<CalendarEvent>> eventMap = {};

    void addEvent(DateTime date, CalendarEvent event) {
      final key = DateTime(date.year, date.month, date.day);
      eventMap.putIfAbsent(key, () => []).add(event);
    }

    // 1. Transactions (blue)
    final transactions = _ref.read(transactionProvider).transactions;
    for (final t in transactions) {
      addEvent(
        t.date,
        CalendarEvent(
          id: t.id,
          title: t.category ?? (t.type == TransactionType.income ? 'Income' : 'Expense'),
          subtitle: t.description,
          date: t.date,
          type: CalendarEventType.transaction,
          color: t.type == TransactionType.income ? Colors.green : Colors.blue,
          icon: t.type == TransactionType.income
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          amount: t.amount,
          currency: t.currency,
        ),
      );
    }

    // 2. Recurring transaction next due dates (purple)
    final recurringTxns = _ref.read(recurringTransactionProvider).items;
    for (final rt in recurringTxns) {
      if (!rt.isActive) continue;
      addEvent(
        rt.nextDueDate,
        CalendarEvent(
          id: rt.id,
          title: '${rt.category ?? 'Recurring'} (Due)',
          subtitle: rt.description,
          date: rt.nextDueDate,
          type: CalendarEventType.recurringTransaction,
          color: Colors.purple,
          icon: Icons.repeat_rounded,
          amount: rt.amount,
          currency: rt.currency,
        ),
      );
    }

    // 3. Liability due dates (red/orange)
    final liabilities = _ref.read(liabilityProvider).liabilities;
    for (final l in liabilities) {
      if (l.isPaid) continue;
      addEvent(
        l.dueDate,
        CalendarEvent(
          id: l.id,
          title: 'Due: ${l.personName}',
          subtitle: l.description,
          date: l.dueDate,
          type: CalendarEventType.liabilityDue,
          color: l.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.orange,
          icon: Icons.warning_rounded,
          amount: l.amount,
          currency: l.currency,
        ),
      );
    }

    // 4. Savings goal deadlines (green)
    final goals = _ref.read(savingsGoalProvider).goals;
    for (final g in goals) {
      if (g.isCompleted) continue;
      addEvent(
        g.targetDate,
        CalendarEvent(
          id: g.id,
          title: 'Goal: ${g.name}',
          subtitle: g.description,
          date: g.targetDate,
          type: CalendarEventType.savingsGoalDeadline,
          color: Colors.green,
          icon: Icons.flag_rounded,
          amount: g.targetAmount,
          currency: g.currency,
        ),
      );
    }

    // 5. Loan dates (amber)
    final loans = _ref.read(loanProvider).loans;
    for (final loan in loans) {
      if (loan.isReturned) continue;
      addEvent(
        loan.loanDate,
        CalendarEvent(
          id: loan.id,
          title: 'Loan: ${loan.personName}',
          subtitle: loan.description,
          date: loan.loanDate,
          type: CalendarEventType.loanDate,
          color: Colors.amber,
          icon: Icons.person_rounded,
          amount: loan.amount,
          currency: loan.currency,
        ),
      );
    }

    state = state.copyWith(events: eventMap);
  }

  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  void setSelectedDay(DateTime? day) {
    state = state.copyWith(selectedDay: day);
  }

  void refresh() => buildEvents();
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(ref);
});
