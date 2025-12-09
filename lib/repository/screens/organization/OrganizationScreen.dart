import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blinkit/repository/screens/services/organization_api_service.dart';
import '../sidebar/hrms_sidebar.dart';

class OrganizationScreen extends StatefulWidget {
  @override
  _OrganizationScreenState createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedStatus = 'Active';
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> submitOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    final result = await OrganizationApiService.createOrganization(
      orgName: _nameController.text,
      orgLocation: _locationController.text,
      orgContact: _contactController.text,
      orgEmail: _emailController.text,
      orgLink: _linkController.text,
      orgStatus: _selectedStatus,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Organization created successfully")),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      clearFields();
      Navigator.pop(context); // Return to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(result["message"] ?? "Something went wrong"),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void clearFields() {
    _nameController.clear();
    _locationController.clear();
    _contactController.clear();
    _emailController.clear();
    _linkController.clear();
    _selectedStatus = "Active";
    setState(() {});
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF44336), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isSmallScreen ? 14 : 16,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.toggle_on_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            color: Colors.black87,
          ),
          dropdownColor: Colors.white,
          items: ["Active", "Inactive"].map((e) {
            return DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e == "Active"
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(e),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedStatus = val!),
        ),
      ),
    );
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
        backgroundColor: const Color(0xFF2196F3),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Organization",
          style: TextStyle(
            fontSize: isSmallScreen ? 17 : 19,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header Card with Icon
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF1976D2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 36 : 42,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Organization Registration",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fill all required fields below",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Form Fields
                  _inputField(
                    label: "Organization Name *",
                    icon: Icons.business_center_rounded,
                    controller: _nameController,
                    validator: (v) => 
                        v!.isEmpty ? "Enter organization name" : null,
                  ),

                  _inputField(
                    label: "Location *",
                    icon: Icons.location_on_rounded,
                    controller: _locationController,
                    validator: (v) => v!.isEmpty ? "Enter location" : null,
                  ),

                  _inputField(
                    label: "Contact Number",
                    icon: Icons.phone_rounded,
                    controller: _contactController,
                    keyboard: TextInputType.phone,
                  ),

                  _inputField(
                    label: "Email *",
                    icon: Icons.email_rounded,
                    controller: _emailController,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter email";
                      if (!RegExp(r".+@.+\..+").hasMatch(v)) {
                        return "Invalid email format";
                      }
                      return null;
                    },
                  ),

                  _inputField(
                    label: "Website Link",
                    icon: Icons.link_rounded,
                    controller: _linkController,
                    keyboard: TextInputType.url,
                  ),

                  _statusDropdown(),

                  const SizedBox(height: 8),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 50 : 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitOrganization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF2196F3).withOpacity(0.4),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  "Create Organization",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Clear Button
                  SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 46 : 52,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : clearFields,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Clear All Fields",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}