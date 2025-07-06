import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  CategoryState({
    required this.categories,
    required this.isLoading,
    this.error,
  });

  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Category> getCategoriesByType(CategoryType type) {
    return categories.where((category) => category.type == type).toList();
  }

  List<Category> getIncomeCategories() {
    return getCategoriesByType(CategoryType.income);
  }

  List<Category> getExpenseCategories() {
    return getCategoriesByType(CategoryType.expense);
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final DatabaseService _databaseService = DatabaseService();

  CategoryNotifier() : super(CategoryState(categories: [], isLoading: false));

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _databaseService.getAllCategories();
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadCategoriesByType(CategoryType type) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _databaseService.getCategoriesByType(type);
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addCategory({
    required String name,
    required CategoryType type,
    required IconData icon,
    required Color color,
  }) async {
    try {
      final category = Category(
        id: const Uuid().v4(),
        name: name,
        type: type,
        icon: icon,
        color: color,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await _databaseService.insertCategory(category);
      state = state.copyWith(
        categories: [...state.categories, category],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _databaseService.updateCategory(category);
      
      final updatedCategories = state.categories.map((c) {
        return c.id == category.id ? category : c;
      }).toList();
      
      state = state.copyWith(categories: updatedCategories, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _databaseService.deleteCategory(categoryId);
      final updatedCategories = state.categories
          .where((category) => category.id != categoryId)
          .toList();
      state = state.copyWith(categories: updatedCategories, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Category? getCategoryById(String categoryId) {
    try {
      return state.categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  Category? getCategoryByName(String name, CategoryType type) {
    try {
      return state.categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase() && category.type == type,
      );
    } catch (e) {
      return null;
    }
  }

  bool categoryExists(String name, CategoryType type) {
    return getCategoryByName(name, type) != null;
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier();
});

// Convenience providers for specific category types
final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categoryState = ref.watch(categoryProvider);
  return categoryState.getIncomeCategories();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categoryState = ref.watch(categoryProvider);
  return categoryState.getExpenseCategories();
});