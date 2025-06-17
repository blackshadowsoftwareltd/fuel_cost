# Server Setup Instructions

## Configuration Required

Before using the sync functionality, you need to update the server URL in the following files:

### 1. Update Server URL in `lib/services/auth_service.dart`
Replace `YOUR_SERVER_URL` with your actual server URL:
```dart
static const String _baseUrl = 'YOUR_SERVER_URL'; // Change this to your server URL
```

### 2. Update Server URL in `lib/services/sync_service.dart`
Replace `YOUR_SERVER_URL` with your actual server URL:
```dart
static const String _baseUrl = 'YOUR_SERVER_URL'; // Change this to your server URL
```

## Example
If your server is running at `https://your-fuel-server.com`, update both files:
```dart
static const String _baseUrl = 'https://your-fuel-server.com';
```

## Server Repository
The server code is available at: https://github.com/blackshadowsoftwareltd/fuel_cost_server

## How It Works

1. **Authentication**: 
   - User enters email and password
   - If account doesn't exist, server automatically creates one
   - Auth token is stored locally

2. **Sync Process**:
   - When sync button is pressed, app checks if user is authenticated
   - If not authenticated, shows auth screen
   - After authentication, uploads all local fuel entries to server using bulk API
   - Shows success/error messages

3. **Data Format**:
   - Local fuel entries are converted to server format
   - Bulk upload sends all entries at once for efficiency
   - Server stores data with user_id association

## API Endpoints Used

- `POST /api/auth/signin` - Authentication (auto-signup)
- `POST /api/fuel-entries/bulk` - Bulk upload fuel entries

## Features Added

✅ Authentication screen with email/password  
✅ Auto-signup functionality  
✅ Sync button on home screen  
✅ Loading states during sync  
✅ Success/error feedback  
✅ Bulk data upload to server  
✅ Proper error handling for network issues  

The sync functionality is now ready to use once you configure the server URL!