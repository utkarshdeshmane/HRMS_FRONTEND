import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/platform_file.dart';

class ApiService {
    
  // static const String baseUrl = "https://distillatory-neoma-unmoldy.ngrok-free.dev/";
  static const String baseUrl = "http://127.0.0.1:8000/";
  
  // Get headers with authentication token if available
  static Future<Map<String, String>> getHeaders() async {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "ngrok-skip-browser-warning": "true",
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    } catch (e) {
      print("Error getting auth token: $e");
    }

    return headers;
  }

  // Helper to get employee ID
  static String? getEmployeeId(dynamic employee) {
    return employee['id']?.toString() ?? employee['_id']?.toString();
  }

  // ========== Fetch Employees with Dropdowns ==========
  Future<List<dynamic>> getEmployees() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/fetch/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("📡 Employee Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // Handle different response formats
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map) {
          return decoded["results"] ?? decoded["data"] ?? [];
        }
      }
      return [];
    } catch (e) {
      print("❌ EXCEPTION in getEmployees: $e");
      return [];
    }
  }

  // ========== Fetch Shifts from Employee API ==========
  Future<List<dynamic>> getShifts() async {
    try {
      print("📡 Fetching shifts from employee API...");
      final url = Uri.parse("${baseUrl}api/employee/fetch/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("   Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        if (decoded is Map && decoded.containsKey("shifts")) {
          print("✅ Found shifts in response");
          return decoded["shifts"] is List ? decoded["shifts"] : [];
        }
      }
      
      print("⚠️ No shifts found");
      return [];
    } catch (e) {
      print("❌ EXCEPTION in getShifts: $e");
      return [];
    }
  }

  // ========== Fetch Reporting Managers ==========
  Future<List<dynamic>> getReportingManagers() async {
    try {
      print("📡 Fetching reporting managers...");
      final url = Uri.parse("${baseUrl}api/employee/fetch/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        if (decoded is Map && decoded.containsKey("reportingManagers")) {
          print("✅ Found reporting managers in response");
          return decoded["reportingManagers"] is List ? decoded["reportingManagers"] : [];
        }
      }
      
      print("⚠️ No managers found");
      return [];
    } catch (e) {
      print("❌ EXCEPTION in getReportingManagers: $e");
      return [];
    }
  }

  // ========== Create Employee ==========
  Future<http.Response> createEmployee(
    Map<String, dynamic> formData, Map<String, CustomPlatformFile?> docs) async {
    print("=" * 80);
    print("🔵 CREATE EMPLOYEE API CALL STARTED");
    print("=" * 80);
    
    try {
      var request = http.MultipartRequest(
          "POST", Uri.parse("${baseUrl}api/employee/create/"));

      // Add authentication headers
      final headers = await getHeaders();
      request.headers.addAll(headers);
      request.headers.remove("Content-Type"); // MultipartRequest sets this automatically

      print("📝 Adding form fields...");
      
      // Add all form fields
      formData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      print("✅ Added ${request.fields.length} form fields");
      
      // Add document files
      print("📎 Processing ${docs.length} document fields...");
      int filesAdded = 0;
      
      for (var entry in docs.entries) {
        if (entry.value != null) {
          try {
            CustomPlatformFile platformFile = entry.value!;
            
            // Get file bytes using the platform file method
            Uint8List? bytes = await platformFile.getBytes();
            
            if (bytes == null) {
              print("⚠️ Skipping ${entry.key}: Could not read file bytes");
              continue;
            }
            
            String filename = platformFile.name;
            if (filename.isEmpty) {
              filename = "${entry.key}_document";
            }
            
            // Detect MIME type
            String? mimeType = lookupMimeType(filename);
            MediaType? mediaType;
            
            if (mimeType != null) {
              var parts = mimeType.split('/');
              mediaType = MediaType(parts[0], parts[1]);
            } else {
              // Default MIME types based on file type
              if (entry.key == "photo") {
                mediaType = MediaType('image', 'jpeg');
              } else {
                mediaType = MediaType('application', 'pdf');
              }
            }
            
            // Add file to request with nested field name for Django backend
            request.files.add(
              http.MultipartFile.fromBytes(
                "documents.${entry.key}", // Django expects documents.adharCard format
                bytes,
                filename: filename,
                contentType: mediaType,
              ),
            );
            
            filesAdded++;
            print("✅ File ${filesAdded}: documents.${entry.key} -> $filename (${bytes.length} bytes)");
          } catch (e) {
            print("⚠️ Error adding file ${entry.key}: $e");
          }
        }
      }
      
      print("📎 Total files added: $filesAdded");
      print("📡 Sending request to: ${baseUrl}api/employee/create/");
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 RESPONSE RECEIVED");
      print("📊 Status Code: ${response.statusCode}");
      print("📄 Response Body: ${response.body}");
      print("=" * 80);

      return response;
    } catch (e, stackTrace) {
      print("❌ CREATE EMPLOYEE EXCEPTION: $e");
      print("📍 STACK TRACE: $stackTrace");
      return http.Response(
        json.encode({"error": e.toString()}), 
        500
      );
    }
  }

  // ========== Update Employee ==========
  Future<Map<String, dynamic>?> updateEmployee(
      String employeeId, Map<String, dynamic> employeeData) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/update/$employeeId/");
      print("✏️ Updating employee: $employeeId");

      final headers = await getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(employeeData),
      );

      print("📊 Update Status Code: ${response.statusCode}");
      print("📄 Update Response: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Employee updated successfully");
        return json.decode(response.body);
      } else {
        print("❌ Update failed: ${response.statusCode}");
        return null;
      }
    } catch (e, stackTrace) {
      print("❌ UPDATE EXCEPTION: $e");
      print("📍 STACK TRACE: $stackTrace");
      return null;
    }
  }

  // ========== Update Employee with Files ==========
  Future<http.Response> updateEmployeeWithFiles(
    String employeeId, 
    Map<String, dynamic> formData, 
    Map<String, CustomPlatformFile?> docs
  ) async {
    print("=" * 80);
    print("🔵 UPDATE EMPLOYEE WITH FILES API CALL STARTED");
    print("=" * 80);
    
    try {
      var request = http.MultipartRequest(
          "PUT", Uri.parse("${baseUrl}api/employee/update/$employeeId/"));

      // Add authentication headers
      final headers = await getHeaders();
      request.headers.addAll(headers);
      request.headers.remove("Content-Type"); // MultipartRequest sets this automatically

      print("📝 Adding form fields...");
      
      // Add all form fields
      formData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      print("✅ Added ${request.fields.length} form fields");
      
      // Add document files
      print("📎 Processing ${docs.length} document fields...");
      int filesAdded = 0;
       
      for (var entry in docs.entries) {
        if (entry.value != null) {
          try {
            CustomPlatformFile platformFile = entry.value!;
            
            // Get file bytes using the platform file method
            Uint8List? bytes = await platformFile.getBytes();
            
            if (bytes == null) {
              print("⚠️ Skipping ${entry.key}: Could not read file bytes");
              continue;
            }
            
            String filename = platformFile.name;
            if (filename.isEmpty) {
              filename = "${entry.key}_document";
            }
            
            // Detect MIME type
            String? mimeType = lookupMimeType(filename);
            MediaType? mediaType;
            
            if (mimeType != null) {
              var parts = mimeType.split('/');
              mediaType = MediaType(parts[0], parts[1]);
            } else {
              // Default MIME types based on file type
              if (entry.key == "photo") {
                mediaType = MediaType('image', 'jpeg');
              } else {
                mediaType = MediaType('application', 'pdf');
              }
            }
            
            // Add file to request with nested field name for Django backend
            request.files.add(
              http.MultipartFile.fromBytes(
                "documents.${entry.key}", // Django expects documents.adharCard format
                bytes,
                filename: filename,
                contentType: mediaType,
              ),
            );
            
            filesAdded++;
            print("✅ File ${filesAdded}: documents.${entry.key} -> $filename (${bytes.length} bytes)");
          } catch (e) {
            print("⚠️ Error adding file ${entry.key}: $e");
          }
        }
      }
      
      print("📎 Total files added: $filesAdded");
      print("📡 Sending request to: ${baseUrl}api/employee/update/$employeeId/");
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 RESPONSE RECEIVED");
      print("📊 Status Code: ${response.statusCode}");
      print("📄 Response Body: ${response.body}");
      print("=" * 80);

      return response;
    } catch (e, stackTrace) {
      print("❌ UPDATE EMPLOYEE WITH FILES EXCEPTION: $e");
      print("📍 STACK TRACE: $stackTrace");
      return http.Response(
        json.encode({"error": e.toString()}), 
        500
      );
    }
  }

  // ========== Delete Employee ==========
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/delete/$employeeId/");
      print("🗑️ Deleting employee: $employeeId");

      final headers = await getHeaders();
      final response = await http.delete(url, headers: headers);

      print("📊 Delete Status Code: ${response.statusCode}");
      print("📄 Delete Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ Employee deleted successfully");
        return true;
      } else {
        print("❌ Delete failed: ${response.statusCode}");
        return false;
      }
    } catch (e, stackTrace) {
      print("❌ DELETE EXCEPTION: $e");
      print("📍 STACK TRACE: $stackTrace");
      return false;
    }
  }

  // ========== Get Employee Profile ==========
  Future<Map<String, dynamic>?> getLoggedEmployee() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/profile/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("Profile Response: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("Profile Error: $e");
      return null;
    }
  }

  // ========== Check-In ==========
  Future<bool> checkIn() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/checkin/");
      final headers = await getHeaders();
      final response = await http.post(url, headers: headers);

      print("CheckIn Response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("CheckIn Error: $e");
      return false;
    }
  }

  // ========== Check-Out ==========
  Future<bool> checkOut() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/checkout/");
      final headers = await getHeaders();
      final response = await http.post(url, headers: headers);

      print("CheckOut Response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("CheckOut Error: $e");
      return false;
    }
  }

  // ========== Employee Login ==========
  Future<Map<String, dynamic>?> loginEmployee(String email, String password) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/login/");
      final headers = await getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      print("Login Response: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // ========== Change Password ==========
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/change-password/");
      final headers = await getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          "old_password": oldPassword,
          "new_password": newPassword,
        }),
      );

      print("Change Password Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Change Password Error: $e");
      return false;
    }
  }

  // ========== Send Credentials ==========
  Future<bool> sendCredentials(String employeeId) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/send-credentials/$employeeId/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("Send Credentials Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Send Credentials Error: $e");
      return false;
    }
  }

  // ========== Get Attendance ==========
  Future<List<dynamic>> getAttendance() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/attendance/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded["attendance"] ?? [];
      }
      return [];
    } catch (e) {
      print("Get Attendance Error: $e");
      return [];
    }
  }

  // ========== Mark Attendance ==========
  Future<bool> markAttendance(String employeeId) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/mark-attendance/$employeeId/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print("Mark Attendance Error: $e");
      return false;
    }
  }

  // ========== Mark All Attendance ==========
  Future<bool> markAllAttendance() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/mark-all-attendance/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print("Mark All Attendance Error: $e");
      return false;
    }
  }

  // ========== Get Attendance Data ==========
  Future<Map<String, dynamic>?> getAttendanceData() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/attendance-summary/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("📊 Attendance Summary Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        if (data is Map) {
          return data['data'] ?? data;
        }
        return data;
      }
      return null;
    } catch (e) {
      print("❌ Attendance Data Error: $e");
      return null;
    }
  }

  // ========== Get Leave Balance ==========
  Future<Map<String, dynamic>?> getLeaveBalance() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/leave-balance/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("📊 Leave Balance Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        if (data is Map) {
          return data['data'] ?? data;
        }
        return data;
      }
      return null;
    } catch (e) {
      print("❌ Leave Balance Error: $e");
      return null;
    }
  }

  // ========== Get Today's Attendance Status ==========
  Future<Map<String, dynamic>?> getTodayAttendanceStatus() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/attendance-status/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("📊 Today's Attendance Status: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print("❌ Attendance Status Error: $e");
      return null;
    }
  }

  // ========== Get Employee Dashboard Data ==========
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/dashboard/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("📊 Dashboard Data Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        if (data is Map) {
          return data['data'] ?? data;
        }
        return data;
      }
      return null;
    } catch (e) {
      print("❌ Dashboard Data Error: $e");
      return null;
    }
  }

  // ========== Get Recent Activities ==========
  Future<List<dynamic>> getRecentActivities() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/recent-activities/");
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      print("📊 Recent Activities Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        if (data is List) {
          return data;
        } else if (data is Map) {
          return data['data'] ?? data['activities'] ?? [];
        }
        return [];
      }
      return [];
    } catch (e) {
      print("❌ Recent Activities Error: $e");
      return [];
    }
  }
}