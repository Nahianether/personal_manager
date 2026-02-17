# Personal Manager - Feature Roadmap

## Completed Features

### Core Financial Management
- [x] Account management (CRUD) - savings, checking, credit card, cash, mobile banking
- [x] Transaction tracking (income/expense) with categories
- [x] Transfer between accounts with history
- [x] Loan tracking (given/received) with account linking
- [x] Liability tracking with payment via accounts
- [x] Budget planning with category-based spending limits
- [x] Recurring transactions (daily/weekly/monthly/yearly)

### Currency & Conversion
- [x] Multi-currency support (20+ currencies: BDT, USD, EUR, GBP, INR, JPY, etc.)
- [x] Per-account currency selection
- [x] Live exchange rates from ExchangeRate-API (24h cache)
- [x] Display currency preference (convert totals to preferred currency)
- [x] Currency picker widget (searchable)
- [x] Backend preference sync (GET/PUT /api/preferences)

### Reports & Analytics
- [x] Visual reports (income vs expense charts via FL Chart)
- [x] Daily/weekly/monthly/yearly report periods
- [x] PDF report generation and sharing
- [x] Excel/CSV export

### Notifications & Reminders
- [x] Due liability alerts
- [x] Budget overspend warnings
- [x] Loan return reminders
- [x] In-app notification center

### UI & Settings
- [x] Dark/light theme with persistence
- [x] Customizable dashboard (reorder/toggle sections)
- [x] Settings screen (theme, currency, data management)

### Backend & Sync
- [x] Rust/Axum backend with SQLite
- [x] JWT authentication (signup/login/signin)
- [x] Full CRUD API for accounts, transactions, loans, liabilities
- [x] User data download endpoints (/api/*)
- [x] User preferences sync
- [x] Database auto-migration (WAL mode, create_if_missing)
- [x] CORS enabled for Flutter development
- [x] API service with auth interceptor

### Auth
- [x] Sign up / Sign in screens
- [x] Auth splash screen (auto-login)
- [x] Token-based authentication

---

## Upcoming Features (Priority Order)

### 1. Data Export & Backup Improvements
- [x] JSON backup export with metadata envelope & share via share_plus
- [x] Import from CSV (auto-detects transactions/accounts/generic format)
- [x] Data restore from JSON backup file
- [ ] Cloud backup (Google Drive / local file backup)
- [ ] Scheduled auto-backup

### 2. Savings Goals
- [x] Create savings goals with target amount and deadline
- [x] Link goals to accounts
- [x] Track progress with visual indicators (progress bars, percentage, days remaining)
- [x] Auto-contribute from recurring transactions

### 4. Financial Insights & AI
- [x] Monthly spending summary with trends
- [x] Category spending analysis over time
- [x] Smart budget suggestions based on history
- [x] Unusual spending alerts

### 5. Calendar Integration
- [ ] Calendar view for transactions, tasks, and bills
- [ ] Daily/weekly/monthly views
- [ ] Event scheduling

### 6. Cloud Synchronization
- [ ] Real-time sync between devices
- [ ] Conflict resolution
- [ ] Offline queue with auto-sync on reconnect
- [ ] Sync status indicators

### 8. UI/UX Enhancements
- [x] Dashboard widgets (Recent Transactions, Savings Goals sections)
- [x] Search across all data (accounts, transactions, loans, liabilities, savings goals)
- [x] Batch operations (multi-select delete on transactions and accounts)
- [ ] Onboarding flow for new users
- [ ] Biometric lock (fingerprint/face)

---

## Tech Stack
- **Frontend:** Flutter/Dart with Riverpod state management
- **Backend:** Rust/Axum with SQLite (sqlx)
- **Auth:** JWT tokens
- **Charts:** FL Chart
- **Currency:** ExchangeRate-API (free tier, USD base)
- **Reports:** PDF (pdf package) + Excel (excel package)
