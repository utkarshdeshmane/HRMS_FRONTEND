import 'package:flutter/material.dart';
import '../services/organization_api_service.dart';

/// Test screen to demonstrate all Organization API endpoints
class OrganizationApiTestScreen extends StatefulWidget {
  @override
  _OrganizationApiTestScreenState createState() =>
      _OrganizationApiTestScreenState();
}

class _OrganizationApiTestScreenState extends State<OrganizationApiTestScreen> {
  String _output = "Ready to test APIs...";
  bool _isLoading = false;

  void _setOutput(String text) {
    setState(() {
      _output = text;
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  // Test Create Organization
  Future<void> _testCreateOrganization() async {
    _setLoading(true);
    _setOutput("Creating organization...");

    final result = await OrganizationApiService.createOrganization(
      orgName: "Test Organization ${DateTime.now().millisecond}",
      orgLocation: "Test City, Test Country",
      orgContact: "+1234567890",
      orgEmail: "test@organization.com",
      orgLink: "https://testorg.com",
      orgStatus: "Active",
    );

    _setLoading(false);
    _setOutput("CREATE RESULT:\n${result.toString()}");
  }

  // Test Fetch All Organizations
  Future<void> _testFetchOrganizations() async {
    _setLoading(true);
    _setOutput("Fetching all organizations...");

    try {
      final organizations = await OrganizationApiService.getOrganizations();
      _setLoading(false);
      _setOutput(
        "FETCH ALL RESULT:\nFound ${organizations.length} organizations\n\n${organizations.toString()}",
      );
    } catch (e) {
      _setLoading(false);
      _setOutput("ERROR: $e");
    }
  }

  // Test Fetch Organization by ID
  Future<void> _testFetchOrganizationById() async {
    _setLoading(true);
    _setOutput("Fetching organizations to get an ID...");

    try {
      final organizations = await OrganizationApiService.getOrganizations();
      
      if (organizations.isEmpty) {
        _setLoading(false);
        _setOutput("No organizations found. Create one first!");
        return;
      }

      final firstOrg = organizations[0];
      final orgId = firstOrg["_id"] ?? firstOrg["id"];

      if (orgId == null) {
        _setLoading(false);
        _setOutput("Organization ID not found in response");
        return;
      }

      _setOutput("Fetching organization by ID: $orgId");
      
      final org = await OrganizationApiService.getOrganizationById(
        orgId.toString(),
      );

      _setLoading(false);
      _setOutput("FETCH BY ID RESULT:\n${org.toString()}");
    } catch (e) {
      _setLoading(false);
      _setOutput("ERROR: $e");
    }
  }

  // Test Update Organization
  Future<void> _testUpdateOrganization() async {
    _setLoading(true);
    _setOutput("Fetching organizations to get an ID...");

    try {
      final organizations = await OrganizationApiService.getOrganizations();
      
      if (organizations.isEmpty) {
        _setLoading(false);
        _setOutput("No organizations found. Create one first!");
        return;
      }

      final firstOrg = organizations[0];
      final orgId = firstOrg["_id"] ?? firstOrg["id"];

      if (orgId == null) {
        _setLoading(false);
        _setOutput("Organization ID not found in response");
        return;
      }

      _setOutput("Updating organization: $orgId");

      final updateData = {
        "orgName": "Updated Organization ${DateTime.now().millisecond}",
        "orgLocation": "Updated Location",
        "orgContact": "+9876543210",
        "orgEmail": "updated@organization.com",
        "orgLink": "https://updated.com",
        "orgStatus": "Active",
      };

      final result = await OrganizationApiService.updateOrganization(
        orgId.toString(),
        updateData,
      );

      _setLoading(false);
      _setOutput("UPDATE RESULT:\n${result.toString()}");
    } catch (e) {
      _setLoading(false);
      _setOutput("ERROR: $e");
    }
  }

  // Test Delete Organization
  Future<void> _testDeleteOrganization() async {
    _setLoading(true);
    _setOutput("Fetching organizations to get an ID...");

    try {
      final organizations = await OrganizationApiService.getOrganizations();
      
      if (organizations.isEmpty) {
        _setLoading(false);
        _setOutput("No organizations found. Create one first!");
        return;
      }

      // Get the last organization to delete
      final lastOrg = organizations[organizations.length - 1];
      final orgId = lastOrg["_id"] ?? lastOrg["id"];

      if (orgId == null) {
        _setLoading(false);
        _setOutput("Organization ID not found in response");
        return;
      }

      _setOutput("Deleting organization: $orgId");

      final result = await OrganizationApiService.deleteOrganization(
        orgId.toString(),
      );

      _setLoading(false);
      _setOutput("DELETE RESULT:\n${result.toString()}");
    } catch (e) {
      _setLoading(false);
      _setOutput("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organization API Test"),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Column(
        children: [
          // Output Display
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        _output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),

          // Test Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTestButton(
                  "1. Create Organization",
                  Icons.add_circle,
                  Colors.green,
                  _testCreateOrganization,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  "2. Fetch All Organizations",
                  Icons.list,
                  Colors.blue,
                  _testFetchOrganizations,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  "3. Fetch Organization by ID",
                  Icons.search,
                  Colors.purple,
                  _testFetchOrganizationById,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  "4. Update Organization",
                  Icons.edit,
                  Colors.orange,
                  _testUpdateOrganization,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  "5. Delete Organization",
                  Icons.delete,
                  Colors.red,
                  _testDeleteOrganization,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
