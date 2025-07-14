# Loan & Liability Transaction System Usage

This document explains how to use the new loan and liability transaction system that automatically handles account debits and credits.

## Key Features

1. **Historical vs New Entries**: Distinguish between past records and new transactions
2. **Automatic Account Transactions**: Debits/credits your accounts when giving loans or settling debts
3. **Settlement Tracking**: Proper account reconciliation when loans are returned or liabilities are paid

## Usage Examples

### 1. Creating a Historical Loan Entry (No Account Impact)

```dart
// Add a loan that happened in the past - no account debit
await loanProvider.addLoan(
  personName: 'John Doe',
  amount: 5000.0,
  currency: 'BDT',
  loanDate: DateTime(2024, 1, 15),
  description: 'Emergency loan given last year',
  isHistoricalEntry: true,  // This prevents account debit
  accountId: null,          // No account needed for historical entries
);
```

### 2. Giving a New Loan (Account Debited)

```dart
// Give a new loan - automatically debits your selected account
await loanProvider.addLoan(
  personName: 'Jane Smith',
  amount: 3000.0,
  currency: 'BDT',
  loanDate: DateTime.now(),
  description: 'New loan for business',
  isHistoricalEntry: false, // This triggers account debit
  accountId: 'cash_account_id', // Required for new loans
);
```

### 3. Settling a Loan (Account Credited)

```dart
// When loan is returned - automatically credits your account
await loanProvider.markLoanAsReturned(
  'loan_id',
  settleAccountId: 'bank_account_id', // Optional: different account
);
```

### 4. Creating a Historical Liability (No Account Impact)

```dart
// Add a liability that already exists - no account impact
await liabilityProvider.addLiability(
  personName: 'ABC Company',
  amount: 2000.0,
  currency: 'BDT',
  dueDate: DateTime(2024, 12, 31),
  description: 'Outstanding invoice from last month',
  isHistoricalEntry: true,  // No account impact
  accountId: 'bank_account_id', // Account to use when settling
);
```

### 5. Settling a Liability (Account Debited)

```dart
// Pay a liability - automatically debits your account
await liabilityProvider.markAsPaid(
  'liability_id',
  settleAccountId: 'cash_account_id', // Optional: different account
);
```

## Transaction Flow

### For Loans:
1. **Historical Entry**: No transaction created
2. **New Loan**: Creates expense transaction (debits your account)
3. **Loan Settlement**: Creates income transaction (credits your account)

### For Liabilities:
1. **Historical Entry**: No transaction created
2. **Liability Settlement**: Creates expense transaction (debits your account)

## Database Schema Changes

New fields added to both `loans` and `liabilities` tables:
- `is_historical_entry`: Boolean flag to distinguish entry types
- `account_id`: Associated account for transactions
- `transaction_id`: Links to the related transaction record

## Account Balance Impact

- **Giving a loan**: Your account balance decreases (expense)
- **Receiving loan payment**: Your account balance increases (income)
- **Paying a liability**: Your account balance decreases (expense)
- **Historical entries**: No impact on account balances

This ensures your account balances always reflect the actual money flow from loan and liability activities.