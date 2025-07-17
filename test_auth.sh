#!/bin/bash

# Test script for authentication endpoints
BASE_URL="http://localhost:3000"

echo "🧪 Testing Personal Manager Authentication API"
echo "=============================================="

# Test 1: Health check
echo "1. Testing health endpoint..."
curl -s "$BASE_URL/health" && echo "" || echo "❌ Health check failed"

# Test 2: User signup
echo "2. Testing user signup..."
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "testpass123"
  }')

echo "Signup response: $SIGNUP_RESPONSE"

# Extract token from signup response if successful
TOKEN=$(echo $SIGNUP_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Signup failed, no token received"
else
  echo "✅ Signup successful, token received"
  
  # Test 3: Token validation
  echo "3. Testing token validation..."
  curl -s -X GET "$BASE_URL/api/auth/validate" \
    -H "Authorization: Bearer $TOKEN" && echo "" || echo "❌ Token validation failed"
  
  # Test 4: User signin
  echo "4. Testing user signin..."
  SIGNIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/signin" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "test@example.com",
      "password": "testpass123"
    }')
  
  echo "Signin response: $SIGNIN_RESPONSE"
  
  # Test 5: Token refresh
  echo "5. Testing token refresh..."
  curl -s -X POST "$BASE_URL/api/auth/refresh" \
    -H "Authorization: Bearer $TOKEN" && echo "" || echo "❌ Token refresh failed"
  
  # Test 6: Logout
  echo "6. Testing logout..."
  curl -s -X POST "$BASE_URL/api/auth/logout" \
    -H "Authorization: Bearer $TOKEN" && echo "" || echo "❌ Logout failed"
fi

echo ""
echo "🏁 Test completed!"
echo ""
echo "💡 Usage Instructions:"
echo "1. Start your Rust backend server: cargo run"
echo "2. Run this test script: ./test_auth.sh"
echo "3. Test with your Flutter app"
echo ""
echo "🔧 To switch back to production server:"
echo "Change baseUrl in lib/config/api_config.dart to: 'http://103.51.129.29:3000'"