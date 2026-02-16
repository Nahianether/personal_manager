import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_config.dart';
import '../providers/dashboard_config_provider.dart';

class DashboardCustomizationScreen extends ConsumerStatefulWidget {
  const DashboardCustomizationScreen({super.key});

  @override
  ConsumerState<DashboardCustomizationScreen> createState() =>
      _DashboardCustomizationScreenState();
}

class _DashboardCustomizationScreenState
    extends ConsumerState<DashboardCustomizationScreen> {
  late List<DashboardSectionConfig> _sections;

  @override
  void initState() {
    super.initState();
    _sections = List.from(
      ref.read(dashboardConfigProvider).config.sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Drag to reorder. Toggle to show or hide.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _sections.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final config = _sections[index];
                return _buildSectionTile(config, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile(DashboardSectionConfig config, int index) {
    final isVisible = config.isVisible;

    return Container(
      key: ValueKey(config.section.name),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isVisible
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSectionIcon(config.section),
            color: isVisible
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          config.section.label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: isVisible
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isVisible,
              onChanged: (_) => _toggleVisibility(index),
            ),
            Icon(
              Icons.drag_handle_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSectionIcon(DashboardSection section) {
    switch (section) {
      case DashboardSection.totalBalance:
        return Icons.account_balance_wallet_rounded;
      case DashboardSection.quickActions:
        return Icons.flash_on_rounded;
      case DashboardSection.budgetStatus:
        return Icons.pie_chart_rounded;
      case DashboardSection.incomeExpenseChart:
        return Icons.bar_chart_rounded;
      case DashboardSection.overviewCards:
        return Icons.dashboard_rounded;
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, item);
    });
    ref.read(dashboardConfigProvider.notifier).updateConfig(
          DashboardConfig(sections: List.from(_sections)),
        );
  }

  void _toggleVisibility(int index) {
    setState(() {
      _sections[index] = _sections[index].copyWith(
        isVisible: !_sections[index].isVisible,
      );
    });
    ref.read(dashboardConfigProvider.notifier).updateConfig(
          DashboardConfig(sections: List.from(_sections)),
        );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Dashboard'),
        content: const Text(
          'This will restore the default section order and visibility. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final defaults = DashboardConfig.defaultConfig();
              setState(() => _sections = List.from(defaults.sections));
              ref
                  .read(dashboardConfigProvider.notifier)
                  .resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
