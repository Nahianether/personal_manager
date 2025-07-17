const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const mysql = require('mysql2/promise');
const rateLimit = require('express-rate-limit');

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per windowMs
  message: 'Too many authentication attempts, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Database configuration
const dbConfig = {
  host: 'localhost',
  user: 'your_db_user',
  password: 'your_db_password',
  database: 'personal_manager',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// Create MySQL connection pool
const pool = mysql.createPool(dbConfig);

// JWT secret key - CHANGE THIS IN PRODUCTION
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production';
const JWT_EXPIRES_IN = '7d';

// Database initialization
async function initializeDatabase() {
  try {
    const connection = await pool.getConnection();
    
    // Create users table
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
    
    // Create user_sessions table for token management
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
    
    connection.release();
    console.log('✅ Database tables initialized successfully');
  } catch (error) {
    console.error('❌ Database initialization error:', error);
    throw error;
  }
}

// Helper function to generate UUID
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Helper function to hash password
async function hashPassword(password) {
  const saltRounds = 12;
  return await bcrypt.hash(password, saltRounds);
}

// Helper function to verify password
async function verifyPassword(password, hashedPassword) {
  return await bcrypt.compare(password, hashedPassword);
}

// Helper function to generate JWT token
function generateToken(user) {
  return jwt.sign(
    { 
      userId: user.id,
      email: user.email,
      name: user.name
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

// Helper function to verify JWT token
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

// Middleware to authenticate JWT token
async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = verifyToken(token);
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    // Check if token exists in database and is active
    const connection = await pool.getConnection();
    const [sessions] = await connection.execute(
      'SELECT * FROM user_sessions WHERE token_hash = ? AND is_active = TRUE AND expires_at > NOW()',
      [token]
    );
    connection.release();

    if (sessions.length === 0) {
      return res.status(401).json({ error: 'Token not found or expired' });
    }

    req.user = decoded;
    next();
  } catch (error) {
    console.error('❌ Token authentication error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Validation middleware
const validateSignup = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Name must be between 2 and 255 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number')
];

const validateSignin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

// Routes

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// User registration endpoint
app.post('/auth/signup', authLimiter, validateSignup, async (req, res) => {
  try {
    // Check validation results
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { name, email, password } = req.body;
    
    const connection = await pool.getConnection();
    
    try {
      // Check if user already exists
      const [existingUsers] = await connection.execute(
        'SELECT id FROM users WHERE email = ?',
        [email]
      );

      if (existingUsers.length > 0) {
        return res.status(409).json({ error: 'User with this email already exists' });
      }

      // Hash password
      const passwordHash = await hashPassword(password);
      
      // Create new user
      const userId = generateUUID();
      await connection.execute(
        'INSERT INTO users (id, name, email, password_hash) VALUES (?, ?, ?, ?)',
        [userId, name, email, passwordHash]
      );

      console.log(`✅ User registered successfully: ${email}`);
      
      res.status(201).json({
        message: 'User registered successfully',
        user: {
          id: userId,
          name,
          email
        }
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('❌ Signup error:', error);
    res.status(500).json({ error: 'Internal server error during registration' });
  }
});

// User login endpoint
app.post('/auth/signin', authLimiter, validateSignin, async (req, res) => {
  try {
    // Check validation results
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password } = req.body;
    
    const connection = await pool.getConnection();
    
    try {
      // Find user by email
      const [users] = await connection.execute(
        'SELECT id, name, email, password_hash, is_active FROM users WHERE email = ?',
        [email]
      );

      if (users.length === 0) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const user = users[0];
      
      // Check if user is active
      if (!user.is_active) {
        return res.status(401).json({ error: 'Account is deactivated' });
      }

      // Verify password
      const passwordValid = await verifyPassword(password, user.password_hash);
      if (!passwordValid) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      // Generate JWT token
      const token = generateToken(user);
      
      // Store session in database
      const sessionId = generateUUID();
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
      
      await connection.execute(
        'INSERT INTO user_sessions (id, user_id, token_hash, expires_at) VALUES (?, ?, ?, ?)',
        [sessionId, user.id, token, expiresAt]
      );

      // Update last login
      await connection.execute(
        'UPDATE users SET last_login = NOW() WHERE id = ?',
        [user.id]
      );

      console.log(`✅ User signed in successfully: ${email}`);
      
      res.json({
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        }
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('❌ Signin error:', error);
    res.status(500).json({ error: 'Internal server error during login' });
  }
});

// Token validation endpoint
app.get('/auth/validate', authenticateToken, (req, res) => {
  res.json({
    message: 'Token is valid',
    user: {
      id: req.user.userId,
      name: req.user.name,
      email: req.user.email
    }
  });
});

// User logout endpoint
app.post('/auth/logout', authenticateToken, async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    const connection = await pool.getConnection();
    
    try {
      // Deactivate the session
      await connection.execute(
        'UPDATE user_sessions SET is_active = FALSE WHERE token_hash = ?',
        [token]
      );

      console.log(`✅ User logged out successfully: ${req.user.email}`);
      
      res.json({ message: 'Logout successful' });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('❌ Logout error:', error);
    res.status(500).json({ error: 'Internal server error during logout' });
  }
});

// Get user profile endpoint
app.get('/auth/profile', authenticateToken, async (req, res) => {
  try {
    const connection = await pool.getConnection();
    
    try {
      const [users] = await connection.execute(
        'SELECT id, name, email, created_at, last_login FROM users WHERE id = ?',
        [req.user.userId]
      );

      if (users.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const user = users[0];
      
      res.json({
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          created_at: user.created_at,
          last_login: user.last_login
        }
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('❌ Profile fetch error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Clean expired sessions (run this periodically)
async function cleanExpiredSessions() {
  try {
    const connection = await pool.getConnection();
    
    try {
      const [result] = await connection.execute(
        'DELETE FROM user_sessions WHERE expires_at < NOW() OR is_active = FALSE'
      );
      
      console.log(`🧹 Cleaned ${result.affectedRows} expired sessions`);
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('❌ Error cleaning expired sessions:', error);
  }
}

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Initialize database and start server
async function startServer() {
  try {
    await initializeDatabase();
    
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
      console.log(`🚀 Authentication API server running on port ${PORT}`);
      console.log(`📋 Available endpoints:`);
      console.log(`   POST /auth/signup - User registration`);
      console.log(`   POST /auth/signin - User login`);
      console.log(`   GET  /auth/validate - Token validation`);
      console.log(`   POST /auth/logout - User logout`);
      console.log(`   GET  /auth/profile - User profile`);
      console.log(`   GET  /health - Health check`);
    });
    
    // Clean expired sessions every hour
    setInterval(cleanExpiredSessions, 60 * 60 * 1000);
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;