# Organization API Integration

Complete implementation of Organization CRUD operations with the backend API.

## 📁 Files Created/Updated

### 1. **organization_api_service.dart**
Location: `lib/repository/screens/services/organization_api_service.dart`

Complete API service with all CRUD operations:
- ✅ Create Organization
- ✅ Fetch All Organizations
- ✅ Fetch Organization by ID
- ✅ Update Organization
- ✅ Delete Organization

### 2. **OrganizationScreen.dart** (Updated)
Location: `lib/repository/screens/organization/OrganizationScreen.dart`

Updated to use the new `OrganizationApiService` instead of the old `ApiService`.

### 3. **OrganizationDashboardScreen.dart** (Updated)
Location: `lib/repository/screens/organization/OrganizationDashboardScreen.dart`

Enhanced with:
- ✅ Full Edit functionality with dialog
- ✅ Full Delete functionality with confirmation
- ✅ Proper error handling
- ✅ Success/error notifications

### 4. **OrganizationApiTestScreen.dart** (New)
Location: `lib/repository/screens/organization/OrganizationApiTestScreen.dart`

Test screen to verify all API endpoints work correctly.

---

## 🔌 API Endpoints Integrated

### Base URL
```
https://distillatory-neoma-unmoldy.ngrok-free.dev/api
```

### 1. Create Organization
**Endpoint:** `POST /organization/create/`

**Request Body:**
```json
{
  "orgName": "string",
  "orgLocation": "string",
  "orgContact": "string",
  "orgEmail": "string",
  "orgLink": "string",
  "orgStatus": "Active" | "Inactive"
}
```

**Usage:**
```dart
final result = await OrganizationApiService.createOrganization(
  orgName: "My Organization",
  orgLocation: "New York",
  orgContact: "+1234567890",
  orgEmail: "contact@org.com",
  orgLink: "https://org.com",
  orgStatus: "Active",
);

if (result["success"]) {
  print("Created: ${result["data"]}");
} else {
  print("Error: ${result["message"]}");
}
```

---

### 2. Fetch All Organizations
**Endpoint:** `GET /organization/fetch/`

**Usage:**
```dart
try {
  final organizations = await OrganizationApiService.getOrganizations();
  print("Found ${organizations.length} organizations");
  
  for (var org in organizations) {
    print("${org["orgName"]} - ${org["orgStatus"]}");
  }
} catch (e) {
  print("Error: $e");
}
```

---

### 3. Fetch Organization by ID
**Endpoint:** `GET /organization/fetch/id/{id}/`

**Usage:**
```dart
final org = await OrganizationApiService.getOrganizationById("12345");

if (org != null) {
  print("Organization: ${org["orgName"]}");
} else {
  print("Organization not found");
}
```

---

### 4. Update Organization
**Endpoint:** `PUT /organization/update/id/{id}/`

**Request Body:**
```json
{
  "orgName": "string",
  "orgLocation": "string",
  "orgContact": "string",
  "orgEmail": "string",
  "orgLink": "string",
  "orgStatus": "Active" | "Inactive"
}
```

**Usage:**
```dart
final updateData = {
  "orgName": "Updated Name",
  "orgLocation": "Updated Location",
  "orgContact": "+9876543210",
  "orgEmail": "new@email.com",
  "orgLink": "https://newlink.com",
  "orgStatus": "Active",
};

final result = await OrganizationApiService.updateOrganization(
  "12345",
  updateData,
);

if (result["success"]) {
  print("Updated successfully");
} else {
  print("Error: ${result["message"]}");
}
```

---

### 5. Delete Organization
**Endpoint:** `DELETE /organization/delete/id/{id}/`

**Usage:**
```dart
final result = await OrganizationApiService.deleteOrganization("12345");

if (result["success"]) {
  print("Deleted successfully");
} else {
  print("Error: ${result["message"]}");
}
```

---

## 🎯 Features

### Error Handling
- ✅ Network timeout (30 seconds)
- ✅ No internet connection detection
- ✅ HTTP status code handling (200, 201, 400, 401, 404)
- ✅ Exception catching with detailed logging

### Response Format
All methods return consistent response formats:

**Success Response:**
```dart
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response:**
```dart
{
  "success": false,
  "message": "Error description"
}
```

### Logging
All API calls include detailed console logging:
- 🌐 Request URL
- 📤 Request body
- 📡 Response status
- 📦 Response body
- ✅ Success messages
- ❌ Error messages

---

## 🧪 Testing

### Using the Test Screen

1. Navigate to `OrganizationApiTestScreen`:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => OrganizationApiTestScreen(),
  ),
);
```

2. Test each endpoint in order:
   - Create Organization
   - Fetch All Organizations
   - Fetch Organization by ID
   - Update Organization
   - Delete Organization

### Manual Testing

Check the console logs for detailed API responses:
```
🌐 Creating organization at: https://...
📤 Request Body: {"orgName":"Test",...}
📡 Response Status: 201
📦 Response Body: {...}
✅ Organization created successfully!
```

---

## 🔐 Authentication

The service uses JWT Bearer token authentication:

```dart
static const String token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
```

Headers sent with every request:
```dart
{
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
  'Accept': 'application/json',
}
```

---

## 📱 UI Integration

### Dashboard Features
- **View:** Display organization details in a dialog
- **Edit:** Update organization with inline form
- **Delete:** Confirm and delete with feedback
- **Refresh:** Pull-to-refresh to reload data
- **Empty State:** Friendly message when no data

### Create Screen Features
- **Form Validation:** Required fields and email format
- **Loading State:** Disabled button with spinner
- **Success Feedback:** Green snackbar with checkmark
- **Error Feedback:** Red snackbar with error message
- **Clear Fields:** Reset form button

---

## 🚀 Quick Start

### 1. Import the service
```dart
import 'package:blinkit/repository/screens/services/organization_api_service.dart';
```

### 2. Use in your screen
```dart
// Fetch organizations
final orgs = await OrganizationApiService.getOrganizations();

// Create organization
final result = await OrganizationApiService.createOrganization(
  orgName: "New Org",
  orgLocation: "Location",
  orgContact: "Contact",
  orgEmail: "email@test.com",
  orgLink: "https://link.com",
  orgStatus: "Active",
);

// Update organization
final updateResult = await OrganizationApiService.updateOrganization(
  orgId,
  updateData,
);

// Delete organization
final deleteResult = await OrganizationApiService.deleteOrganization(orgId);
```

---

## 📝 Notes

1. **Organization ID:** The API may return `_id` or `id` - the service handles both
2. **Response Format:** The service handles both array and wrapped responses
3. **Timeout:** All requests timeout after 30 seconds
4. **Error Messages:** User-friendly error messages for all scenarios

---

## ✅ Checklist

- [x] Create Organization API
- [x] Fetch All Organizations API
- [x] Fetch Organization by ID API
- [x] Update Organization API
- [x] Delete Organization API
- [x] Error handling
- [x] Loading states
- [x] Success/error notifications
- [x] Form validation
- [x] Edit dialog
- [x] Delete confirmation
- [x] Test screen
- [x] Documentation

---

## 🎉 Complete!

All Organization API endpoints are now fully integrated and ready to use!
