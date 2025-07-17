# Testing Setup Guide

## 🔧 Local Testing Configuration

### 1. Flutter App Configuration
The API configuration has been updated to use localhost for testing:

```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://localhost:3000';
```

### 2. Backend Configuration
The backend is configured to run on localhost:3000:

```env
# .env
PORT=3000
HOST=localhost
DATABASE_URL=postgresql://username:password@localhost/personal_manager
```

## 🚀 Setup Steps

### 1. Database Setup
```bash
# Install PostgreSQL if not already installed
# Create database
createdb personal_manager

# Run the migration
psql -d personal_manager -f migration.sql
```

### 2. Backend Setup
```bash
# Navigate to your backend directory
cd path/to/your/backend

# Install dependencies
cargo build

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials

# Run the server
cargo run
```

### 3. Flutter App Setup
```bash
# Navigate to your Flutter app directory
cd path/to/your/flutter/app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🧪 Testing

### 1. API Testing
Run the test script to verify all endpoints:
```bash
./test_auth.sh
```

### 2. Flutter App Testing
1. Launch the Flutter app
2. Try to access the app (should show signin screen)
3. Test user registration
4. Test user login
5. Test logout functionality

### 3. Manual API Testing
```bash
# Test signup
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "testpass123"
  }'

# Test signin
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

## 🔄 Production Deployment

When testing is complete, update the Flutter app configuration for production:

```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://103.51.129.29:3000';
```

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/signup` | User registration |
| POST | `/api/auth/signin` | User login |
| GET | `/api/auth/validate` | Token validation |
| POST | `/api/auth/logout` | User logout |
| POST | `/api/auth/refresh` | Token refresh |
| GET | `/health` | Health check |

## 🐛 Troubleshooting

### Common Issues:

1. **Connection Refused**: Make sure the backend server is running on port 3000
2. **Database Connection Error**: Check PostgreSQL is running and credentials are correct
3. **CORS Issues**: The backend includes CORS configuration for localhost
4. **Token Issues**: Check JWT_SECRET is properly set in .env

### Logs:
- Backend logs: Check cargo run output
- Flutter logs: Check flutter run output
- Database logs: Check PostgreSQL logs

## 🔒 Security Notes

- The JWT_SECRET in .env is for testing only
- Change all default passwords before production
- Use HTTPS in production
- Implement rate limiting for production