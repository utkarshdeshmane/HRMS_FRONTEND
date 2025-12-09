import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

class DepartmentApiService {
  static const String baseUrl = "https://distillatory-neoma-unmoldy.ngrok-free.dev/api";
  
  // JWT Token
  static const String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBJZCI6IjY5Mjk0ZGYxYWI5ZmI3YWE0MmJjZWY4ZiIsInJvbGUiOiJhZG1pbiIsImV4cCI6MTc2NTQzNzAyNiwiaWF0IjoxNzY0ODMyMjI2fQ.70DG833hoc8bKfRJpSd-eMQbt7C0C5tJVDS7kjGsEI0";

  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Get common headers
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Add this to bypass ngrok warnings
    };
  }

  /// Check if response is HTML/ngrok error
  static bool _isHtmlResponse(String body) {
    if (body.isEmpty) return false;
    return body.trim().startsWith('<!DOCTYPE') || 
           body.contains('<html') || 
           body.contains('ngrok') ||
           body.contains('DOCTYPE') ||
           body.contains('html>') ||
           body.contains('<head>');
  }

  /// Show troubleshooting steps for ngrok errors
  static void _showNgrokTroubleshooting() {
    print("\n🔧 ========== NGROK TROUBLESHOOTING ==========");
    print("❌ You're getting an ngrok HTML page instead of JSON.");
    print("💡 This means your backend server is NOT running or ngrok can't reach it.");
    print("\n📋 STEPS TO FIX:");
    print("1. ✅ Start your backend server (Spring Boot/Django/Node.js)");
    print("2. ✅ Check the port (usually 8080, 8000, 3000, etc.)");
    print("3. ✅ Test locally: http://localhost:YOUR_PORT/api/department/fetch/");
    print("4. ✅ Restart ngrok: ngrok http http://localhost:YOUR_PORT");
    print("5. ✅ Update baseUrl with new ngrok URL");
    print("===========================================\n");
  }

  // ============================================================================
  // ORGANIZATION METHODS
  // ============================================================================

  /// Fetch all organizations - CORRECTED VERSION
  static Future<List<dynamic>> getOrganizations() async {
    try {
      final url = Uri.parse("$baseUrl/organization/fetch/");
      
      print("🌐 Fetching organizations from: $url");
      
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(timeoutDuration);

      print("📡 Response Status: ${response.statusCode}");
      
      // Check for HTML response BEFORE trying to parse JSON
      if (_isHtmlResponse(response.body)) {
        print("❌ NGrok HTML Error Received!");
        print("💡 First 500 chars: ${response.body.substring(0, min(response.body.length, 500))}");
        
        _showNgrokTroubleshooting();
        
        throw Exception('NGROK_ERROR: Backend server not accessible. Check if backend is running on port 8080/8000.');
      }
      
      print("📦 Response Body Preview: ${response.body.substring(0, min(response.body.length, 200))}...");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print("✅ DECODED RESPONSE TYPE: ${decoded.runtimeType}");

        // Handle different response formats
        List<dynamic> orgList;
        
        if (decoded is List) {
          // Direct array: [{"_id": "...", "orgName": "..."}, ...]
          orgList = decoded;
        } else if (decoded is Map) {
          // Wrapped response
          orgList = decoded["results"] ?? 
                    decoded["data"] ?? 
                    decoded["organizations"] ?? 
                    [];
        } else {
          orgList = [];
        }

        print("✅ Found ${orgList.length} organizations");
        return orgList;
        
      } else {
        print("❌ API ERROR: ${response.statusCode}");
        throw Exception('Failed to load organizations: ${response.statusCode}');
      }
    } on SocketException {
      print("❌ No internet connection");
      throw Exception('No internet connection');
    } on TimeoutException {
      print("❌ Request timeout");
      throw Exception('Request timeout');
    } on FormatException catch (e) {
      print("❌ FORMAT EXCEPTION: $e");
      throw Exception('Invalid JSON response from server');
    } catch (e) {
      print("❌ EXCEPTION: $e");
      throw Exception('Error: ${e.toString()}');
    }
  }

  // ============================================================================
  // DEPARTMENT METHODS
  // ============================================================================

  /// Get all departments
  static Future<List<dynamic>> getDepartments() async {
    try {
      final url = Uri.parse("$baseUrl/department/fetch/");
      
      print("🌐 Fetching departments from: $url");
      
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(timeoutDuration);

      print("📡 Response Status: ${response.statusCode}");
      
      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print("❌ NGrok HTML Error Received!");
        print("💡 First 500 chars: ${response.body.substring(0, min(response.body.length, 500))}");
        
        _showNgrokTroubleshooting();
        
        throw Exception('NGROK_ERROR: Backend server not accessible.');
      }
      
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        print("✅ DECODED RESPONSE TYPE: ${decoded.runtimeType}");
        print("✅ DECODED KEYS: ${decoded is Map ? decoded.keys.toList() : 'Not a Map'}");
        
        if (decoded is List) {
          // Direct array response
          return decoded;
        } else if (decoded is Map) {
          // Wrapped response - check multiple possible keys
          final deptList = decoded["data"] ?? 
                          decoded["results"] ?? 
                          decoded["departments"] ?? 
                          [];
          
          print("✅ Found ${deptList.length} departments");
          return deptList;
        }
        
        return [];
      } else {
        print("❌ API ERROR: ${response.statusCode}");
        return [];
      }
    } on FormatException catch (e) {
      print("❌ FORMAT EXCEPTION: $e");
      return [];
    } catch (e) {
      print("❌ EXCEPTION: $e");
      return [];
    }
  }

  /// Create new department
  static Future<Map<String, dynamic>> createDepartment({
    required String deptName,
    required String deptCode,
    required String deptDesc,
    required String orgId,
    required String orgStatus,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/department/create/');
      
      final requestBody = {
        'deptName': deptName,
        'deptCode': deptCode,
        'deptDesc': deptDesc,
        'orgId': orgId,
        'orgStatus': orgStatus,
      };

      print('🌐 Creating department at: $url');
      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            url,
            headers: _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(timeoutDuration);

      print('📡 Response Status: ${response.statusCode}');
      
      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print('❌ NGrok HTML Error Received');
        return {
          'success': false,
          'message': 'Backend server not accessible via ngrok. Please check if backend is running.',
          'html_error': true,
        };
      }
      
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Department created successfully!');
        
        return {
          'success': true,
          'message': 'Department created successfully',
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid request data',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized: Please login again',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create department: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timeout',
      };
    } catch (e) {
      print('❌ Error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Update department
  static Future<bool> updateDepartment(String id, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse("$baseUrl/department/update/$id/");
      
      print("🌐 Updating department: $id");
      
      final response = await http
          .put(
            url,
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(timeoutDuration);

      print("📡 Response Status: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");
      
      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print('❌ NGrok HTML Error Received');
        return false;
      }
      
      // Accept both 200 (OK) and 201 (Created) as success
      final isSuccess = response.statusCode == 200 || response.statusCode == 201;
      
      if (isSuccess) {
        print('✅ Department update successful (${response.statusCode})');
      } else {
        print('❌ Department update failed with status: ${response.statusCode}');
      }
      
      return isSuccess;
    } catch (e) {
      print("❌ Error updating department: $e");
      return false;
    }
  }

  /// Delete department
  static Future<bool> deleteDepartment(String id) async {
    try {
      final url = Uri.parse("$baseUrl/department/delete/$id/");
      
      print("🗑️ Deleting department: $id");
      
      final response = await http
          .delete(url, headers: _getHeaders())
          .timeout(timeoutDuration);

      print("📡 Response Status: ${response.statusCode}");
      
      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print('❌ NGrok HTML Error Received');
        return false;
      }
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("❌ Error deleting department: $e");
      return false;
    }
  }

  // ============================================================================
  // TEST METHODS
  // ============================================================================

  /// Test connection to backend
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print("🔍 Testing backend connection...");
      
      // First try department endpoint
      final url = Uri.parse("$baseUrl/department/fetch/");
      
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(Duration(seconds: 10));

      if (_isHtmlResponse(response.body)) {
        return {
          'success': false,
          'message': 'NGrok HTML page received',
          'details': 'Backend server is not running or ngrok is misconfigured',
          'troubleshooting': 'Start backend server and restart ngrok tunnel',
        };
      } else if (response.statusCode == 200) {
        return {
          'success': true,
          'message': '✅ Backend is accessible via ngrok',
          'status': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': '❌ Backend returned error: ${response.statusCode}',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Connection failed: ${e.toString()}',
      };
    }
  }

  /// Quick local test (for development)
  static Future<void> testLocalBackend() async {
    print("🔍 Testing local backend endpoints...");
    
    // Common backend ports
    List<int> ports = [8080, 8000, 3000, 5000, 9000];
    
    for (var port in ports) {
      try {
        final localUrl = Uri.parse("http://localhost:$port/api/department/fetch/");
        print("Trying port $port: $localUrl");
        
        final response = await http
            .get(localUrl)
            .timeout(Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          print("✅ Found backend on port $port!");
          print("💡 Update ngrok: ngrok http http://localhost:$port");
          return;
        }
      } catch (e) {
        // Continue to next port
      }
    }
    
    print("❌ Could not find running backend on common ports.");
    print("💡 Please start your backend server first.");
  }
}