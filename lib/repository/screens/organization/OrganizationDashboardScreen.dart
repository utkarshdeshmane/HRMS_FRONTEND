import 'package:blinkit/repository/screens/organization/OrganizationScreen.dart';
import 'package:blinkit/repository/screens/organization/ViewOrganizationScreen.dart';
import 'package:blinkit/repository/screens/organization/EditOrganizationScreen.dart';
import 'package:blinkit/repository/screens/sidebar/hrms_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/organization_api_service.dart';
import 'package:icons_plus/icons_plus.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  @override
  _OrganizationDashboardState createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboardScreen> {
  List<dynamic> organizations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrganizations();
  }

  Future<void> loadOrganizations() async {
    try {
      final data = await OrganizationApiService.getOrganizations();
      print("PRINT IN DASHBOARD: $data");

      setState(() {
        organizations = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading organizations: $e");
      setState(() {
        organizations = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      drawer: HRMSSidebar(),
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Organizations",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrganizationScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                "Add",
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
            )
          : organizations.isEmpty
              ? _buildEmptyState(screenWidth)
              : RefreshIndicator(
                  onRefresh: loadOrganizations,
                  color: const Color(0xFF2196F3),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: 16,
                    ),
                    itemCount: organizations.length,
                    itemBuilder: (_, index) {
                      final org = organizations[index];
                      return _buildOrganizationCard(
                        org,
                        screenWidth,
                        isSmallScreen,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: screenWidth * 0.25,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No Organizations Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the Add button to create one",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationCard(
    Map<String, dynamic> org,
    double screenWidth,
    bool isSmallScreen,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print("CARD TAPPED for ${org["orgName"]}");
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Name + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        org["orgName"] ?? "No Name",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(org["orgStatus"], isSmallScreen),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Organization Details
                _buildInfoRow(
                  Icons.location_on_rounded,
                  org["orgLocation"] ?? "-",
                  const Color(0xFFE91E63),
                  isSmallScreen,
                ),
                const SizedBox(height: 10),
                
                _buildInfoRow(
                  Icons.call_rounded,
                  org["orgContact"] ?? "-",
                  const Color(0xFF4CAF50),
                  isSmallScreen,
                ),
                const SizedBox(height: 10),
                
                _buildInfoRow(
                  Icons.email_rounded,
                  org["orgEmail"] ?? "-",
                  const Color(0xFF9C27B0),
                  isSmallScreen,
                ),
                const SizedBox(height: 10),
                
                _buildInfoRow(
                  Bootstrap.linkedin,
                  org["orgLink"] ?? "-",
                  const Color(0xFF0077B5),
                  isSmallScreen,
                  isUrl: true,
                ),
                
                const SizedBox(height: 16),
                
                // Divider
                Divider(
                  color: Colors.grey.shade200,
                  thickness: 1,
                ),
                
                const SizedBox(height: 8),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.visibility_rounded,
                      label: "View",
                      color: const Color(0xFF2196F3),
                      isSmallScreen: isSmallScreen,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewOrganizationScreen(
                              organization: org,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      label: "Edit",
                      color: const Color(0xFFFF9800),
                      isSmallScreen: isSmallScreen,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditOrganizationScreen(
                              organization: org,
                            ),
                          ),
                        );
                        
                        if (result == true && mounted) {
                          loadOrganizations();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      label: "Delete",
                      color: const Color(0xFFF44336),
                      isSmallScreen: isSmallScreen,
                      onPressed: () {
                        _showDeleteConfirmation(org);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status, bool isSmallScreen) {
    final isActive = status == "Active";
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 12,
        vertical: isSmallScreen ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4CAF50).withOpacity(0.15)
            : const Color(0xFFF44336).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFFF44336).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status ?? "Unknown",
            style: TextStyle(
              color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color iconColor,
    bool isSmallScreen, {
    bool isUrl = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isSmallScreen ? 16 : 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: const Color(0xFF424242),
                height: 1.4,
              ),
              maxLines: isUrl ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSmallScreen,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: isSmallScreen ? 16 : 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> org) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          org["orgName"] ?? "Organization Details",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfo("Location", org["orgLocation"]),
              _buildDialogInfo("Contact", org["orgContact"]),
              _buildDialogInfo("Email", org["orgEmail"]),
              _buildDialogInfo("Website", org["orgLink"]),
              _buildDialogInfo("Status", org["orgStatus"]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? "-",
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> org) {
    final nameController = TextEditingController(text: org["orgName"]);
    final locationController = TextEditingController(text: org["orgLocation"]);
    final contactController = TextEditingController(text: org["orgContact"]);
    final emailController = TextEditingController(text: org["orgEmail"]);
    final linkController = TextEditingController(text: org["orgLink"]);
    String selectedStatus = org["orgStatus"] ?? "Active";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit Organization",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Organization Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: "Contact",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: "Website Link",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
                items: ["Active", "Inactive"].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedStatus = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final orgId = org["_id"] ?? org["id"];
              if (orgId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Organization ID not found"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final updateData = {
                "orgName": nameController.text,
                "orgLocation": locationController.text,
                "orgContact": contactController.text,
                "orgEmail": emailController.text,
                "orgLink": linkController.text,
                "orgStatus": selectedStatus,
              };

              final result = await OrganizationApiService.updateOrganization(
                orgId.toString(),
                updateData,
              );

              if (result["success"]) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text("Organization updated successfully"),
                      ],
                    ),
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                );
                loadOrganizations();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result["message"] ?? "Update failed"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> org) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Organization",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Are you sure you want to delete ${org["orgName"]}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final orgId = org["_id"] ?? org["id"];
              if (orgId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Organization ID not found"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final result = await OrganizationApiService.deleteOrganization(
                orgId.toString(),
              );

              if (result["success"]) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text("Organization deleted successfully"),
                      ],
                    ),
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                );
                loadOrganizations();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result["message"] ?? "Delete failed"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}