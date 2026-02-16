import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final IconData icon;
  final Color color;
  final bool isDefault;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: CategoryType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      icon: _getIconFromCodePoint(json['iconCodePoint']),
      color: Color(json['colorValue']),
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static IconData _getIconFromCodePoint(int codePoint) {
    // Map common icon code points to their actual IconData
    const iconMap = {
      0xe1a0: Icons.category_rounded,
      0xe56c: Icons.restaurant_rounded,
      0xe1ba: Icons.directions_car_rounded,
      0xe1cc: Icons.shopping_bag_rounded,
      0xe02c: Icons.movie_rounded,
      0xe179: Icons.receipt_rounded,
      0xe548: Icons.local_hospital_rounded,
      0xe80c: Icons.school_rounded,
      0xe539: Icons.flight_rounded,
      0xe1b7: Icons.fitness_center_rounded,
      0xe8f9: Icons.work_rounded,
      0xe0af: Icons.business_rounded,
      0xe8e6: Icons.trending_up_rounded,
      0xe31e: Icons.laptop_rounded,
      0xe8f6: Icons.card_giftcard_rounded,
      0xe91f: Icons.add_circle_rounded,
      0xe80f: Icons.home_rounded,
      0xe0cd: Icons.phone_rounded,
      0xe021: Icons.games_rounded,
      0xe3a1: Icons.music_note_rounded,
      0xe85a: Icons.sports_soccer_rounded,
      0xe837: Icons.payments_rounded,
      0xe19c: Icons.savings_rounded,
      0xe5d0: Icons.more_horiz_rounded,
    };
    
    return iconMap[codePoint] ?? Icons.category_rounded;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.toARGB32(),
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    IconData? icon,
    Color? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum CategoryType {
  income,
  expense,
}

class DefaultCategories {
  static final List<Category> incomeCategories = [
    Category(
      id: 'income_salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: Icons.work_rounded,
      color: const Color(0xFF4CAF50),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'income_business',
      name: 'Business',
      type: CategoryType.income,
      icon: Icons.business_rounded,
      color: const Color(0xFF2196F3),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'income_investment',
      name: 'Investment',
      type: CategoryType.income,
      icon: Icons.trending_up_rounded,
      color: const Color(0xFF9C27B0),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'income_freelance',
      name: 'Freelance',
      type: CategoryType.income,
      icon: Icons.laptop_rounded,
      color: const Color(0xFF00BCD4),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'income_gift',
      name: 'Gift',
      type: CategoryType.income,
      icon: Icons.card_giftcard_rounded,
      color: const Color(0xFFE91E63),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'income_other',
      name: 'Other Income',
      type: CategoryType.income,
      icon: Icons.add_circle_rounded,
      color: const Color(0xFF607D8B),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  static final List<Category> expenseCategories = [
    Category(
      id: 'expense_food',
      name: 'Food & Dining',
      type: CategoryType.expense,
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFFF5722),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_transport',
      name: 'Transportation',
      type: CategoryType.expense,
      icon: Icons.directions_car_rounded,
      color: const Color(0xFF3F51B5),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFFE91E63),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_entertainment',
      name: 'Entertainment',
      type: CategoryType.expense,
      icon: Icons.movie_rounded,
      color: const Color(0xFF9C27B0),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_bills',
      name: 'Bills & Utilities',
      type: CategoryType.expense,
      icon: Icons.receipt_rounded,
      color: const Color(0xFF795548),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_medical',
      name: 'Healthcare',
      type: CategoryType.expense,
      icon: Icons.local_hospital_rounded,
      color: const Color(0xFFF44336),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_education',
      name: 'Education',
      type: CategoryType.expense,
      icon: Icons.school_rounded,
      color: const Color(0xFF2196F3),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_travel',
      name: 'Travel',
      type: CategoryType.expense,
      icon: Icons.flight_rounded,
      color: const Color(0xFF00BCD4),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_fitness',
      name: 'Fitness & Sports',
      type: CategoryType.expense,
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFF4CAF50),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'expense_other',
      name: 'Other Expense',
      type: CategoryType.expense,
      icon: Icons.more_horiz_rounded,
      color: const Color(0xFF607D8B),
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  static List<Category> getAllDefaultCategories() {
    return [...incomeCategories, ...expenseCategories];
  }
}