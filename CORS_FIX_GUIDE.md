# CORS Fix Guide for Flutter Web + Django Backend

## Current Issue
Flutter web app cannot connect to Django backend due to CORS (Cross-Origin Resource Sharing) restrictions.

**Error:** `ClientException: Failed to fetch`

## Temporary Solution (Currently Active)
- Added mock login for `admin@gmail.com` / `admin123`
- App will work for testing UI/UX while backend CORS is being fixed

## Permanent Solutions

### Option 1: Fix Django Backend CORS (Recommended)

1. **Install django-cors-headers:**
```bash
pip install django-cors-headers
```

2. **Update Django settings.py:**
```python
INSTALLED_APPS = [
    # ... your existing apps
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    # ... your other middleware
]

# CORS Configuration
CORS_ALLOW_ALL_ORIGINS = True  # For development only
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOWED_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'ngrok-skip-browser-warning',
]

# For production, use specific origins:
# CORS_ALLOWED_ORIGINS = [
#     "http://localhost:3000",
#     "https://your-flutter-web-domain.com",
# ]
```

3. **Restart Django server**

### Option 2: Use Flutter Desktop/Mobile (No CORS Issues)

```bash
# Run on Windows desktop
flutter run -d windows

# Run on Android (if emulator available)
flutter run -d android
```

### Option 3: Use CORS Proxy (Development Only)

Run Flutter with disabled web security:
```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

## Testing After CORS Fix

1. Remove mock login from `auth_api_service.dart`
2. Test with real credentials
3. Verify all API endpoints work

## Current Mock Credentials
- Email: `admin@gmail.com`
- Password: `admin123`

## Next Steps
1. Fix CORS on Django backend (Option 1)
2. Test real API connection
3. Remove mock login code
4. Deploy with proper CORS configuration