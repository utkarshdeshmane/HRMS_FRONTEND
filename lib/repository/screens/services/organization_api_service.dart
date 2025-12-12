import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

class OrganizationApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";
  // static const String baseUrl = "https://distillatory-neoma-unmoldy.ngrok-free.dev/api";
  
  // JWT Token
  static const String token = "";

  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Get common headers
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Add this for ngrok
    };
  }

  // ============================================================================
  // HELPER: Check if response is HTML/ngrok error
  // ============================================================================
  static bool _isHtmlResponse(String body) {
    return body.trim().startsWith('<!DOCTYPE') || 
           body.contains('<html>') || 
           body.contains('ngrok') ||
           body.contains('DOCTYPE');
  }

  // ============================================================================
  // CREATE ORGANIZATION
  // ============================================================================
  
  /// Create new organization
  static Future<Map<String, dynamic>> createOrganization({
    required String orgName,
    required String orgLocation,
    required String orgContact,
    required String orgEmail,
    required String orgLink,
    required String orgStatus,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/organization/create/');
      
      final requestBody = {
        'orgName': orgName,
        'orgLocation': orgLocation,
        'orgContact': orgContact,
        'orgEmail': orgEmail,
        'orgLink': orgLink,
        'orgStatus': orgStatus,
      };

      print('🌐 Creating organization at: $url');
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
        print('💡 First 300 chars: ${response.body.substring(0, min(response.body.length, 300))}');
        return {
          'success': false,
          'message': 'Backend server not accessible via ngrok. Please check if backend is running.',
          'html_error': true,
        };
      }
      
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Organization created successfully!');
        
        return {
          'success': true,
          'message': 'Organization created successfully',
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
          'message': 'Failed to create organization: ${response.statusCode}',
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

  // ============================================================================
  // FETCH ALL ORGANIZATIONS
  // ============================================================================
  
  /// Fetch all organizations
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
        
        // Detailed troubleshooting instructions
        print("\n🔧 TROUBLESHOOTING STEPS:");
        print("1. Ensure your backend server is running (Spring Boot/Django/Node.js)");
        print("2. Check if ngrok is pointing to correct port");
        print("3. Verify the API endpoint exists locally: http://localhost:your-port/api/organization/fetch/");
        print("4. Stop and restart ngrok tunnel");
        print("\n💡 QUICK FIX: Stop current ngrok and run:");
        print("   ngrok http http://localhost:8080 --host-header=\"localhost:8080\"");
        
        throw Exception('NGROK_ERROR: Backend server not accessible. Check if backend is running and ngrok is properly configured.');
      }
      
      print("📦 Response Body: ${response.body.substring(0, min(response.body.length, 200))}...");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print("✅ DECODED RESPONSE TYPE: ${decoded.runtimeType}");
        print("✅ Response keys: ${decoded is Map ? decoded.keys.toList() : 'List with ${decoded.length} items'}");

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
          if (orgList.isEmpty && decoded.isNotEmpty) {
            // If it's a single organization object, wrap it in a list
            orgList = [decoded];
          }
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
      print("💡 Response was not valid JSON");
      throw Exception('Invalid response format from server');
    } catch (e) {
      print("❌ EXCEPTION: $e");
      throw Exception('Error loading organizations: ${e.toString()}');
    }
  }

  // ============================================================================
  // FETCH ORGANIZATION BY ID
  // ============================================================================
  
  /// Fetch single organization by ID
  static Future<Map<String, dynamic>?> getOrganizationById(String id) async {
    try {
      final url = Uri.parse("$baseUrl/organization/fetch/$id/");
      
      print("🌐 Fetching organization by ID: $id");
      
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(timeoutDuration);

      print("📡 Response Status: ${response.statusCode}");
      
      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print('❌ NGrok HTML Error Received');
        return null;
      }
      
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print("✅ Organization fetched successfully");
        return decoded;
      } else if (response.statusCode == 404) {
        print("❌ Organization not found");
        return null;
      } else {
        print("❌ API ERROR: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching organization: $e");
      return null;
    }
  }

  // ============================================================================
  // UPDATE ORGANIZATION
  // ============================================================================
  
  /// Update organization by ID
  static Future<Map<String, dynamic>> updateOrganization(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/organization/update/$id/");
      
      print("🌐 Updating organization: $id");
      print("📤 Update Data: ${json.encode(data)}");
      
      final response = await http
          .put(
            url,
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(timeoutDuration);

      print("📡 Response Status: ${response.statusCode}");
      
      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print('❌ NGrok HTML Error Received');
        return {
          'success': false,
          'message': 'Backend server not accessible via ngrok',
          'html_error': true,
        };
      }
      
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Organization updated successfully");
        return {
          'success': true,
          'message': 'Organization updated successfully',
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Organization not found',
        };
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid request data',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update organization: ${response.statusCode}',
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
      print("❌ Error updating organization: $e");
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================================
  // DELETE ORGANIZATION
  // ============================================================================
  
  /// Delete organization by ID
  static Future<Map<String, dynamic>> deleteOrganization(String id) async {
    try {
      final url = Uri.parse("$baseUrl/organization/delete/$id/");
      
      print("🗑️ Deleting organization: $id");
      
      final response = await http
          .delete(url, headers: _getHeaders())
          .timeout(timeoutDuration);

      print("📡 Response Status: ${response.statusCode}");
      
      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print('❌ NGrok HTML Error Received');
        return {
          'success': false,
          'message': 'Backend server not accessible via ngrok',
          'html_error': true,
        };
      }
      
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ Organization deleted successfully");
        return {
          'success': true,
          'message': 'Organization deleted successfully',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Organization not found',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete organization: ${response.statusCode}',
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
      print("❌ Error deleting organization: $e");
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================================
  // TEST CONNECTION
  // ============================================================================
  
  /// Test if backend is accessible via ngrok
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final url = Uri.parse("$baseUrl/organization/fetch/");
      
      print("🔍 Testing connection to: $url");
      
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(Duration(seconds: 10));

      if (_isHtmlResponse(response.body)) {
        return {
          'success': false,
          'message': 'NGrok HTML page received. Backend server is not running.',
          'status': 'HTML_RESPONSE',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connection successful',
          'status': 'CONNECTED',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Connection failed with status: ${response.statusCode}',
          'status': 'ERROR',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'status': 'EXCEPTION',
      };
    }
  }
}