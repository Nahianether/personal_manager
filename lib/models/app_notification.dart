enum NotificationType {
  liabilityDue,
  liabilityOverdue,
  budgetWarning,
  budgetExceeded,
  loanReminder,
  unusualSpending,
}

enum NotificationSeverity {
  info,
  warning,
  critical,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final NotificationSeverity severity;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });
}
