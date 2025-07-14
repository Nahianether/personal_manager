# API Testing Guide for VPS Backend

## 🔧 **Correct curl Commands for Your App**

Based on your Flutter app models, here are the correct API testing commands:

## 📊 **1. Test API Health Check**

```bash
# Test if your VPS API is running
curl -X GET http://103.51.129.29:3000/health

# Or test root endpoint
curl -X GET http://103.51.129.29:3000/
```

## 💳 **2. Create an Account First** 

```bash
# Create a test account (REQUIRED before transactions)
curl -X POST http://103.51.129.29:3000/accounts \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-account-123",
    "name": "Test Bank Account",
    "type": "bank",
    "balance": 1000.0,
    "currency": "BDT",
    "createdAt": "2025-07-13T10:00:00.000Z",
    "updatedAt": "2025-07-13T10:00:00.000Z"
  }'
```

### **Valid Account Types:**
- `wallet` - Digital Wallet
- `bank` - Bank Account  
- `mobileBanking` - Mobile Banking
- `cash` - Cash
- `investment` - Investment
- `savings` - Savings Account
- `creditCard` - Credit Card

## 💰 **3. Create a Transaction**

```bash
# Create a test transaction (after account exists)
curl -X POST http://103.51.129.29:3000/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-transaction-123",
    "accountId": "test-account-123",
    "type": "income",
    "amount": 100.0,
    "currency": "BDT",
    "category": "Salary",
    "description": "Test income transaction",
    "date": "2025-07-13T10:00:00.000Z",
    "createdAt": "2025-07-13T10:00:00.000Z"
  }'
```

### **Valid Transaction Types:**
- `income` - Money coming in
- `expense` - Money going out  
- `transfer` - Money between accounts

## 💸 **4. Create a Loan**

```bash
# Create a test loan
curl -X POST http://103.51.129.29:3000/loans \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-loan-123",
    "personName": "John Doe",
    "amount": 5000.0,
    "currency": "BDT",
    "loanDate": "2025-07-13T10:00:00.000Z",
    "returnDate": null,
    "isReturned": false,
    "description": "Personal loan to John",
    "createdAt": "2025-07-13T10:00:00.000Z",
    "updatedAt": "2025-07-13T10:00:00.000Z",
    "isHistoricalEntry": false,
    "accountId": "test-account-123",
    "transactionId": null
  }'
```

## 📋 **5. Create a Liability**

```bash
# Create a test liability
curl -X POST http://103.51.129.29:3000/liabilities \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-liability-123",
    "personName": "ABC Company",
    "amount": 2000.0,
    "currency": "BDT",
    "dueDate": "2025-08-13T10:00:00.000Z",
    "isPaid": false,
    "description": "Invoice payment due",
    "createdAt": "2025-07-13T10:00:00.000Z",
    "updatedAt": "2025-07-13T10:00:00.000Z",
    "isHistoricalEntry": true,
    "accountId": "test-account-123",
    "transactionId": null
  }'
```

## 🔍 **6. Read Data (GET Requests)**

```bash
# Get all accounts
curl -X GET http://103.51.129.29:3000/accounts

# Get all transactions  
curl -X GET http://103.51.129.29:3000/transactions

# Get all loans
curl -X GET http://103.51.129.29:3000/loans

# Get all liabilities
curl -X GET http://103.51.129.29:3000/liabilities
```

## 🛠️ **Troubleshooting Common Issues**

### **Issue 1: 500 Internal Server Error**
**Cause:** Missing required fields or foreign key violations

**Solutions:**
1. ✅ Create account first before transactions
2. ✅ Use correct field names and types
3. ✅ Check date format: `"2025-07-13T10:00:00.000Z"`
4. ✅ Ensure all required fields are present

### **Issue 2: Foreign Key Constraint**
**Cause:** Transaction references non-existent account

**Solution:**
```bash
# Always create account first
curl -X POST http://103.51.129.29:3000/accounts -H "Content-Type: application/json" -d '{"id":"acc-1","name":"Test","type":"bank","balance":0,"currency":"BDT","createdAt":"2025-07-13T10:00:00.000Z","updatedAt":"2025-07-13T10:00:00.000Z"}'

# Then create transaction
curl -X POST http://103.51.129.29:3000/transactions -H "Content-Type: application/json" -d '{"id":"txn-1","accountId":"acc-1","type":"income","amount":100,"currency":"BDT","date":"2025-07-13T10:00:00.000Z","createdAt":"2025-07-13T10:00:00.000Z"}'
```

### **Issue 3: Date Format Error**
**Cause:** Incorrect date format

**Correct Format:** `"2025-07-13T10:00:00.000Z"`
**Wrong Formats:** 
- ❌ `"2025-07-13T10:00:00Z"` (missing milliseconds)
- ❌ `"2025-07-13 10:00:00"` (missing T and Z)

## 🧪 **Quick Test Sequence**

Run these commands in order to test your API:

```bash
# 1. Health check
curl http://103.51.129.29:3000/

# 2. Create account
curl -X POST http://103.51.129.29:3000/accounts \
  -H "Content-Type: application/json" \
  -d '{"id":"acc-test","name":"Test Account","type":"bank","balance":1000,"currency":"BDT","createdAt":"2025-07-13T10:00:00.000Z","updatedAt":"2025-07-13T10:00:00.000Z"}'

# 3. Create transaction
curl -X POST http://103.51.129.29:3000/transactions \
  -H "Content-Type: application/json" \
  -d '{"id":"txn-test","accountId":"acc-test","type":"income","amount":500,"currency":"BDT","category":"Test","description":"Test transaction","date":"2025-07-13T10:00:00.000Z","createdAt":"2025-07-13T10:00:00.000Z"}'

# 4. Verify data
curl http://103.51.129.29:3000/accounts
curl http://103.51.129.29:3000/transactions
```

## 🔒 **Security Notes**

- Your API currently has no authentication
- Consider adding API keys or JWT tokens for production
- Ensure your VPS firewall allows port 3000
- Consider using HTTPS in production

## 📊 **Expected Responses**

**Success (201 Created):**
```json
{
  "id": "test-account-123",
  "name": "Test Bank Account",
  "type": "bank",
  "balance": 1000,
  "currency": "BDT",
  "createdAt": "2025-07-13T10:00:00.000Z",
  "updatedAt": "2025-07-13T10:00:00.000Z"
}
```

**Error (500 Internal Server Error):**
```json
{
  "error": "Internal Server Error",
  "message": "Database constraint violation"
}
```

Try these commands and let me know the results! 🚀