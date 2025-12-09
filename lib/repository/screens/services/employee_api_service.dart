import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  static const String baseUrl = "https://distillatory-neoma-unmoldy.ngrok-free.dev/";
  
  // TODO: UPDATE THIS TOKEN - Get fresh token from your backend login API
  // Current token is expired (exp: 1765437026 = Feb 2025)
  // To get new token: Login to your backend and copy the JWT token
  static const String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBJZCI6IjY5Mjk0ZGYxYWI5ZmI3YWE0MmJjZWY4ZiIsInJvbGUiOiJhZG1pbiIsImV4cCI6MTc2NTQzNzAyNiwiaWF0IjoxNzY0ODMyMjI2fQ.70DG833hoc8bKfRJpSd-eMQbt7C0C5tJVDS7kjGsEI0";

  static Map<String, String> getHeaders() {
    return {
      "Content-Type": "application/json",
      // "Authorization": "Bearer $token",
      "Accept": "application/json",
      "ngrok-skip-browser-warning": "true",
    };
  }

  // Helper to get employee ID
  static String? getEmployeeId(dynamic employee) {
    return employee['id']?.toString() ?? employee['_id']?.toString();
  }

  // ========== Get ALL dropdown data from employee/fetch endpoint ==========
  Future<Map<String, dynamic>> getDropdowns() async {
    print("📡 FETCHING ALL DROPDOWN DATA FROM EMPLOYEE API");
    
    Map<String, dynamic> dropdownData = {
      "organizations": [],
      "departments": [],
      "shifts": [],
      "reportingManagers": []
    };
    
    try {
      final url = Uri.parse("${baseUrl}api/employee/fetch/");
      print("   URL: $url");
      print("   Headers: ${getHeaders()}");
      
      final response = await http.get(url, headers: getHeaders());
      
      print("   Status: ${response.statusCode}");
      print("   Response length: ${response.body.length}");
      
      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          print("   Decoded type: ${decoded.runtimeType}");
          print("   Available keys: ${decoded.keys.toList()}");
          
          // Extract organizations
          if (decoded.containsKey("organizations")) {
            dropdownData["organizations"] = decoded["organizations"] ?? [];
          }
          
          // Extract departments
          if (decoded.containsKey("departments")) {
            dropdownData["departments"] = decoded["departments"] ?? [];
          }
          
          // Extract shifts
          if (decoded.containsKey("shifts")) {
            dropdownData["shifts"] = decoded["shifts"] ?? [];
          }
          
          // Extract reporting managers
          if (decoded.containsKey("reportingManagers")) {
            dropdownData["reportingManagers"] = decoded["reportingManagers"] ?? [];
          }
          
          print("\n✅ SUCCESSFULLY EXTRACTED DROPDOWN DATA:");
          print("   Organizations: ${dropdownData["organizations"].length}");
          if (dropdownData["organizations"].isNotEmpty) {
            print("   Sample: ${dropdownData["organizations"].take(2).map((o) => "${o["orgName"]} (id: ${o["id"]})").toList()}");
          }
          
          print("   Departments: ${dropdownData["departments"].length}");
          if (dropdownData["departments"].isNotEmpty) {
            print("   Sample: ${dropdownData["departments"].take(2).map((d) => "${d["deptName"]} (id: ${d["id"]})").toList()}");
          }
          
          print("   Shifts: ${dropdownData["shifts"].length}");
          if (dropdownData["shifts"].isNotEmpty) {
            print("   Sample: ${dropdownData["shifts"].take(2).map((s) => "${s["shiftType"]} (id: ${s["id"]})").toList()}");
          }
          
          print("   Reporting Managers: ${dropdownData["reportingManagers"].length}");
          if (dropdownData["reportingManagers"].isNotEmpty) {
            print("   Sample: ${dropdownData["reportingManagers"].take(2).map((m) => "${m["firstName"]} (id: ${m["id"]})").toList()}");
          }
          
          // If any dropdown is empty, check if data might be in different format
          if (dropdownData["organizations"].isEmpty || 
              dropdownData["departments"].isEmpty ||
              dropdownData["shifts"].isEmpty) {
            
            print("\n⚠️ WARNING: Some dropdowns are empty. Checking alternative structures...");
            
            // Try to find data in different keys
            final keys = decoded.keys.toList();
            print("   All available keys in response: $keys");
            
            // Check if there's a nested structure
            for (var key in keys) {
              print("   Checking key '$key': ${decoded[key].runtimeType}");
            }
          }
          
        } catch (e) {
          print("   ❌ JSON decode error: $e");
          print("   Raw response (first 500 chars): ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}");
        }
      } else {
        print("❌ API call failed: ${response.statusCode}");
        print("   Error body: ${response.body}");
        
        // Try alternative endpoints if main endpoint fails
        print("\n🔄 Trying alternative endpoints...");
        return await _getDropdownsFromSeparateEndpoints();
      }
      
      return dropdownData;
      
    } catch (e, stackTrace) {
      print("\n❌ EXCEPTION in getDropdowns: $e");
      print("📍 STACK TRACE: $stackTrace");
      
      // Fallback to separate endpoints
      return await _getDropdownsFromSeparateEndpoints();
    }
  }

  // Fallback method to get data from separate endpoints
  Future<Map<String, dynamic>> _getDropdownsFromSeparateEndpoints() async {
    print("\n🔄 FALLBACK: Fetching from separate endpoints...");
    
    Map<String, dynamic> dropdownData = {
      "organizations": [],
      "departments": [],
      "shifts": [],
      "reportingManagers": []
    };
    
    try {
      // Fetch Organizations separately
      final orgUrl = Uri.parse("${baseUrl}api/organization/fetch/");
      final orgResponse = await http.get(orgUrl, headers: getHeaders());
      
      if (orgResponse.statusCode == 200) {
        final orgDecoded = json.decode(orgResponse.body);
        if (orgDecoded is List) {
          dropdownData["organizations"] = orgDecoded;
        } else if (orgDecoded is Map && orgDecoded.containsKey("data")) {
          dropdownData["organizations"] = orgDecoded["data"] ?? [];
        }
      }
      
      // Fetch Departments separately
      final deptUrl = Uri.parse("${baseUrl}api/department/fetch/");
      final deptResponse = await http.get(deptUrl, headers: getHeaders());
      
      if (deptResponse.statusCode == 200) {
        final deptDecoded = json.decode(deptResponse.body);
        if (deptDecoded is List) {
          dropdownData["departments"] = deptDecoded;
        } else if (deptDecoded is Map && deptDecoded.containsKey("data")) {
          dropdownData["departments"] = deptDecoded["data"] ?? [];
        }
      }
      
      // Try to get shifts from employee data
      final empUrl = Uri.parse("${baseUrl}api/employee/fetch/");
      final empResponse = await http.get(empUrl, headers: getHeaders());
      
      if (empResponse.statusCode == 200) {
        final empDecoded = json.decode(empResponse.body);
        
        // Extract employees for reporting managers
        List<dynamic> employees = [];
        if (empDecoded is Map) {
          employees = empDecoded["results"] ?? empDecoded["data"] ?? [];
        } else if (empDecoded is List) {
          employees = empDecoded;
        }
        
        // Create reporting managers from employees
        List<Map<String, dynamic>> managers = [];
        for (var emp in employees) {
          if (emp is Map) {
            String? firstName = emp["firstName"]?.toString() ?? emp["first_name"]?.toString();
            String? id = emp["id"]?.toString() ?? emp["_id"]?.toString();
            
            if (id != null && firstName != null) {
              managers.add({
                "id": id,
                "firstName": firstName,
              });
            }
          }
        }
        dropdownData["reportingManagers"] = managers;
      }
      
      print("✅ Fallback data loaded:");
      print("   Organizations: ${dropdownData["organizations"].length}");
      print("   Departments: ${dropdownData["departments"].length}");
      print("   Reporting Managers: ${dropdownData["reportingManagers"].length}");
      
    } catch (e) {
      print("❌ Fallback also failed: $e");
    }
    
    return dropdownData;
  }

  // ========== Get employees only ==========
  Future<List<dynamic>> getEmployees() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/fetch/");
      final response = await http.get(url, headers: getHeaders());

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
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

  // ========== Static method for backward compatibility ==========
  static Future<Map<String, dynamic>> getEmployeeWithDropdowns() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/fetch/");
      final response = await http.get(url, headers: getHeaders());

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // Ensure the response has the expected structure
        Map<String, dynamic> result = {
          "results": [],
          "organizations": [],
          "departments": [],
          "shifts": [],
          "reportingManagers": []
        };
        
        if (decoded is Map) {
          result["results"] = decoded["results"] ?? decoded["data"] ?? [];
          result["organizations"] = decoded["organizations"] ?? [];
          result["departments"] = decoded["departments"] ?? [];
          result["shifts"] = decoded["shifts"] ?? [];
          result["reportingManagers"] = decoded["reportingManagers"] ?? [];
        }
        
        return result;
      } else {
        return {
          "results": [],
          "organizations": [],
          "departments": [],
          "shifts": [],
          "reportingManagers": []
        };
      }
    } catch (e) {
      print("❌ EXCEPTION in getEmployeeWithDropdowns: $e");
      return {
        "results": [],
        "organizations": [],
        "departments": [],
        "shifts": [],
        "reportingManagers": []
      };
    }
  }

  // ========== Fetch Shifts from Employee API ==========
  Future<List<dynamic>> getShifts() async {
    try {
      print("📡 Fetching shifts from employee API...");
      final url = Uri.parse("${baseUrl}api/employee/fetch/");
      final response = await http.get(url, headers: getHeaders());

      print("   Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        if (decoded is Map) {
          // Check for shifts in the response
          if (decoded.containsKey("shifts")) {
            print("✅ Found shifts in response");
            return decoded["shifts"] is List ? decoded["shifts"] : [];
          }
          
          // If employees have shift data, extract unique shifts
          final employees = decoded["data"] ?? decoded["results"] ?? [];
          if (employees is List && employees.isNotEmpty) {
            Set<String> seenIds = {};
            List<Map<String, dynamic>> uniqueShifts = [];
            
            for (var emp in employees) {
              if (emp is Map) {
                // Check for shift data in employee
                if (emp.containsKey("shiftId") && emp.containsKey("shiftType")) {
                  String shiftId = emp["shiftId"].toString();
                  if (!seenIds.contains(shiftId)) {
                    seenIds.add(shiftId);
                    uniqueShifts.add({
                      "id": shiftId,
                      "shiftType": emp["shiftType"],
                    });
                  }
                } else if (emp.containsKey("shift")) {
                  // If shift is an object
                  var shift = emp["shift"];
                  if (shift is Map && shift.containsKey("id")) {
                    String shiftId = shift["id"].toString();
                    if (!seenIds.contains(shiftId)) {
                      seenIds.add(shiftId);
                      uniqueShifts.add({
                        "id": shiftId,
                        "shiftType": shift["shiftType"] ?? shift["type"] ?? "Unknown",
                      });
                    }
                  }
                }
              }
            }
            
            print("✅ Extracted ${uniqueShifts.length} unique shifts from employees");
            return uniqueShifts;
          }
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
      final response = await http.get(url, headers: getHeaders());

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final employees = decoded["data"] ?? decoded["results"] ?? [];
        
        List<Map<String, dynamic>> managers = [];
        
        if (employees is List) {
          for (var emp in employees) {
            if (emp is Map) {
              String? role = emp["role"]?.toString();
              String? firstName = emp["firstName"]?.toString() ?? emp["first_name"]?.toString();
              String? lastName = emp["lastName"]?.toString() ?? emp["last_name"]?.toString();
              String? id = emp["id"]?.toString() ?? emp["_id"]?.toString();
              
              if (id != null && firstName != null) {
                // Include managers, admins, and HR as potential reporting managers
                bool isManager = role == "manager" || role == "admin" || role == "hr";
                if (isManager) {
                  String fullName = "$firstName ${lastName ?? ''}".trim();
                  
                  managers.add({
                    "id": id,
                    "firstName": fullName,
                    "role": role ?? "employee"
                  });
                }
              }
            }
          }
        }
        
        print("✅ Found ${managers.length} reporting managers");
        return managers;
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
    Map<String, dynamic> formData, Map<String, File?> docs) async {
    print("=" * 80);
    print("🔵 CREATE EMPLOYEE API CALL STARTED");
    print("=" * 80);
    
    try {
      final url = Uri.parse("${baseUrl}api/employee/create/");
      
      print("Preparing employee data...");
      print("Form data keys: ${formData.keys.toList()}");
      
      // Use multipart form data (backend expects this format)
      var request = http.MultipartRequest("POST", url);
      request.headers["Accept"] = "application/json";
      request.headers["ngrok-skip-browser-warning"] = "true";
      
      formData.forEach((key, value) {
        if (value != null) {
          if (value is Map) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });
      
      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print("📡 Request sent to: $url");

      print("\n📥 RESPONSE RECEIVED");
      print("📊 Status Code: ${response.statusCode}");
      print("📄 Response Body: ${response.body}");
      print("=" * 80);

      return response;
    } catch (e, stackTrace) {
      print("\n❌ CREATE EMPLOYEE EXCEPTION: $e");
      return http.Response(
        json.encode({"error": e.toString()}), 
        500
      );
    }
  }

  // Delete Employee
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/delete/$employeeId/");
      final response = await http.delete(url, headers: getHeaders());

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("❌ DELETE EXCEPTION: $e");
      return false;
    }
  }

  // Update Employee
  Future<Map<String, dynamic>?> updateEmployee(
      String employeeId, Map<String, dynamic> employeeData) async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/update/$employeeId/");
      final response = await http.put(
        url,
        headers: getHeaders(),
        body: json.encode(employeeData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("❌ UPDATE EXCEPTION: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLoggedEmployee() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/profile/");
      final response = await http.get(url, headers: getHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("Profile Error: $e");
      return null;
    }
  }

  // Check-In API
  Future<bool> checkIn() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/checkin/");
      final response = await http.post(url, headers: getHeaders());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("CheckIn Error: $e");
      return false;
    }
  }

  // Check-Out API
  Future<bool> checkOut() async {
    try {
      final url = Uri.parse("${baseUrl}api/employee/checkout/");
      final response = await http.post(url, headers: getHeaders());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("CheckOut Error: $e");
      return false;
    }
  }
}
