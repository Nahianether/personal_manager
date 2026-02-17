import 'package:flutter/material.dart';

enum CalendarEventType {
  transaction,
  recurringTransaction,
  liabilityDue,
  savingsGoalDeadline,
  loanDate,
}

class CalendarEvent {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime date;
  final CalendarEventType type;
  final Color color;
  final IconData icon;
  final double? amount;
  final String? currency;

  CalendarEvent({
    required this.id,
    required this.title,
    this.subtitle,
    required this.date,
    required this.type,
    required this.color,
    required this.icon,
    this.amount,
    this.currency,
  });
}
