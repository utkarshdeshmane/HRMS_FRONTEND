import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
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

  // ========== Admin Login ==========
  Future<Map<String, dynamic>?> adminLogin(String email, String password) async {
    print("=" * 80);
    print("🔐 ADMIN LOGIN API CALL STARTED");
    print("=" * 80);
    
    try {
      // Use the employee login endpoint
      final url = Uri.parse("${baseUrl}api/employee/login/");
      final headers = await getHeaders();
      
      final body = json.encode({
        "email": email,
        "password": password,
      });

      print("📡 Sending login request to: $url");
      print("📧 Email: $email");
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print("📥 RESPONSE RECEIVED");
      print("📊 Status Code: ${response.statusCode}");
      print("📄 Response Body: ${response.body}");
      print("=" * 80);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Handle your backend's response format
        if (data != null) {
          // Check for your backend's JWT format (accessToken/refreshToken)
          if (data['accessToken'] != null) {
            return {
              'success': true,
              'message': data['message'] ?? 'Login successful',
              'token': data['accessToken'],
              'refresh_token': data['refreshToken'],
              'user': data['data'] ?? data,
              'role': data['role'],
              'isAuthenticated': data['isAuthenticated'],
            };
          }
          // Check for standard JWT token format
          else if (data['access'] != null) {
            return {
              'success': true,
              'message': 'Login successful',
              'token': data['access'],
              'refresh_token': data['refresh'],
              'user': data,
            };
          }
          // Check for custom token format
          else if (data['token'] != null) {
            return {
              'success': true,
              'message': data['message'] ?? 'Login successful',
              'token': data['token'],
              'user': data['user'] ?? data,
            };
          }
          // Check for success flag
          else if (data['success'] == true || data['status'] == 'success') {
            return {
              'success': true,
              'message': data['message'] ?? 'Login successful',
              'token': data['token'],
              'user': data['user'] ?? data['data'] ?? data,
            };
          }
          // Default success response
          else {
            return {
              'success': true,
              'message': data['message'] ?? 'Login successful',
              'user': data,
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid response format from server',
          };
        }
      } else {
        // Handle error responses
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Invalid email or password';
          
          // Handle different error response formats
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['non_field_errors'] != null) {
            errorMessage = errorData['non_field_errors'][0];
          }
          
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid email or password',
          };
        }
      }
    } catch (e, stackTrace) {
      print("❌ LOGIN EXCEPTION: $e");
      print("📍 STACK TRACE: $stackTrace");
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }

    return null;
  }

  // ========== Employee Login ==========
  Future<Map<String, dynamic>?> employeeLogin(String email, String password) async {
    return adminLogin(email, password); // Same endpoint for both
  }

  // ========== Logout ==========
  Future<bool> logout() async {
    try {
      print("🚪 LOGOUT: Clearing session data");
      
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all authentication data
      await prefs.remove('auth_token');
      await prefs.remove('is_logged_in');
      await prefs.remove('user_role');
      await prefs.remove('user_email');
      
      print("✅ LOGOUT: Session cleared successfully");
      return true;
    } catch (e) {
      print("❌ LOGOUT ERROR: $e");
      return false;
    }
  }

  // ========== Check Authentication Status ==========
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final token = prefs.getString('auth_token');
      
      return isLoggedIn && (token != null || true);
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  // ========== Get Current User Role ==========
  Future<String?> getCurrentUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role');
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  // ========== Get Current User Email ==========
  Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email');
    } catch (e) {
      print("Error getting user email: $e");
      return null;
    }
  }
}