import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../providers/liability_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _regenerateNotifications(ref);
        },
        child: notificationState.notifications.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notificationState.notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(
                    context,
                    notificationState.notifications[index],
                  );
                },
              ),
      ),
    );
  }

  void _regenerateNotifications(WidgetRef ref) {
    final liabilities = ref.read(liabilityProvider).liabilities;
    final loans = ref.read(loanProvider).loans;
    final transactions = ref.read(transactionProvider).transactions;
    final budgetStatuses =
        ref.read(budgetProvider.notifier).getBudgetStatuses(transactions);

    ref.read(notificationProvider.notifier).generateNotifications(
          liabilities: liabilities,
          budgetStatuses: budgetStatuses,
          loans: loans,
        );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_rounded,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'All Clear!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No alerts right now.\nYou\'re on top of everything!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    final config = _getNotificationConfig(notification.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity color strip
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: config.color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          config.label,
                          style: TextStyle(
                            color: config.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.liabilityOverdue:
        return Icons.warning_rounded;
      case NotificationType.liabilityDue:
        return Icons.schedule_rounded;
      case NotificationType.budgetExceeded:
        return Icons.money_off_rounded;
      case NotificationType.budgetWarning:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.loanReminder:
        return Icons.person_rounded;
    }
  }

  _NotificationConfig _getNotificationConfig(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return _NotificationConfig(color: Colors.red, label: 'CRITICAL');
      case NotificationSeverity.warning:
        return _NotificationConfig(color: Colors.orange, label: 'WARNING');
      case NotificationSeverity.info:
        return _NotificationConfig(color: Colors.blue, label: 'INFO');
    }
  }
}

class _NotificationConfig {
  final Color color;
  final String label;

  _NotificationConfig({required this.color, required this.label});
}
