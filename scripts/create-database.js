const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  multipleStatements: true
};

async function createDatabase() {
  let connection;
  
  try {
    console.log('🔄 Connecting to MySQL server...');
    connection = await mysql.createConnection(dbConfig);
    
    console.log('🔄 Creating database...');
    await connection.execute('CREATE DATABASE IF NOT EXISTS personal_manager');
    
    console.log('🔄 Switching to personal_manager database...');
    await connection.execute('USE personal_manager');
    
    console.log('🔄 Creating users table...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        last_login TIMESTAMP NULL,
        is_active BOOLEAN DEFAULT TRUE,
        INDEX idx_email (email),
        INDEX idx_created_at (created_at)
      )
    `);
    
    console.log('🔄 Creating user_sessions table...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS user_sessions (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        token_hash VARCHAR(255) NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_token_hash (token_hash),
        INDEX idx_expires_at (expires_at)
      )
    `);
    
    console.log('🔄 Creating accounts table...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS accounts (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        name VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        balance DECIMAL(15,2) DEFAULT 0.00,
        currency VARCHAR(10) DEFAULT 'BDT',
        credit_limit DECIMAL(15,2) DEFAULT 0.00,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_type (type)
      )
    `);
    
    console.log('🔄 Creating transactions table...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS transactions (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        account_id VARCHAR(36) NOT NULL,
        type VARCHAR(50) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        currency VARCHAR(10) DEFAULT 'BDT',
        category VARCHAR(255),
        description TEXT,
        date TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_account_id (account_id),
        INDEX idx_type (type),
        INDEX idx_date (date)
      )
    `);
    
    console.log('🔄 Creating loans table...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS loans (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        person_name VARCHAR(255) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        currency VARCHAR(10) DEFAULT 'BDT',
        loan_date TIMESTAMP NOT NULL,
        return_date TIMESTAMP,
        is_returned BOOLEAN DEFAULT FALSE,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        is_historical_entry BOOLEAN DEFAULT FALSE,
        account_id VARCHAR(36),
        transaction_id VARCHAR(36),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL,
        INDEX idx_user_id (user_id),
        INDEX idx_person_name (person_name),
        INDEX idx_loan_date (loan_date),
        INDEX idx_is_returned (is_returned)
      )
    `);
    
    console.log('🔄 Creating liabilities table...');
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS liabilities (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        person_name VARCHAR(255) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        currency VARCHAR(10) DEFAULT 'BDT',
        due_date TIMESTAMP NOT NULL,
        is_paid BOOLEAN DEFAULT FALSE,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        is_historical_entry BOOLEAN DEFAULT FALSE,
        account_id VARCHAR(36),
        transaction_id VARCHAR(36),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL,
        INDEX idx_user_id (user_id),
        INDEX idx_person_name (person_name),
        INDEX idx_due_date (due_date),
        INDEX idx_is_paid (is_paid)
      )
    `);
    
    console.log('✅ Database and tables created successfully!');
    console.log('📋 Created tables:');
    console.log('   - users (authentication)');
    console.log('   - user_sessions (token management)');
    console.log('   - accounts (user accounts)');
    console.log('   - transactions (financial transactions)');
    console.log('   - loans (loan management)');
    console.log('   - liabilities (liability management)');
    
  } catch (error) {
    console.error('❌ Error creating database:', error);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

createDatabase();