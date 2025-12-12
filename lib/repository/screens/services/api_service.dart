import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";
  // static const String baseUrl = "https://distillatory-neoma-unmoldy.ngrok-free.dev/"

  // Replace this with your real JWT
  static const String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbXBJZCI6IjY5Mjk0ZGYxYWI5ZmI3YWE0MmJjZWY4ZiIsInJvbGUiOiJhZG1pbiIsImV4cCI6MTc2NTQzNzAyNiwiaWF0IjoxNzY0ODMyMjI2fQ.70DG833hoc8bKfRJpSd-eMQbt7C0C5tJVDS7kjGsEI0";

  // ============================
  // CREATE ORGANIZATION API
  // ============================
  static Future<Map<String, dynamic>> createOrganization({
    required String orgName,
    required String orgLocation,
    required String orgContact,
    required String orgEmail,
    required String orgLink,
    required String orgStatus,
  }) async {
    final url = Uri.parse("$baseUrl/organization/create/");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "orgName": orgName,
        "orgLocation": orgLocation,
        "orgContact": orgContact,
        "orgEmail": orgEmail,
        "orgLink": orgLink,
        "orgStatus": orgStatus,
      }),
    );

    final decoded = jsonDecode(response.body);

    return {
      "success": response.statusCode == 200 || response.statusCode == 201,
      "data": decoded,
    };
  }

  // ============================
  // FETCH ORGANIZATIONS API
  // ============================
    static Future<List<dynamic>> getOrganizations() async {
    try {
      final url = Uri.parse("$baseUrl/organization/fetch/");
      final response = await http.get(url,
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
      );

      print("RAW API RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print("DECODED RESPONSE: $decoded");

        // Extract list from "results"
        return decoded["results"] ?? [];
      } else {
        print("API ERROR: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("EXCEPTION: $e");
      return [];
    }
  }
}
  
