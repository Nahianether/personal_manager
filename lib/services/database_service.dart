import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/loan.dart';
import '../models/liability.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import 'sync_service.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Helper method to get current user ID
  Future<String?> _getCurrentUserId() async {
    return await AuthService().getUserId();
  }

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
  
  // Method to reset database if it becomes corrupted or read-only
  Future<void> resetDatabase() async {
    try {
      await _database?.close();
      _database = null;
      
      String path = join(await getDatabasesPath(), 'personal_manager.db');
      await deleteDatabase(path);
      print('Database reset completed');
      
      // Reinitialize with fresh database
      _database = await _initDatabase();
      print('Database reinitialized successfully');
    } catch (e) {
      print('Error resetting database: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'personal_manager.db');
    print('Database path: $path');
    
    try {
      final db = await openDatabase(
        path,
        version: 10,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );

      // Test database write permissions
      await _testDatabaseWritePermissions(db);

      // Reset to current version
      await db.execute('PRAGMA user_version = 10');
      
      return db;
    } catch (e) {
      print('Database initialization failed: $e');
      
      // If the database is read-only or corrupted, delete and recreate
      if (e.toString().contains('readonly database') || e.toString().contains('1032')) {
        print('Database is read-only, attempting to delete and recreate...');
        
        try {
          // Close any existing connection
          await _database?.close();
          _database = null;
          
          // Delete the corrupted database file
          await deleteDatabase(path);
          print('Corrupted database deleted');
          
          // Create a fresh database
          final db = await openDatabase(
            path,
            version: 10,
            onCreate: _createTables,
            onUpgrade: _upgradeDatabase,
          );
          
          // Test write permissions again
          await _testDatabaseWritePermissions(db);
          print('New database created successfully');
          
          return db;
        } catch (recreateError) {
          print('Failed to recreate database: $recreateError');
          rethrow;
        }
      }
      
      rethrow;
    }
  }
  
  Future<void> _testDatabaseWritePermissions(Database db) async {
    try {
      // Simple write test - just try to run a pragma command that writes to the database
      await db.execute('PRAGMA user_version = 1');
      await db.execute('PRAGMA user_version = 10'); // Reset to current version
      print('Database write permissions OK');
    } catch (e) {
      print('Database write permission test failed: $e');
      throw Exception('Database is read-only or permissions issue: $e');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
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
        user_id TEXT NOT NULL,
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
        user_id TEXT NOT NULL,
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
        last_synced_at TEXT,
        is_historical_entry INTEGER NOT NULL DEFAULT 0,
        account_id TEXT,
        transaction_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE liabilities (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        due_date TEXT NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT,
        is_historical_entry INTEGER NOT NULL DEFAULT 0,
        account_id TEXT,
        transaction_id TEXT
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

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BDT',
        category TEXT,
        description TEXT,
        frequency TEXT NOT NULL DEFAULT 'monthly',
        start_date TEXT NOT NULL,
        end_date TEXT,
        next_due_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_synced_at TEXT
      )
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
    
    if (oldVersion < 7) {
      // Add new fields for loan and liability transaction tracking
      await db.execute('ALTER TABLE loans ADD COLUMN is_historical_entry INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE loans ADD COLUMN account_id TEXT');
      await db.execute('ALTER TABLE loans ADD COLUMN transaction_id TEXT');
      
      await db.execute('ALTER TABLE liabilities ADD COLUMN is_historical_entry INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE liabilities ADD COLUMN account_id TEXT');
      await db.execute('ALTER TABLE liabilities ADD COLUMN transaction_id TEXT');
    }
    
    if (oldVersion < 8) {
      // Add user_id columns to all tables for user-specific data
      await db.execute('ALTER TABLE accounts ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE transactions ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE loans ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE liabilities ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');

      // For existing data, we'll need to assign the current user ID
      final currentUserId = await AuthService().getUserId();
      if (currentUserId != null) {
        await db.execute('UPDATE accounts SET user_id = ? WHERE user_id = ""', [currentUserId]);
        await db.execute('UPDATE transactions SET user_id = ? WHERE user_id = ""', [currentUserId]);
        await db.execute('UPDATE loans SET user_id = ? WHERE user_id = ""', [currentUserId]);
        await db.execute('UPDATE liabilities SET user_id = ? WHERE user_id = ""', [currentUserId]);
      }
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          period TEXT NOT NULL DEFAULT 'monthly',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'pending',
          last_synced_at TEXT
        )
      ''');
    }

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE recurring_transactions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          account_id TEXT NOT NULL,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          currency TEXT NOT NULL DEFAULT 'BDT',
          category TEXT,
          description TEXT,
          frequency TEXT NOT NULL DEFAULT 'monthly',
          start_date TEXT NOT NULL,
          end_date TEXT,
          next_due_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'pending',
          last_synced_at TEXT
        )
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
    final userId = await _getCurrentUserId();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
    
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
    final userId = await _getCurrentUserId();
    
    await db.insert(
      'accounts',
      {
        'id': account.id,
        'user_id': userId ?? '',
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
    final userId = await _getCurrentUserId();
    
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
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [account.id, userId] : [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    // First delete all transactions associated with this account
    await db.delete(
      'transactions',
      where: userId != null ? 'account_id = ? AND user_id = ?' : 'account_id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
    );
    
    // Then delete the account
    await db.delete(
      'accounts',
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
    );
  }

  Future<List<transaction_model.Transaction>> getAllTransactions() async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
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

  Future<List<transaction_model.Transaction>> getTransactionsByAccount(String accountId) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: userId != null ? 'account_id = ? AND user_id = ?' : 'account_id = ?',
      whereArgs: userId != null ? [accountId, userId] : [accountId],
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
    final userId = await _getCurrentUserId();
    
    await db.delete(
      'transactions',
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
    );
  }

  Future<void> insertTransaction(transaction_model.Transaction transaction) async {
    try {
      final db = await database;
      final userId = await _getCurrentUserId();
      
      // First verify the account exists and belongs to the user
      final accountCheck = await db.query(
        'accounts',
        where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
        whereArgs: userId != null ? [transaction.accountId, userId] : [transaction.accountId],
      );
      
      if (accountCheck.isEmpty) {
        throw Exception('Account with ID ${transaction.accountId} does not exist or does not belong to user');
      }
      
      await db.insert(
        'transactions',
        {
          'id': transaction.id,
          'user_id': userId ?? '',
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
    } catch (e) {
      print('Error inserting transaction: $e');
      print('Transaction data: ${transaction.toJson()}');
      rethrow;
    }
  }

  Future<void> updateTransaction(transaction_model.Transaction transaction) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    await db.update(
      'transactions',
      {
        'account_id': transaction.accountId,
        'type': transaction.type.toString().split('.').last,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'category': transaction.category,
        'description': transaction.description,
        'date': transaction.date.toIso8601String(),
        'sync_status': 'pending',
      },
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [transaction.id, userId] : [transaction.id],
    );

    _triggerImmediateSync('transactions', transaction.id);
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    await db.update(
      'accounts',
      {
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [accountId, userId] : [accountId],
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
    final userId = await _getCurrentUserId();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
    
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
        'isHistoricalEntry': maps[i]['is_historical_entry'] == 1,
        'accountId': maps[i]['account_id'],
        'transactionId': maps[i]['transaction_id'],
      });
    });
  }

  Future<void> insertLoan(Loan loan) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    await db.insert(
      'loans',
      {
        'id': loan.id,
        'user_id': userId ?? '',
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
        'is_historical_entry': loan.isHistoricalEntry ? 1 : 0,
        'account_id': loan.accountId,
        'transaction_id': loan.transactionId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Trigger immediate sync if connected
    _triggerImmediateSync('loans', loan.id);
  }

  Future<void> deleteLoan(String id) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    await db.delete(
      'loans',
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
    );
  }

  Future<List<Liability>> getAllLiabilities() async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'liabilities',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
    
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
        'isHistoricalEntry': maps[i]['is_historical_entry'] == 1,
        'accountId': maps[i]['account_id'],
        'transactionId': maps[i]['transaction_id'],
      });
    });
  }

  Future<void> insertLiability(Liability liability) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    await db.insert(
      'liabilities',
      {
        'id': liability.id,
        'user_id': userId ?? '',
        'person_name': liability.personName,
        'amount': liability.amount,
        'currency': liability.currency,
        'due_date': liability.dueDate.toIso8601String(),
        'is_paid': liability.isPaid ? 1 : 0,
        'description': liability.description,
        'created_at': liability.createdAt.toIso8601String(),
        'updated_at': liability.updatedAt.toIso8601String(),
        'sync_status': 'pending',
        'is_historical_entry': liability.isHistoricalEntry ? 1 : 0,
        'account_id': liability.accountId,
        'transaction_id': liability.transactionId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Trigger immediate sync if connected
    _triggerImmediateSync('liabilities', liability.id);
  }

  Future<void> deleteLiability(String id) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    await db.delete(
      'liabilities',
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
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

  // ─── Budget operations ──────

  Future<List<Budget>> getAllBudgets() async {
    final db = await database;
    final userId = await _getCurrentUserId();

    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'category ASC',
    );

    return List.generate(maps.length, (i) {
      return Budget.fromJson({
        'id': maps[i]['id'],
        'category': maps[i]['category'],
        'amount': maps[i]['amount'],
        'period': maps[i]['period'],
        'createdAt': maps[i]['created_at'],
        'updatedAt': maps[i]['updated_at'],
      });
    });
  }

  Future<void> insertBudget(Budget budget) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    await db.insert(
      'budgets',
      {
        'id': budget.id,
        'user_id': userId ?? '',
        'category': budget.category,
        'amount': budget.amount,
        'period': budget.period.toString().split('.').last,
        'created_at': budget.createdAt.toIso8601String(),
        'updated_at': budget.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _triggerImmediateSync('budgets', budget.id);
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    await db.update(
      'budgets',
      {
        'category': budget.category,
        'amount': budget.amount,
        'period': budget.period.toString().split('.').last,
        'updated_at': budget.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [budget.id, userId] : [budget.id],
    );

    _triggerImmediateSync('budgets', budget.id);
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    await db.delete(
      'budgets',
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
    );
  }

  // ─── Recurring Transaction operations ──────

  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    final db = await database;
    final userId = await _getCurrentUserId();

    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'next_due_date ASC',
    );

    return List.generate(maps.length, (i) {
      return RecurringTransaction.fromJson({
        'id': maps[i]['id'],
        'accountId': maps[i]['account_id'],
        'type': maps[i]['type'],
        'amount': maps[i]['amount'],
        'currency': maps[i]['currency'],
        'category': maps[i]['category'],
        'description': maps[i]['description'],
        'frequency': maps[i]['frequency'],
        'startDate': maps[i]['start_date'],
        'endDate': maps[i]['end_date'],
        'nextDueDate': maps[i]['next_due_date'],
        'isActive': maps[i]['is_active'] == 1,
        'createdAt': maps[i]['created_at'],
        'updatedAt': maps[i]['updated_at'],
      });
    });
  }

  Future<void> insertRecurringTransaction(RecurringTransaction rt) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    await db.insert(
      'recurring_transactions',
      {
        'id': rt.id,
        'user_id': userId ?? '',
        'account_id': rt.accountId,
        'type': rt.type.toString().split('.').last,
        'amount': rt.amount,
        'currency': rt.currency,
        'category': rt.category,
        'description': rt.description,
        'frequency': rt.frequency.toString().split('.').last,
        'start_date': rt.startDate.toIso8601String(),
        'end_date': rt.endDate?.toIso8601String(),
        'next_due_date': rt.nextDueDate.toIso8601String(),
        'is_active': rt.isActive ? 1 : 0,
        'created_at': rt.createdAt.toIso8601String(),
        'updated_at': rt.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _triggerImmediateSync('recurring_transactions', rt.id);
  }

  Future<void> updateRecurringTransaction(RecurringTransaction rt) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    await db.update(
      'recurring_transactions',
      {
        'account_id': rt.accountId,
        'type': rt.type.toString().split('.').last,
        'amount': rt.amount,
        'currency': rt.currency,
        'category': rt.category,
        'description': rt.description,
        'frequency': rt.frequency.toString().split('.').last,
        'start_date': rt.startDate.toIso8601String(),
        'end_date': rt.endDate?.toIso8601String(),
        'next_due_date': rt.nextDueDate.toIso8601String(),
        'is_active': rt.isActive ? 1 : 0,
        'updated_at': rt.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [rt.id, userId] : [rt.id],
    );

    _triggerImmediateSync('recurring_transactions', rt.id);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final db = await database;
    final userId = await _getCurrentUserId();

    await db.delete(
      'recurring_transactions',
      where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
      whereArgs: userId != null ? [id, userId] : [id],
    );
  }

  // ─── Server-to-Local: Upsert methods (sync_status='synced') ──────

  /// Upsert account from server. Skips if local item has pending changes.
  Future<void> upsertAccountFromServer(Map<String, dynamic> data, String userId) async {
    final db = await database;
    final id = data['id']?.toString();
    if (id == null) return;

    // Check if local item has pending changes
    final existing = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existing.isNotEmpty && existing.first['sync_status'] == 'pending') {
      print('⏭️ Skipping account $id - has pending local changes');
      return;
    }

    final now = DateTime.now().toIso8601String();
    await db.insert(
      'accounts',
      {
        'id': id,
        'user_id': userId,
        'name': data['name'],
        'type': data['type']?.toString().split('.').last ?? 'wallet',
        'balance': (data['balance'] ?? 0).toDouble(),
        'currency': data['currency'] ?? 'BDT',
        'credit_limit': data['creditLimit']?.toDouble(),
        'created_at': data['createdAt'] ?? now,
        'updated_at': data['updatedAt'] ?? now,
        'sync_status': 'synced',
        'last_synced_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert transaction from server. Skips if local item has pending changes.
  Future<void> upsertTransactionFromServer(Map<String, dynamic> data, String userId) async {
    final db = await database;
    final id = data['id']?.toString();
    if (id == null) return;

    final existing = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existing.isNotEmpty && existing.first['sync_status'] == 'pending') {
      print('⏭️ Skipping transaction $id - has pending local changes');
      return;
    }

    final now = DateTime.now().toIso8601String();
    await db.insert(
      'transactions',
      {
        'id': id,
        'user_id': userId,
        'account_id': data['accountId']?.toString() ?? '',
        'type': data['type']?.toString().split('.').last ?? 'expense',
        'amount': (data['amount'] ?? 0).toDouble(),
        'currency': data['currency'] ?? 'BDT',
        'category': data['category'],
        'description': data['description'],
        'date': data['date'] ?? now,
        'created_at': data['createdAt'] ?? now,
        'sync_status': 'synced',
        'last_synced_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert loan from server. Skips if local item has pending changes.
  Future<void> upsertLoanFromServer(Map<String, dynamic> data, String userId) async {
    final db = await database;
    final id = data['id']?.toString();
    if (id == null) return;

    final existing = await db.query(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existing.isNotEmpty && existing.first['sync_status'] == 'pending') {
      print('⏭️ Skipping loan $id - has pending local changes');
      return;
    }

    final now = DateTime.now().toIso8601String();
    final isReturned = data['isReturned'];
    final isHistorical = data['isHistoricalEntry'];

    await db.insert(
      'loans',
      {
        'id': id,
        'user_id': userId,
        'person_name': data['personName'] ?? '',
        'amount': (data['amount'] ?? 0).toDouble(),
        'currency': data['currency'] ?? 'BDT',
        'loan_date': data['loanDate'] ?? now,
        'return_date': data['returnDate'],
        'is_returned': (isReturned == true || isReturned == 1) ? 1 : 0,
        'description': data['description'],
        'created_at': data['createdAt'] ?? now,
        'updated_at': data['updatedAt'] ?? now,
        'sync_status': 'synced',
        'last_synced_at': now,
        'is_historical_entry': (isHistorical == true || isHistorical == 1) ? 1 : 0,
        'account_id': data['accountId'],
        'transaction_id': data['transactionId'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert liability from server. Skips if local item has pending changes.
  Future<void> upsertLiabilityFromServer(Map<String, dynamic> data, String userId) async {
    final db = await database;
    final id = data['id']?.toString();
    if (id == null) return;

    final existing = await db.query(
      'liabilities',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existing.isNotEmpty && existing.first['sync_status'] == 'pending') {
      print('⏭️ Skipping liability $id - has pending local changes');
      return;
    }

    final now = DateTime.now().toIso8601String();
    final isPaid = data['isPaid'];
    final isHistorical = data['isHistoricalEntry'];

    await db.insert(
      'liabilities',
      {
        'id': id,
        'user_id': userId,
        'person_name': data['personName'] ?? '',
        'amount': (data['amount'] ?? 0).toDouble(),
        'currency': data['currency'] ?? 'BDT',
        'due_date': data['dueDate'] ?? now,
        'is_paid': (isPaid == true || isPaid == 1) ? 1 : 0,
        'description': data['description'],
        'created_at': data['createdAt'] ?? now,
        'updated_at': data['updatedAt'] ?? now,
        'sync_status': 'synced',
        'last_synced_at': now,
        'is_historical_entry': (isHistorical == true || isHistorical == 1) ? 1 : 0,
        'account_id': data['accountId'],
        'transaction_id': data['transactionId'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

      // Delete all budgets
      await txn.delete('budgets');

      // Delete all recurring transactions
      await txn.delete('recurring_transactions');

      // Delete all custom categories (keep default ones)
      await txn.delete('categories', where: 'is_default = 0');
    });
  }
  
  Future<void> clearAllUserData() async {
    final db = await database;
    final userId = await _getCurrentUserId();
    
    if (userId != null) {
      print('🗑️ Clearing data for user: $userId');
      await clearSpecificUserData(userId);
      print('✅ User data cleared from database');
    } else {
      print('⚠️ No user ID found, clearing all data');
      await deleteAllData();
    }
  }
  
  Future<void> clearSpecificUserData(String userId) async {
    final db = await database;
    
    print('🗑️ Clearing data for specific user: $userId');
    
    await db.transaction((txn) async {
      // Delete all user-specific data
      await txn.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('accounts', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('loans', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('liabilities', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('budgets', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('recurring_transactions', where: 'user_id = ?', whereArgs: [userId]);
    });
    
    print('✅ Specific user data cleared from database');
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