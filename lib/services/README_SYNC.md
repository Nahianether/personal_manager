# Offline-First Sync Implementation

This implementation provides offline-first data synchronization with your Rust backend API. When the device has internet connectivity, data automatically syncs to the server. When offline, data is stored locally and synced when connectivity is restored.

## How It Works

### 1. Local Database Enhancement
- Added `sync_status` and `last_synced_at` columns to all data tables
- Sync status values: `pending`, `synced`, `failed`
- All new data is automatically marked as `pending` for sync

### 2. Connectivity Monitoring
- Real-time internet connectivity detection using `connectivity_plus`
- Automatic sync trigger when internet becomes available
- Offline/online status indication in the UI

### 3. Sync Service
- Background synchronization every 5 minutes when online
- Batch sync for better performance
- Automatic retry mechanism for failed sync attempts
- Individual item sync when data is created/updated

### 4. API Integration
- RESTful API endpoints for all data types (accounts, transactions, loans, liabilities)
- Batch sync endpoints for efficient data transfer
- Timeout and error handling
- Configurable base URL and timeouts

## Configuration

Update the API configuration in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://your-rust-backend-url.com';
  // ... other configuration options
}
```

## Rust Backend API Endpoints (✅ IMPLEMENTED)

Your Rust backend already implements these endpoints:

### Health Check
- `GET /health` - Server health check ✅

### Accounts
- `GET /accounts` - Get all accounts ✅
- `POST /accounts` - Create account ✅
- `PUT /accounts/{id}` - Update account (needs implementation)
- `DELETE /accounts/{id}` - Delete account (needs implementation)
- `POST /accounts/batch` - Batch sync accounts (needs implementation)

### Transactions
- `GET /transactions` - Get all transactions ✅
- `POST /transactions` - Create transaction ✅
- `PUT /transactions/{id}` - Update transaction (needs implementation)
- `DELETE /transactions/{id}` - Delete transaction (needs implementation)
- `POST /transactions/batch` - Batch sync transactions (needs implementation)

### Loans
- `GET /loans` - Get all loans ✅
- `POST /loans` - Create loan ✅
- `PUT /loans/{id}` - Update loan (needs implementation)
- `DELETE /loans/{id}` - Delete loan (needs implementation)
- `POST /loans/batch` - Batch sync loans (needs implementation)

### Liabilities
- `GET /liabilities` - Get all liabilities ✅
- `POST /liabilities` - Create liability ✅
- `PUT /liabilities/{id}` - Update liability (needs implementation)
- `DELETE /liabilities/{id}` - Delete liability (needs implementation)
- `POST /liabilities/batch` - Batch sync liabilities (needs implementation)

### Categories
- `GET /categories` - Get all categories ✅
- `POST /categories` - Create category ✅

## Data Flow

1. **Creating Data (Online):**
   - Save to local database with `sync_status = 'pending'`
   - Immediately attempt to sync to API
   - On success: Update `sync_status = 'synced'` and `last_synced_at`
   - On failure: Keep as `pending` for retry

2. **Creating Data (Offline):**
   - Save to local database with `sync_status = 'pending'`
   - Data will sync automatically when internet is restored

3. **Background Sync:**
   - Every 5 minutes, check for pending items
   - Sync all pending items to API
   - Update sync status accordingly

4. **Manual Sync:**
   - Users can trigger manual sync via the sync status widget
   - Force sync option to re-sync all data

## UI Components

### SyncStatusWidget
- Shows current connectivity and sync status
- Displays pending items count
- Manual sync buttons
- Error messages

### SyncStatusIndicator
- Small indicator in app bar
- Shows connectivity and pending items
- Non-intrusive status display

## Usage Example

```dart
// The sync happens automatically, but you can manually trigger it:
final syncNotifier = ref.read(syncProvider.notifier);

// Sync pending data
await syncNotifier.syncNow();

// Force sync all data
await syncNotifier.forceSyncAll();

// Mark specific item for sync
await syncNotifier.markForSync('accounts', accountId);
```

## Benefits

1. **Offline Capability:** App works fully offline with local data storage
2. **Automatic Sync:** Seamless sync when internet is available
3. **Data Integrity:** No data loss due to connectivity issues
4. **User Experience:** No blocking operations, smooth user experience
5. **Reliability:** Retry mechanisms ensure data eventually syncs
6. **Transparency:** Users can see sync status and pending items

## Testing

To test the offline-first functionality:

1. **Offline Mode:**
   - Turn off internet/WiFi
   - Create/update data in the app
   - Verify data is saved locally
   - Check sync status shows pending items

2. **Online Mode:**
   - Turn internet back on
   - Verify automatic sync occurs
   - Check sync status updates to "synced"
   - Verify data appears on backend

3. **Error Scenarios:**
   - Test with invalid API endpoint
   - Test with server downtime
   - Verify retry mechanisms work
   - Check error messages display properly

## Dependencies Added

- `http: ^1.1.0` - HTTP client for API requests
- `connectivity_plus: ^6.0.5` - Network connectivity monitoring
- `dio: ^5.4.0` - Advanced HTTP client with interceptors

## Next Steps

1. Configure your Rust backend API endpoints
2. Update the base URL in `api_config.dart`
3. Test the sync functionality
4. Monitor sync performance and optimize as needed