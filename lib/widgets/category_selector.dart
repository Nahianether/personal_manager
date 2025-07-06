import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class CategorySelector extends ConsumerStatefulWidget {
  final CategoryType categoryType;
  final Category? selectedCategory;
  final Function(Category) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categoryType,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final categories = categoryState.getCategoriesByType(widget.categoryType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateCategoryDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (categoryState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (categories.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No categories found',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showCreateCategoryDialog(context),
                    child: const Text('Create first category'),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isSelected = widget.selectedCategory?.id == category.id;
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 8,
                      right: index == categories.length - 1 ? 0 : 8,
                    ),
                    child: _buildCategoryChip(category, isSelected),
                  );
                }).toList(),
              ),
            ),
          ),
        if (widget.selectedCategory != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.selectedCategory!.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.selectedCategory!.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selectedCategory!.icon,
                  color: widget.selectedCategory!.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected: ${widget.selectedCategory!.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.selectedCategory!.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChip(Category category, bool isSelected) {
    return InkWell(
      onTap: () => widget.onCategorySelected(category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? category.color.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? category.color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: isSelected 
                  ? category.color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected 
                    ? category.color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category_rounded;
    Color selectedColor = Colors.blue;

    final availableIcons = [
      Icons.category_rounded,
      Icons.restaurant_rounded,
      Icons.directions_car_rounded,
      Icons.shopping_bag_rounded,
      Icons.movie_rounded,
      Icons.receipt_rounded,
      Icons.local_hospital_rounded,
      Icons.school_rounded,
      Icons.flight_rounded,
      Icons.fitness_center_rounded,
      Icons.work_rounded,
      Icons.business_rounded,
      Icons.trending_up_rounded,
      Icons.laptop_rounded,
      Icons.card_giftcard_rounded,
      Icons.home_rounded,
      Icons.phone_rounded,
      Icons.games_rounded,
      Icons.music_note_rounded,
      Icons.sports_soccer_rounded,
    ];

    final availableColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.brown,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Create ${widget.categoryType.name.toUpperCase()} Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Icon',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((icon) {
                    final isSelected = selectedIcon == icon;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = icon),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? selectedColor.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                                ? selectedColor
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected 
                              ? selectedColor
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Color',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableColors.map((color) {
                    final isSelected = selectedColor == color;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final existingCategory = ref.read(categoryProvider.notifier)
                      .getCategoryByName(name, widget.categoryType);
                  
                  if (existingCategory != null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Category "$name" already exists'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    return;
                  }

                  await ref.read(categoryProvider.notifier).addCategory(
                    name: name,
                    type: widget.categoryType,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Category "$name" created successfully'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}