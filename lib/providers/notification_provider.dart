import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../models/liability.dart';
import '../models/loan.dart';
import '../models/budget.dart';
import '../utils/currency_utils.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;

  NotificationState({
    required this.notifications,
    required this.isLoading,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get count => notifications.length;

  int get criticalCount =>
      notifications.where((n) => n.severity == NotificationSeverity.critical).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier()
      : super(NotificationState(notifications: [], isLoading: false));

  void generateNotifications({
    required List<Liability> liabilities,
    required List<BudgetStatus> budgetStatuses,
    required List<Loan> loans,
  }) {
    state = state.copyWith(isLoading: true);

    final notifications = <AppNotification>[];
    final now = DateTime.now();
    int idCounter = 0;

    // 1. Overdue liabilities (CRITICAL)
    for (final liability in liabilities) {
      if (liability.isPaid) continue;

      if (liability.isOverdue) {
        final daysOverdue = now.difference(liability.dueDate).inDays;
        notifications.add(AppNotification(
          id: 'notif_${idCounter++}',
          type: NotificationType.liabilityOverdue,
          title: 'Overdue: ${liability.personName}',
          message:
              '${CurrencyUtils.formatCurrency(liability.amount, liability.currency)} to ${liability.personName} was due ${DateFormat('MMM d').format(liability.dueDate)} ($daysOverdue days ago)',
          severity: NotificationSeverity.critical,
          createdAt: now,
        ));
      } else if (liability.daysUntilDue >= 0 && liability.daysUntilDue <= 3) {
        // 2. Upcoming liabilities due within 3 days (WARNING)
        final daysText = liability.daysUntilDue == 0
            ? 'today'
            : liability.daysUntilDue == 1
                ? 'tomorrow'
                : 'in ${liability.daysUntilDue} days';
        notifications.add(AppNotification(
          id: 'notif_${idCounter++}',
          type: NotificationType.liabilityDue,
          title: 'Due Soon: ${liability.personName}',
          message:
              '${CurrencyUtils.formatCurrency(liability.amount, liability.currency)} to ${liability.personName} due $daysText',
          severity: NotificationSeverity.warning,
          createdAt: now,
        ));
      } else if (liability.daysUntilDue > 3 && liability.daysUntilDue <= 7) {
        // 3. Upcoming liabilities due within 7 days (INFO)
        notifications.add(AppNotification(
          id: 'notif_${idCounter++}',
          type: NotificationType.liabilityDue,
          title: 'Upcoming: ${liability.personName}',
          message:
              '${CurrencyUtils.formatCurrency(liability.amount, liability.currency)} to ${liability.personName} due in ${liability.daysUntilDue} days',
          severity: NotificationSeverity.info,
          createdAt: now,
        ));
      }
    }

    // 4. Budget exceeded (CRITICAL)
    for (final status in budgetStatuses) {
      if (status.isOverBudget) {
        notifications.add(AppNotification(
          id: 'notif_${idCounter++}',
          type: NotificationType.budgetExceeded,
          title: 'Budget Exceeded: ${status.budget.category}',
          message:
              'Spent ${CurrencyUtils.formatCurrency(status.spent, status.budget.currency)} of ${CurrencyUtils.formatCurrency(status.budget.amount, status.budget.currency)} ${status.budget.period.name} budget (${status.percentage.toStringAsFixed(0)}%)',
          severity: NotificationSeverity.critical,
          createdAt: now,
        ));
      } else if (status.isWarning) {
        // 5. Budget approaching limit >=80% (WARNING)
        notifications.add(AppNotification(
          id: 'notif_${idCounter++}',
          type: NotificationType.budgetWarning,
          title: 'Budget Alert: ${status.budget.category}',
          message:
              'Spent ${CurrencyUtils.formatCurrency(status.spent, status.budget.currency)} of ${CurrencyUtils.formatCurrency(status.budget.amount, status.budget.currency)} (${status.percentage.toStringAsFixed(0)}%)',
          severity: NotificationSeverity.warning,
          createdAt: now,
        ));
      }
    }

    // 6. Outstanding loans > 30 days (WARNING)
    for (final loan in loans) {
      if (loan.isReturned) continue;

      final daysSinceLoan = now.difference(loan.loanDate).inDays;
      if (daysSinceLoan > 30) {
        notifications.add(AppNotification(
          id: 'notif_${idCounter++}',
          type: NotificationType.loanReminder,
          title: 'Loan Reminder: ${loan.personName}',
          message:
              '${CurrencyUtils.formatCurrency(loan.amount, loan.currency)} lent $daysSinceLoan days ago',
          severity: NotificationSeverity.warning,
          createdAt: now,
        ));
      }
    }

    // Sort: critical first, then warning, then info
    notifications.sort((a, b) {
      final severityOrder = {
        NotificationSeverity.critical: 0,
        NotificationSeverity.warning: 1,
        NotificationSeverity.info: 2,
      };
      return severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
    });

    state = state.copyWith(notifications: notifications, isLoading: false);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
