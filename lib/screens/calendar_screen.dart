import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/calendar_provider.dart';
import '../providers/currency_provider.dart';
import '../models/calendar_event.dart';
import '../utils/currency_utils.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    final displayCurrency = ref.watch(currencyProvider).displayCurrency;
    final formatter = CurrencyUtils.getFormatter(displayCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        actions: [
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_agenda_rounded),
            tooltip: 'Change View',
            onSelected: (format) => setState(() => _calendarFormat = format),
            itemBuilder: (context) => const [
              PopupMenuItem(value: CalendarFormat.month, child: Text('Month')),
              PopupMenuItem(
                  value: CalendarFormat.twoWeeks, child: Text('2 Weeks')),
              PopupMenuItem(value: CalendarFormat.week, child: Text('Week')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: calendarState.focusedDay,
            selectedDayPredicate: (day) =>
                isSameDay(calendarState.selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) => calendarState.getEventsForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(calendarProvider.notifier).setSelectedDay(selectedDay);
              ref.read(calendarProvider.notifier).setFocusedDay(focusedDay);
            },
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) {
              ref.read(calendarProvider.notifier).setFocusedDay(focusedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              markersMaxCount: 0, // We use custom markers
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                final uniqueTypes = events.map((e) => e.type).toSet();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: uniqueTypes.take(4).map((type) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getColorForType(type),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          _buildLegend(context),
          const Divider(height: 1),
          Expanded(
            child: _buildEventList(context, calendarState, formatter),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.transaction:
        return Colors.blue;
      case CalendarEventType.recurringTransaction:
        return Colors.purple;
      case CalendarEventType.liabilityDue:
        return Colors.red;
      case CalendarEventType.savingsGoalDeadline:
        return Colors.green;
      case CalendarEventType.loanDate:
        return Colors.amber;
    }
  }

  String _getLabelForType(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.transaction:
        return 'Transactions';
      case CalendarEventType.recurringTransaction:
        return 'Recurring';
      case CalendarEventType.liabilityDue:
        return 'Liabilities';
      case CalendarEventType.savingsGoalDeadline:
        return 'Goals';
      case CalendarEventType.loanDate:
        return 'Loans';
    }
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: CalendarEventType.values.map((type) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getColorForType(type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _getLabelForType(type),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventList(
    BuildContext context,
    CalendarState calendarState,
    dynamic formatter,
  ) {
    final events = calendarState.selectedDay != null
        ? calendarState.getEventsForDay(calendarState.selectedDay!)
        : <CalendarEvent>[];

    if (calendarState.selectedDay == null) {
      return Center(
        child: Text(
          'Select a day to view events',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: Colors.green.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No events on this day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: event.color.withValues(alpha: 0.1),
              child: Icon(event.icon, color: event.color, size: 20),
            ),
            title: Text(
              event.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: event.subtitle != null && event.subtitle!.isNotEmpty
                ? Text(
                    event.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: event.amount != null
                ? Text(
                    CurrencyUtils.formatCurrency(
                        event.amount!, event.currency ?? 'BDT'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: event.color,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
