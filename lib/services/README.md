# API Service Configuration

## Backend URL Configuration

The API service uses a base URL that needs to be configured based on your development environment.

### Update `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

### URL Options by Platform:

1. **Windows/Mac/Linux (same machine):**
   ```dart
   static const String baseUrl = 'http://127.0.0.1:8000';
   ```

2. **Android Emulator:**
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8000';
   ```

3. **iOS Simulator:**
   ```dart
   static const String baseUrl = 'http://localhost:8000';
   ```

4. **Physical Device (same network):**
   - Find your computer's IP address (e.g., `192.168.1.100`)
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8000';
   ```

## Testing the Connection

1. Make sure your FastAPI backend is running:
   ```bash
   cd backend
   uvicorn main:app --reload
   ```

2. Test the health endpoint:
   ```bash
   curl http://127.0.0.1:8000/health
   ```

3. Run your Flutter app and check the History screen.

## Troubleshooting

- **Connection refused**: Make sure the backend is running and the URL is correct
- **CORS errors**: The backend already has CORS enabled for all origins
- **No data showing**: Make sure you have data in your Supabase database
