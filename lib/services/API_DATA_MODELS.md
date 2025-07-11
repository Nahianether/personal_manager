# API Data Models - JSON Structures

This document shows the exact JSON data structures that your Flutter app will send to your Rust backend.

## 🏦 Account Data Structure

### Single Account (POST /accounts)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "My Bank Account",
  "type": "bank",
  "balance": 15000.50,
  "currency": "BDT",
  "creditLimit": null,
  "createdAt": "2025-07-08T14:30:00.000Z",
  "updatedAt": "2025-07-08T14:30:00.000Z"
}
```

### Credit Card Account
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "name": "My Credit Card",
  "type": "creditCard",
  "balance": 2500.00,
  "currency": "BDT",
  "creditLimit": 50000.00,
  "createdAt": "2025-07-08T14:30:00.000Z",
  "updatedAt": "2025-07-08T14:30:00.000Z"
}
```

### Account Types Enum:
- `wallet`
- `bank`
- `mobileBanking`
- `cash`
- `investment`
- `savings`
- `creditCard`

### Batch Accounts (POST /accounts/batch)
```json
{
  "accounts": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "My Bank Account",
      "type": "bank",
      "balance": 15000.50,
      "currency": "BDT",
      "creditLimit": null,
      "createdAt": "2025-07-08T14:30:00.000Z",
      "updatedAt": "2025-07-08T14:30:00.000Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "My Wallet",
      "type": "wallet",
      "balance": 500.00,
      "currency": "BDT",
      "creditLimit": null,
      "createdAt": "2025-07-08T14:30:00.000Z",
      "updatedAt": "2025-07-08T14:30:00.000Z"
    }
  ]
}
```

## 💳 Transaction Data Structure

### Single Transaction (POST /transactions)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440010",
  "accountId": "550e8400-e29b-41d4-a716-446655440000",
  "type": "expense",
  "amount": 250.00,
  "currency": "BDT",
  "category": "Food",
  "description": "Lunch at restaurant",
  "date": "2025-07-08T12:00:00.000Z",
  "createdAt": "2025-07-08T14:30:00.000Z"
}
```

### Transaction Types Enum:
- `income`
- `expense`
- `transfer`

### Batch Transactions (POST /transactions/batch)
```json
{
  "transactions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
      "accountId": "550e8400-e29b-41d4-a716-446655440000",
      "type": "expense",
      "amount": 250.00,
      "currency": "BDT",
      "category": "Food",
      "description": "Lunch at restaurant",
      "date": "2025-07-08T12:00:00.000Z",
      "createdAt": "2025-07-08T14:30:00.000Z"
    }
  ]
}
```

## 💰 Loan Data Structure

### Single Loan (POST /loans)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440020",
  "personName": "John Doe",
  "amount": 5000.00,
  "currency": "BDT",
  "loanDate": "2025-07-01T00:00:00.000Z",
  "returnDate": "2025-08-01T00:00:00.000Z",
  "isReturned": false,
  "description": "Personal loan to friend",
  "createdAt": "2025-07-08T14:30:00.000Z",
  "updatedAt": "2025-07-08T14:30:00.000Z"
}
```

### Batch Loans (POST /loans/batch)
```json
{
  "loans": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440020",
      "personName": "John Doe",
      "amount": 5000.00,
      "currency": "BDT",
      "loanDate": "2025-07-01T00:00:00.000Z",
      "returnDate": "2025-08-01T00:00:00.000Z",
      "isReturned": false,
      "description": "Personal loan to friend",
      "createdAt": "2025-07-08T14:30:00.000Z",
      "updatedAt": "2025-07-08T14:30:00.000Z"
    }
  ]
}
```

## 💸 Liability Data Structure

### Single Liability (POST /liabilities)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440030",
  "personName": "Jane Smith",
  "amount": 2000.00,
  "currency": "BDT",
  "dueDate": "2025-07-15T00:00:00.000Z",
  "isPaid": false,
  "description": "Money borrowed from friend",
  "createdAt": "2025-07-08T14:30:00.000Z",
  "updatedAt": "2025-07-08T14:30:00.000Z"
}
```

### Batch Liabilities (POST /liabilities/batch)
```json
{
  "liabilities": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440030",
      "personName": "Jane Smith",
      "amount": 2000.00,
      "currency": "BDT",
      "dueDate": "2025-07-15T00:00:00.000Z",
      "isPaid": false,
      "description": "Money borrowed from friend",
      "createdAt": "2025-07-08T14:30:00.000Z",
      "updatedAt": "2025-07-08T14:30:00.000Z"
    }
  ]
}
```

## 🛠️ Rust Backend Models

Based on these JSON structures, your Rust backend should have these models:

### Account Model (Rust)
```rust
#[derive(Serialize, Deserialize, Debug)]
pub struct Account {
    pub id: String,
    pub name: String,
    pub account_type: String, // "bank", "wallet", "creditCard", etc.
    pub balance: f64,
    pub currency: String,
    pub credit_limit: Option<f64>,
    pub created_at: String, // ISO 8601 date string
    pub updated_at: String, // ISO 8601 date string
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BatchAccounts {
    pub accounts: Vec<Account>,
}
```

### Transaction Model (Rust)
```rust
#[derive(Serialize, Deserialize, Debug)]
pub struct Transaction {
    pub id: String,
    pub account_id: String,
    pub transaction_type: String, // "income", "expense", "transfer"
    pub amount: f64,
    pub currency: String,
    pub category: Option<String>,
    pub description: Option<String>,
    pub date: String, // ISO 8601 date string
    pub created_at: String, // ISO 8601 date string
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BatchTransactions {
    pub transactions: Vec<Transaction>,
}
```

### Loan Model (Rust)
```rust
#[derive(Serialize, Deserialize, Debug)]
pub struct Loan {
    pub id: String,
    pub person_name: String,
    pub amount: f64,
    pub currency: String,
    pub loan_date: String, // ISO 8601 date string
    pub return_date: Option<String>, // ISO 8601 date string
    pub is_returned: bool,
    pub description: Option<String>,
    pub created_at: String, // ISO 8601 date string
    pub updated_at: String, // ISO 8601 date string
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BatchLoans {
    pub loans: Vec<Loan>,
}
```

### Liability Model (Rust)
```rust
#[derive(Serialize, Deserialize, Debug)]
pub struct Liability {
    pub id: String,
    pub person_name: String,
    pub amount: f64,
    pub currency: String,
    pub due_date: String, // ISO 8601 date string
    pub is_paid: bool,
    pub description: Option<String>,
    pub created_at: String, // ISO 8601 date string
    pub updated_at: String, // ISO 8601 date string
}

#[derive(Serialize, Deserialize, Debug)]
pub struct BatchLiabilities {
    pub liabilities: Vec<Liability>,
}
```

## 📝 Important Notes

1. **Date Format**: All dates are ISO 8601 strings (e.g., "2025-07-08T14:30:00.000Z")
2. **IDs**: UUIDs as strings
3. **Currency**: Default is "BDT" but can be changed
4. **Optional Fields**: Some fields can be `null`/`None`
5. **Enums**: Account types and transaction types are sent as strings

## 🔄 Expected Response Format

Your Rust backend should respond with:
- **Success**: Status 200/201 with the created/updated object
- **Error**: Status 4xx/5xx with error message

Example success response:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "created",
  "message": "Account created successfully"
}
```

Now run the sync and check the console - you'll see exactly what JSON data is being sent!