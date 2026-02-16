import 'package:flutter/material.dart';
import '../utils/currency_utils.dart';

class CurrencyPicker extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final bool compact;

  const CurrencyPicker({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactPicker(context);
    }
    return _buildFullPicker(context);
  }

  Widget _buildCompactPicker(BuildContext context) {
    return InkWell(
      onTap: () => _showCurrencyDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyUtils.getSymbol(selectedCurrency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              selectedCurrency,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPicker(BuildContext context) {
    return InkWell(
      onTap: () => _showCurrencyDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                CurrencyUtils.getSymbol(selectedCurrency),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Currency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$selectedCurrency - ${CurrencyUtils.getName(selectedCurrency)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CurrencySelectionDialog(
        selectedCurrency: selectedCurrency,
        onSelected: onCurrencyChanged,
      ),
    );
  }
}

class _CurrencySelectionDialog extends StatefulWidget {
  final String selectedCurrency;
  final ValueChanged<String> onSelected;

  const _CurrencySelectionDialog({
    required this.selectedCurrency,
    required this.onSelected,
  });

  @override
  State<_CurrencySelectionDialog> createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<_CurrencySelectionDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CurrencyInfo> get _filteredCurrencies {
    final currencies = CurrencyUtils.supportedCurrencies.values.toList();
    if (_searchQuery.isEmpty) return currencies;
    final query = _searchQuery.toLowerCase();
    return currencies.where((c) {
      return c.code.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query) ||
          c.symbol.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Currency'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = currency.code == widget.selectedCurrency;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    title: Text(currency.code),
                    subtitle: Text(currency.name),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      widget.onSelected(currency.code);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
