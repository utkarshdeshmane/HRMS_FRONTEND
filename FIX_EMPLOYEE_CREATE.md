# Fix Employee Create API - Manual Steps

## Problem
The backend expects `multipart/form-data` but we're sending `application/json`, causing 415 error.

## Solution
Replace the `createEmployee` method in `lib/repository/screens/services/employee_api_service.dart`

## Find this code (around line 417-432):
```dart
      final url = Uri.parse("${baseUrl}api/employee/create/");
      
      print("📝 Preparing employee data...");
      print("📊 Form data keys: ${formData.keys.toList()}");
      
      // Use regular POST with JSON body (since we're not uploading files on web)
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: json.encode(formData),
      );
      
      print("📡 Request sent to: $url");
```

## Replace with:
```dart
      var request = http.MultipartRequest(
          "POST", Uri.parse("${baseUrl}api/employee/create/"));

      request.headers["Accept"] = "application/json";
      request.headers["ngrok-skip-browser-warning"] = "true";

      print("Adding form fields...");
      
      formData.forEach((key, value) {
        if (value != null) {
          if (value is Map) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });
      
      print("Added ${request.fields.length} form fields");
      print("Sending multipart request");
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print("Sending multipart request");
```

## Key Changes:
1. Use `MultipartRequest` instead of `http.post`
2. Convert nested Maps (addresses) to JSON strings with `json.encode(value)`
3. Send as multipart/form-data (what backend expects)

## After fixing, employee creation will work!
