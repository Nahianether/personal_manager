import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/category.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'personal_manager.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        credit_limit REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        category TEXT,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        principal REAL NOT NULL,
        interest_rate REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        start_date TEXT NOT NULL,
        end_date TEXT,
        status TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE liabilities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        due_date TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_account_id ON transactions(account_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions(date)
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_categories_type ON categories(type)
    ''');

    // Insert default categories
    if (version >= 2) {
      await _insertDefaultCategories(db);
    }
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          icon_code_point INTEGER NOT NULL,
          color_value INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_categories_type ON categories(type)
      ''');

      await _insertDefaultCategories(db);
    }
    
    if (oldVersion < 3) {
      // Add credit_limit column to accounts table
      await db.execute('''
        ALTER TABLE accounts ADD COLUMN credit_limit REAL
      ''');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = DefaultCategories.getAllDefaultCategories();
    for (final category in defaultCategories) {
      await db.insert(
        'categories',
        {
          'id': category.id,
          'name': category.name,
          'type': category.type.toString().split('.').last,
          'icon_code_point': category.icon.codePoint,
          'color_value': category.color.value,
          'is_default': category.isDefault ? 1 : 0,
          'created_at': category.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) {
      return Account.fromJson({
        'id': maps[i]['id'],
        'name': maps[i]['name'],
        'type': maps[i]['type'],
        'balance': maps[i]['balance'],
        'currency': maps[i]['currency'],
        'creditLimit': maps[i]['credit_limit'],
        'createdAt': maps[i]['created_at'],
        'updatedAt': maps[i]['updated_at'],
      });
    });
  }

  Future<void> insertAccount(Account account) async {
    final db = await database;
    await db.insert(
      'accounts',
      {
        'id': account.id,
        'name': account.name,
        'type': account.type.toString().split('.').last,
        'balance': account.balance,
        'currency': account.currency,
        'credit_limit': account.creditLimit,
        'created_at': account.createdAt.toIso8601String(),
        'updated_at': account.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      {
        'name': account.name,
        'type': account.type.toString().split('.').last,
        'balance': account.balance,
        'currency': account.currency,
        'credit_limit': account.creditLimit,
        'updated_at': account.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    
    // First delete all transactions associated with this account
    await db.delete(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [id],
    );
    
    // Then delete the account
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<transaction_model.Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return transaction_model.Transaction.fromJson({
        'id': maps[i]['id'],
        'accountId': maps[i]['account_id'],
        'type': maps[i]['type'],
        'amount': maps[i]['amount'],
        'currency': maps[i]['currency'],
        'category': maps[i]['category'],
        'description': maps[i]['description'],
        'date': maps[i]['date'],
        'createdAt': maps[i]['created_at'],
      });
    });
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<transaction_model.Transaction>> getTransactionsByAccount(String accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return transaction_model.Transaction.fromJson({
        'id': maps[i]['id'],
        'accountId': maps[i]['account_id'],
        'type': maps[i]['type'],
        'amount': maps[i]['amount'],
        'currency': maps[i]['currency'],
        'category': maps[i]['category'],
        'description': maps[i]['description'],
        'date': maps[i]['date'],
        'createdAt': maps[i]['created_at'],
      });
    });
  }

  Future<void> insertTransaction(transaction_model.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'account_id': transaction.accountId,
        'type': transaction.type.toString().split('.').last,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'category': transaction.category,
        'description': transaction.description,
        'date': transaction.date.toIso8601String(),
        'created_at': transaction.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final db = await database;
    await db.update(
      'accounts',
      {
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<double> getTotalBalance() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM accounts',
    );
    return result.first['total'] ?? 0.0;
  }

  Future<List<Loan>> getAllLoans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('loans');
    return List.generate(maps.length, (i) {
      return Loan.fromJson({
        'id': maps[i]['id'],
        'name': maps[i]['name'],
        'type': maps[i]['type'],
        'principal': maps[i]['principal'],
        'interestRate': maps[i]['interest_rate'],
        'remainingAmount': maps[i]['remaining_amount'],
        'totalAmount': maps[i]['total_amount'],
        'currency': maps[i]['currency'],
        'startDate': maps[i]['start_date'],
        'endDate': maps[i]['end_date'],
        'status': maps[i]['status'],
        'description': maps[i]['description'],
        'createdAt': maps[i]['created_at'],
        'updatedAt': maps[i]['updated_at'],
      });
    });
  }

  Future<void> insertLoan(Loan loan) async {
    final db = await database;
    await db.insert(
      'loans',
      {
        'id': loan.id,
        'name': loan.name,
        'type': loan.type.toString().split('.').last,
        'principal': loan.principal,
        'interest_rate': loan.interestRate,
        'remaining_amount': loan.remainingAmount,
        'total_amount': loan.totalAmount,
        'currency': loan.currency,
        'start_date': loan.startDate.toIso8601String(),
        'end_date': loan.endDate?.toIso8601String(),
        'status': loan.status.toString().split('.').last,
        'description': loan.description,
        'created_at': loan.createdAt.toIso8601String(),
        'updated_at': loan.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteLoan(String id) async {
    final db = await database;
    await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Liability>> getAllLiabilities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('liabilities');
    return List.generate(maps.length, (i) {
      return Liability.fromJson({
        'id': maps[i]['id'],
        'name': maps[i]['name'],
        'type': maps[i]['type'],
        'amount': maps[i]['amount'],
        'currency': maps[i]['currency'],
        'dueDate': maps[i]['due_date'],
        'status': maps[i]['status'],
        'description': maps[i]['description'],
        'createdAt': maps[i]['created_at'],
        'updatedAt': maps[i]['updated_at'],
      });
    });
  }

  Future<void> insertLiability(Liability liability) async {
    final db = await database;
    await db.insert(
      'liabilities',
      {
        'id': liability.id,
        'name': liability.name,
        'type': liability.type.toString().split('.').last,
        'amount': liability.amount,
        'currency': liability.currency,
        'due_date': liability.dueDate.toIso8601String(),
        'status': liability.status.toString().split('.').last,
        'description': liability.description,
        'created_at': liability.createdAt.toIso8601String(),
        'updated_at': liability.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteLiability(String id) async {
    final db = await database;
    await db.delete(
      'liabilities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category operations
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'name ASC');
    return List.generate(maps.length, (i) {
      return Category.fromJson({
        'id': maps[i]['id'],
        'name': maps[i]['name'],
        'type': maps[i]['type'],
        'iconCodePoint': maps[i]['icon_code_point'],
        'colorValue': maps[i]['color_value'],
        'isDefault': maps[i]['is_default'] == 1,
        'createdAt': maps[i]['created_at'],
      });
    });
  }

  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'is_default DESC, name ASC',
    );
    return List.generate(maps.length, (i) {
      return Category.fromJson({
        'id': maps[i]['id'],
        'name': maps[i]['name'],
        'type': maps[i]['type'],
        'iconCodePoint': maps[i]['icon_code_point'],
        'colorValue': maps[i]['color_value'],
        'isDefault': maps[i]['is_default'] == 1,
        'createdAt': maps[i]['created_at'],
      });
    });
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'type': category.type.toString().split('.').last,
        'icon_code_point': category.icon.codePoint,
        'color_value': category.color.value,
        'is_default': category.isDefault ? 1 : 0,
        'created_at': category.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'name': category.name,
        'icon_code_point': category.icon.codePoint,
        'color_value': category.color.value,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ? AND is_default = 0',
      whereArgs: [categoryId],
    );
  }

  Future<Category?> getCategoryById(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    return Category.fromJson({
      'id': maps[0]['id'],
      'name': maps[0]['name'],
      'type': maps[0]['type'],
      'iconCodePoint': maps[0]['icon_code_point'],
      'colorValue': maps[0]['color_value'],
      'isDefault': maps[0]['is_default'] == 1,
      'createdAt': maps[0]['created_at'],
    });
  }
}