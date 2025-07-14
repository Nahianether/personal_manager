# VPS API Configuration Update

## 🚀 **Configuration Updated**

Your application has been successfully configured to use your VPS backend server.

### **Primary Changes Made:**

## 📡 **API Endpoint Configuration**

**File:** `lib/config/api_config.dart`
- **Previous:** `http://localhost:3000`
- **Updated:** `http://103.51.129.29:3000`

## 🔧 **Updated Services**

### 1. **Main API Service** ✅
- `lib/services/api_service.dart` - Uses `ApiConfig.baseUrl` (automatically updated)
- All data synchronization will now go to your VPS database

### 2. **Test Services** ✅
- `lib/services/backend_test_service.dart` - Added VPS URL as primary endpoint
- `lib/services/simple_connectivity_test.dart` - Added VPS URL as primary endpoint

## 📊 **Data Flow**

Your application will now:

1. **Store data locally** in SQLite database (offline capability)
2. **Sync automatically** to your VPS database at `103.51.129.29:3000`
3. **Handle offline/online** transitions seamlessly

## 🔄 **Sync Behavior**

### **What gets synced:**
- ✅ Accounts
- ✅ Transactions  
- ✅ Loans (with new transaction logic)
- ✅ Liabilities (with new transaction logic)
- ✅ Categories

### **When sync happens:**
- 📱 **Immediate:** When creating/updating data (if connected)
- ⏰ **Periodic:** Every 5 minutes (if connected)
- 🔄 **On reconnect:** When internet connection is restored

## 🛡️ **Network Configuration**

### **Timeouts:** 
- Connect: 10 seconds
- Receive: 10 seconds  
- Send: 10 seconds

### **Headers:**
- Content-Type: application/json
- Accept: application/json

## 🧪 **Testing Connectivity**

The app includes built-in connectivity testing that will check:
1. **Primary:** `http://103.51.129.29:3000` (Your VPS)
2. **Fallback:** Local development servers (for testing)

## 📝 **Important Notes**

### **Security Considerations:**
- Currently using HTTP (not HTTPS)
- Consider adding SSL certificate to your VPS for production use
- API endpoints are not authenticated - add authentication if needed

### **Network Requirements:**
- Ensure port 3000 is open on your VPS
- Firewall should allow incoming connections on port 3000
- Your VPS backend should be running and accessible

### **Firewall Check:**
You can test if your VPS is accessible by running:
```bash
curl http://103.51.129.29:3000
```

## 🔍 **Verification Steps**

1. **Start the app** - It will attempt to connect to your VPS
2. **Create test data** - Should sync to your VPS database
3. **Check app logs** - Look for successful API calls
4. **Monitor VPS logs** - Verify requests are being received

## 🎯 **Next Steps**

1. **Test the connection** by creating some accounts/transactions
2. **Monitor your VPS** backend logs to see incoming requests
3. **Check your VPS database** to verify data is being stored
4. **Consider HTTPS** setup for production security

Your app is now fully configured to use your VPS backend! 🎉