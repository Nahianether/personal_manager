import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/category.dart';
import 'sync_service.dart';
import 'connectivity_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Trigger immediate sync if connected
  void _triggerImmediateSync(String table, String id) {
    if (ConnectivityService.isConnected) {
      // Use Future.delayed to avoid blocking the database operation
      Future.delayed(Duration.zero, () {
        SyncService().markForSync(table, id);
      });
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'personal_manager.db');
    return await openDatabase(
      path,
      version: 6,
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
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT
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
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        loan_date TEXT NOT NULL,
        return_date TEXT,
        is_returned INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE liabilities (
        id TEXT PRIMARY KEY,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        due_date TEXT NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT
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
    
    if (oldVersion < 5) {
      // Migrate loans table to new simplified structure
      await db.execute('DROP TABLE IF EXISTS loans_backup');
      await db.execute('ALTER TABLE loans RENAME TO loans_backup');
      
      await db.execute('''
        CREATE TABLE loans (
          id TEXT PRIMARY KEY,
          person_name TEXT NOT NULL,
          amount REAL NOT NULL,
          currency TEXT NOT NULL DEFAULT 'BDT',
          loan_date TEXT NOT NULL,
          return_date TEXT,
          is_returned INTEGER NOT NULL DEFAULT 0,
          description TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Migrate existing loan data to new schema
      final oldLoans = await db.query('loans_backup');
      for (final loan in oldLoans) {
        await db.insert('loans', {
          'id': loan['id'],
          'person_name': loan['borrower_name'] ?? loan['lender_name'] ?? 'Unknown',
          'amount': loan['amount'] ?? loan['principal'] ?? loan['total_amount'] ?? 0.0,
          'currency': loan['currency'],
          'loan_date': loan['loan_date'],
          'return_date': loan['return_date'],
          'is_returned': loan['is_returned'],
          'description': loan['description'],
          'created_at': loan['created_at'],
          'updated_at': loan['updated_at'],
        });
      }
      
      // Clean up backup table
      await db.execute('DROP TABLE IF EXISTS loans_backup');
    }
    
    if (oldVersion < 6) {
      // Add sync status columns to all tables
      await db.execute('ALTER TABLE accounts ADD COLUMN sync_status TEXT NOT NULL DEFAULT "pending"');
      await db.execute('ALTER TABLE accounts ADD COLUMN last_synced_at TEXT');
      
      await db.execute('ALTER TABLE transactions ADD COLUMN sync_status TEXT NOT NULL DEFAULT "pending"');
      await db.execute('ALTER TABLE transactions ADD COLUMN last_synced_at TEXT');
      
      await db.execute('ALTER TABLE loans ADD COLUMN sync_status TEXT NOT NULL DEFAULT "pending"');
      await db.execute('ALTER TABLE loans ADD COLUMN last_synced_at TEXT');
      
      await db.execute('ALTER TABLE liabilities ADD COLUMN sync_status TEXT NOT NULL DEFAULT "pending"');
      await db.execute('ALTER TABLE liabilities ADD COLUMN last_synced_at TEXT');
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
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Trigger immediate sync if connected
    _triggerImmediateSync('accounts', account.id);
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
        'sync_status': 'pending',
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
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Trigger immediate sync if connected
    _triggerImmediateSync('transactions', transaction.id);
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
        'personName': maps[i]['person_name'] ?? maps[i]['borrower_name'] ?? maps[i]['lender_name'] ?? '',
        'amount': maps[i]['amount'],
        'currency': maps[i]['currency'],
        'loanDate': maps[i]['loan_date'],
        'returnDate': maps[i]['return_date'],
        'isReturned': maps[i]['is_returned'] == 1,
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
        'person_name': loan.personName,
        'amount': loan.amount,
        'currency': loan.currency,
        'loan_date': loan.loanDate.toIso8601String(),
        'return_date': loan.returnDate?.toIso8601String(),
        'is_returned': loan.isReturned ? 1 : 0,
        'description': loan.description,
        'created_at': loan.createdAt.toIso8601String(),
        'updated_at': loan.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Trigger immediate sync if connected
    _triggerImmediateSync('loans', loan.id);
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
        'personName': maps[i]['person_name'],
        'amount': maps[i]['amount'],
        'currency': maps[i]['currency'],
        'dueDate': maps[i]['due_date'],
        'isPaid': maps[i]['is_paid'] == 1,
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
        'person_name': liability.personName,
        'amount': liability.amount,
        'currency': liability.currency,
        'due_date': liability.dueDate.toIso8601String(),
        'is_paid': liability.isPaid ? 1 : 0,
        'description': liability.description,
        'created_at': liability.createdAt.toIso8601String(),
        'updated_at': liability.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Trigger immediate sync if connected
    _triggerImmediateSync('liabilities', liability.id);
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

  // Delete all user data from database
  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete all transactions first (due to foreign key constraint)
      await txn.delete('transactions');
      
      // Delete all accounts
      await txn.delete('accounts');
      
      // Delete all loans
      await txn.delete('loans');
      
      // Delete all liabilities
      await txn.delete('liabilities');
      
      // Delete all custom categories (keep default ones)
      await txn.delete('categories', where: 'is_default = 0');
    });
  }

  // Export all data to a structured map for Excel export
  Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await database;
    
    // Get all data from all tables
    final accounts = await db.query('accounts');
    final transactions = await db.query('transactions');
    final loans = await db.query('loans');
    final liabilities = await db.query('liabilities');
    final categories = await db.query('categories');
    
    return {
      'Accounts': accounts,
      'Transactions': transactions,
      'Loans': loans,
      'Liabilities': liabilities,
      'Categories': categories,
    };
  }

  // Import data from structured map (from Excel import)
  Future<void> importAllData(Map<String, List<Map<String, dynamic>>> data) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Clear existing data first
      await txn.delete('transactions');
      await txn.delete('accounts');
      await txn.delete('loans');
      await txn.delete('liabilities');
      await txn.delete('categories', where: 'is_default = 0');
      
      // Import accounts
      if (data['Accounts'] != null) {
        for (final account in data['Accounts']!) {
          await txn.insert('accounts', account, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      
      // Import transactions
      if (data['Transactions'] != null) {
        for (final transaction in data['Transactions']!) {
          await txn.insert('transactions', transaction, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      
      // Import loans
      if (data['Loans'] != null) {
        for (final loan in data['Loans']!) {
          await txn.insert('loans', loan, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      
      // Import liabilities
      if (data['Liabilities'] != null) {
        for (final liability in data['Liabilities']!) {
          await txn.insert('liabilities', liability, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      
      // Import custom categories only
      if (data['Categories'] != null) {
        for (final category in data['Categories']!) {
          if (category['is_default'] == 0) {
            await txn.insert('categories', category, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });
  }
}