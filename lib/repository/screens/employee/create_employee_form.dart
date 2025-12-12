import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/employee_api_service.dart';
import '../services/organization_api_service.dart';
import '../services/department_api_service.dart';
import '../utils/platform_file.dart';

class CreateEmployeeForm extends StatefulWidget {
  @override
  _CreateEmployeeFormState createState() => _CreateEmployeeFormState();
}

class _CreateEmployeeFormState extends State<CreateEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService employeeService = ApiService();
  bool _isLoading = false;
  bool _isSameAddress = false;
  bool _dropdownsLoaded = false;
  String? _dropdownError;

  // Text Controllers - Personal Info
  final firstName = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final mobileNumber = TextEditingController();
  final dob = TextEditingController();
  final doj = TextEditingController();
  final designationId = TextEditingController();

  // Current Address
  final street = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final zip = TextEditingController();
  final country = TextEditingController();

  // Permanent Address
  final pStreet = TextEditingController();
  final pCity = TextEditingController();
  final pState = TextEditingController();
  final pZip = TextEditingController();
  final pCountry = TextEditingController();

  // Dropdown Values
  String? selectedGender;
  String? selectedStatus;
  String? selectedRole;
  String? selectedOrg;
  String? selectedDept;
  String? selectedShift;
  String? selectedReportingManager;

  // Dropdown Data
  List<dynamic> organizations = [];
  List<dynamic> departments = [];
  List<dynamic> shifts = [];
  List<dynamic> reportingManagers = [];

  // Document Files
  CustomPlatformFile? adharCard;
  CustomPlatformFile? panCard;
  CustomPlatformFile? bankBook;
  CustomPlatformFile? xStandardMarksheet;
  CustomPlatformFile? xiiStandardMarksheet;
  CustomPlatformFile? degree;
  CustomPlatformFile? experienceLetter;
  CustomPlatformFile? photo;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    print('🔄 FORM: Starting to load dropdown data...');
    setState(() {
      _isLoading = true;
      _dropdownsLoaded = false;
      _dropdownError = null;
    });
    
    try {
      // Use the working API services directly
      print('📡 FORM: Fetching organizations using OrganizationApiService...');
      final orgs = await OrganizationApiService.getOrganizations();
      
      print('📡 FORM: Fetching departments using DepartmentApiService...');
      final depts = await DepartmentApiService.getDepartments();
      
      print('📡 FORM: Fetching shifts from employee API...');
      final shfts = await employeeService.getShifts();
      
      print('📡 FORM: Fetching reporting managers from employee API...');
      final mgrs = await employeeService.getReportingManagers();
      
      print('📦 FORM: Organizations received: ${orgs.length}');
      print('📦 FORM: Departments received: ${depts.length}');
      print('📦 FORM: Shifts received: ${shfts.length}');
      print('📦 FORM: Managers received: ${mgrs.length}');
      
      setState(() {
        organizations = orgs;
        departments = depts;
        shifts = shfts;
        reportingManagers = mgrs;
        _isLoading = false;
        _dropdownsLoaded = true;
      });
      
      print('✅ FORM: Dropdown data loaded successfully!');
      print('   Organizations: ${organizations.length} items');
      print('   Departments: ${departments.length} items');
      print('   Shifts: ${shifts.length} items');
      print('   Managers: ${reportingManagers.length} items');
      
      // Show warning if no organizations or departments
      if (organizations.isEmpty || departments.isEmpty) {
        String errorMsg = "";
        if (organizations.isEmpty && departments.isEmpty) {
          errorMsg = "No organizations and departments found. Please create them first.";
        } else if (organizations.isEmpty) {
          errorMsg = "No organizations found. Please create organizations first.";
        } else if (departments.isEmpty) {
          errorMsg = "No departments found. Please create departments first.";
        }
        
        setState(() {
          _dropdownError = errorMsg;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      
    } catch (e, stackTrace) {
      print('❌ FORM: Error loading dropdown data: $e');
      print('📍 FORM: Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        _dropdownsLoaded = false;
        _dropdownError = "Failed to load form data: ${e.toString()}";
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load form data. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Pick document files (PDF, DOC, images, etc.)
  Future<CustomPlatformFile?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true, // Always load file data for cross-platform compatibility
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = CustomPlatformFile.fromPickerFile(result.files.first);
        if (pickedFile != null) {
          _showSnackBar("Document selected: ${pickedFile.name}");
          return pickedFile;
        }
      }
      return null;
    } catch (e) {
      print("❌ Error picking document: $e");
      _showSnackBar("Error picking document: $e", isError: true);
      return null;
    }
  }

  // Pick photo/image
  Future<CustomPlatformFile?> pickPhoto() async {
    try {
      if (kIsWeb) {
        // For web, use FilePicker for images too
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final pickedFile = CustomPlatformFile.fromPickerFile(result.files.first);
          if (pickedFile != null) {
            _showSnackBar("Photo selected: ${pickedFile.name}");
            return pickedFile;
          }
        }
        return null;
      } else {
        // For mobile/desktop, use ImagePicker
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          final platformFile = CustomPlatformFile(
            name: picked.name,
            path: picked.path,
            bytes: bytes,
            isWeb: false,
          );
          _showSnackBar("Photo selected: ${platformFile.name}");
          return platformFile;
        }
        return null;
      }
    } catch (e) {
      print("❌ Error picking photo: $e");
      _showSnackBar("Error picking photo: $e", isError: true);
      return null;
    }
  }

  void _copySameAddress(bool? value) {
    if (value == null) return;
    
    setState(() {
      _isSameAddress = value;
      if (_isSameAddress) {
        pStreet.text = street.text;
        pCity.text = city.text;
        pState.text = state.text;
        pZip.text = zip.text;
        pCountry.text = country.text;
      } else {
        // Clear permanent address if unchecked
        pStreet.clear();
        pCity.clear();
        pState.clear();
        pZip.clear();
        pCountry.clear();
      }
    });
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF6366F1),
        title: Text(
          "Create Employee",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_dropdownError != null || (!_isLoading && !_dropdownsLoaded))
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadDropdownData,
              tooltip: "Reload Data",
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _dropdownError != null && organizations.isEmpty
            ? _buildErrorScreen()
            : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show warning banner if dropdowns are empty
                      if (_dropdownError != null && _dropdownsLoaded)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dropdownError!,
                                  style: TextStyle(color: Colors.orange[800]),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, size: 20),
                                onPressed: _loadDropdownData,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),

                      _buildSectionHeader("Personal Information", Icons.person),
                      _buildCard([
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                firstName,
                                "First Name *",
                                Icons.person_outline,
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                middleName,
                                "Middle Name",
                                Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          lastName,
                          "Last Name *",
                          Icons.person_outline,
                          validator: (v) => v!.trim().isEmpty ? "Required" : null,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          email,
                          "Email *",
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v!.trim().isEmpty || !v.contains("@") ? "Invalid email" : null,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          password,
                          "Password *",
                          Icons.lock_outlined,
                          obscureText: true,
                          validator: (v) =>
                              v!.trim().isEmpty || v.length < 6 ? "Password must be at least 6 characters" : null,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          mobileNumber,
                          "Mobile Number *",
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v!.trim().isEmpty || v.length != 10 ? "Must be 10 digits" : null,
                        ),
                        SizedBox(height: 16),
                        _buildDropdown(
                          "Gender *",
                          selectedGender,
                          ["male", "female", "other"],
                          (v) => setState(() => selectedGender = v),
                          Icons.wc_outlined,
                          enabled: true,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(dob, "Date of Birth *"),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(doj, "Date of Joining *"),
                            ),
                          ],
                        ),
                      ]),

                      SizedBox(height: 24),
                      _buildSectionHeader("Organization Details", Icons.business),
                      _buildCard([
                        _buildDropdownFromList(
                          "Organization *",
                          selectedOrg,
                          organizations,
                          "orgName",
                          (v) => setState(() => selectedOrg = v),
                          Icons.business_outlined,
                          required: true,
                        ),
                        SizedBox(height: 16),
                        _buildDropdownFromList(
                          "Department *",
                          selectedDept,
                          departments,
                          "deptName",
                          (v) => setState(() => selectedDept = v),
                          Icons.domain_outlined,
                          required: true,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          designationId,
                          "Designation *",
                          Icons.work_outline,
                          validator: (v) => v!.trim().isEmpty ? "Required" : null,
                        ),
                        SizedBox(height: 16),
                        _buildDropdownFromList(
                          "Shift *",
                          selectedShift,
                          shifts,
                          "shiftType",
                          (v) => setState(() => selectedShift = v),
                          Icons.schedule_outlined,
                          required: false,
                        ),
                        SizedBox(height: 16),
                        _buildDropdown(
                          "Role *",
                          selectedRole,
                          ["admin", "hr", "JR_employee", "SR_employee"],
                          (v) => setState(() => selectedRole = v),
                          Icons.admin_panel_settings_outlined,
                          enabled: true,
                        ),
                        SizedBox(height: 16),
                        _buildDropdown(
                          "Status *",
                          selectedStatus,
                          ["active", "inactive"],
                          (v) => setState(() => selectedStatus = v),
                          Icons.check_circle_outline,
                          enabled: true,
                        ),
                        SizedBox(height: 16),
                        _buildDropdownFromList(
                          "Reporting Manager",
                          selectedReportingManager,
                          reportingManagers,
                          "firstName",
                          (v) => setState(() => selectedReportingManager = v),
                          Icons.supervisor_account_outlined,
                          required: false,
                        ),
                      ]),

                      SizedBox(height: 24),
                      _buildSectionHeader("Current Address", Icons.home),
                      _buildCard([
                        _buildTextField(
                          street,
                          "Street *",
                          Icons.location_on_outlined,
                          validator: (v) => v!.trim().isEmpty ? "Required" : null,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                city,
                                "City *",
                                Icons.location_city_outlined,
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                state,
                                "State *",
                                Icons.map_outlined,
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                zip,
                                "Zip Code *",
                                Icons.pin_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                country,
                                "Country *",
                                Icons.public_outlined,
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                      ]),

                      SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text("Same as Current Address"),
                        value: _isSameAddress,
                        onChanged: _copySameAddress,
                        activeColor: Color(0xFF6366F1),
                        contentPadding: EdgeInsets.zero,
                      ),

                      SizedBox(height: 16),
                      _buildSectionHeader("Permanent Address", Icons.home_work),
                      _buildCard([
                        _buildTextField(
                          pStreet,
                          "Street *",
                          Icons.location_on_outlined,
                          validator: (v) => !_isSameAddress && v!.trim().isEmpty ? "Required" : null,
                          enabled: !_isSameAddress,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                pCity,
                                "City *",
                                Icons.location_city_outlined,
                                validator: (v) => !_isSameAddress && v!.trim().isEmpty ? "Required" : null,
                                enabled: !_isSameAddress,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                pState,
                                "State *",
                                Icons.map_outlined,
                                validator: (v) => !_isSameAddress && v!.trim().isEmpty ? "Required" : null,
                                enabled: !_isSameAddress,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                pZip,
                                "Zip Code *",
                                Icons.pin_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) => !_isSameAddress && v!.trim().isEmpty ? "Required" : null,
                                enabled: !_isSameAddress,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                pCountry,
                                "Country *",
                                Icons.public_outlined,
                                validator: (v) => !_isSameAddress && v!.trim().isEmpty ? "Required" : null,
                                enabled: !_isSameAddress,
                              ),
                            ),
                          ],
                        ),
                      ]),

                      SizedBox(height: 24),
                      _buildSectionHeader("Upload Documents", Icons.upload_file),
                      _buildCard([
                        _buildFilePicker("Aadhar Card", adharCard, "adharCard"),
                        _buildFilePicker("PAN Card", panCard, "panCard"),
                        _buildFilePicker("Bank Book", bankBook, "bankBook"),
                        _buildFilePicker("10th Marksheet", xStandardMarksheet, "xStandardMarksheet"),
                        _buildFilePicker("12th Marksheet", xiiStandardMarksheet, "xiiStandardMarksheet"),
                        _buildFilePicker("Degree", degree, "degree"),
                        _buildFilePicker("Experience Letter", experienceLetter, "experienceLetter"),
                        _buildFilePicker("Photo", photo, "photo"),
                      ]),

                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: (organizations.isEmpty || departments.isEmpty) 
                              ? null 
                              : _isLoading ? null : submitForm,
                          child: _isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  organizations.isEmpty || departments.isEmpty
                                    ? "Please create Organizations & Departments first"
                                    : "Create Employee",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6366F1)),
          SizedBox(height: 20),
          Text(
            "Loading Form Data",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Fetching organizations, departments, and other data...",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: _loadDropdownData,
            child: Text("Retry if taking too long"),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 70,
            ),
            SizedBox(height: 20),
            Text(
              "Unable to Load Form",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 15),
            Text(
              _dropdownError ?? "Failed to load required data",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You need organizations and departments to create an employee",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Retry"),
                  onPressed: _loadDropdownData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.arrow_back),
                  label: Text("Go Back"),
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF6366F1),
                    side: BorderSide(color: Color(0xFF6366F1)),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF6366F1), size: 20),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? Color(0xFF6366F1) : Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? Color(0xFFE2E8F0) : Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? Color(0xFF6366F1) : Colors.grey, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Color(0xFFF8FAFC) : Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: enabled ? null : Colors.grey),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(controller),
      validator: (v) => v!.trim().isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF6366F1), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon, {
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? Color(0xFF6366F1) : Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? Color(0xFFE2E8F0) : Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? Color(0xFF6366F1) : Colors.grey, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Color(0xFFF8FAFC) : Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: enabled ? null : Colors.grey),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item[0].toUpperCase() + item.substring(1)),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: label.contains("*") ? (v) => v == null ? "Required" : null : null,
    );
  }

  Widget _buildDropdownFromList(
    String label,
    String? value,
    List<dynamic> items,
    String displayKey,
    Function(String?) onChanged,
    IconData icon, {
    bool required = true,
  }) {
    final hasItems = items.isNotEmpty;
    final enabled = hasItems;
    
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, 
          color: enabled ? Color(0xFF6366F1) : Colors.grey, 
          size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? Color(0xFFE2E8F0) : Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: enabled ? Color(0xFF6366F1) : Colors.grey, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Color(0xFFF8FAFC) : Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: enabled ? null : Colors.grey),
      ),
      items: hasItems
          ? items
              .map((item) => DropdownMenuItem(
                    value: item["id"].toString(),
                    child: Text(
                      item[displayKey].toString(),
                      style: TextStyle(color: Colors.black),
                    ),
                  ))
              .toList()
          : [
              DropdownMenuItem(
                value: null,
                child: Text(
                  required ? "No data available" : "Optional - No data",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ],
      onChanged: enabled ? onChanged : null,
      validator: required ? (v) => hasItems && v == null ? "Required" : null : null,
    );
  }

  Widget _buildFilePicker(String label, CustomPlatformFile? file, String fileType) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          file != null
              ? Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          switch (fileType) {
                            case "adharCard": adharCard = null; break;
                            case "panCard": panCard = null; break;
                            case "bankBook": bankBook = null; break;
                            case "xStandardMarksheet": xStandardMarksheet = null; break;
                            case "xiiStandardMarksheet": xiiStandardMarksheet = null; break;
                            case "degree": degree = null; break;
                            case "experienceLetter": experienceLetter = null; break;
                            case "photo": photo = null; break;
                          }
                        });
                      },
                      child: Text("Remove", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              : OutlinedButton.icon(
                  icon: Icon(Icons.upload_file, size: 18),
                  label: Text("Choose"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF6366F1),
                    side: BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    // Use different picker for photo vs documents
                    CustomPlatformFile? pickedFile;
                    if (fileType == "photo") {
                      pickedFile = await pickPhoto();
                    } else {
                      pickedFile = await pickDocument();
                    }
                    
                    if (pickedFile != null) {
                      setState(() {
                        switch (fileType) {
                          case "adharCard": adharCard = pickedFile; break;
                          case "panCard": panCard = pickedFile; break;
                          case "bankBook": bankBook = pickedFile; break;
                          case "xStandardMarksheet": xStandardMarksheet = pickedFile; break;
                          case "xiiStandardMarksheet": xiiStandardMarksheet = pickedFile; break;
                          case "degree": degree = pickedFile; break;
                          case "experienceLetter": experienceLetter = pickedFile; break;
                          case "photo": photo = pickedFile; break;
                        }
                      });
                    }
                  },
                ),
        ],
      ),
    );
  }

  void submitForm() async {
    // Check if required dropdowns are selected
    if (organizations.isEmpty || departments.isEmpty) {
      _showSnackBar("Please create organizations and departments first", isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fill all required fields", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare addresses as JSON objects
      Map<String, dynamic> currentAddress = {
        "street": street.text.trim(),
        "city": city.text.trim(),
        "state": state.text.trim(),
        "zip": zip.text.trim(),
        "country": country.text.trim(),
      };

      Map<String, dynamic> permanentAddress = {
        "street": pStreet.text.trim(),
        "city": pCity.text.trim(),
        "state": pState.text.trim(),
        "zip": pZip.text.trim(),
        "country": pCountry.text.trim(),
      };

      // Prepare form data with flattened addresses (Django backend expects this format)
      Map<String, dynamic> formData = {
        // Personal Info
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "email": email.text.trim(),
        "password": password.text.trim(),
        "mobileNumber": mobileNumber.text.trim(),
        "gender": selectedGender,
        "dob": dob.text.trim(),
        "doj": doj.text.trim(),
        "status": selectedStatus,
        "role": selectedRole,
        "designationId": designationId.text.trim(),
        
        // Organization references
        "organizationId": selectedOrg,
        "departmentId": selectedDept,
        "shiftId": selectedShift,
        
        // Flattened current address (Django backend restructures these)
        "currentAddress.street": currentAddress["street"],
        "currentAddress.city": currentAddress["city"],
        "currentAddress.state": currentAddress["state"],
        "currentAddress.zip": currentAddress["zip"],
        "currentAddress.country": currentAddress["country"],
        
        // Flattened permanent address
        "permanentAddress.street": permanentAddress["street"],
        "permanentAddress.city": permanentAddress["city"],
        "permanentAddress.state": permanentAddress["state"],
        "permanentAddress.zip": permanentAddress["zip"],
        "permanentAddress.country": permanentAddress["country"],
      };

      // Add optional fields
      if (middleName.text.trim().isNotEmpty) {
        formData["middleName"] = middleName.text.trim();
      }
      if (selectedReportingManager != null) {
        formData["reportingManager"] = selectedReportingManager;
      }

      // Prepare documents
      Map<String, CustomPlatformFile?> docs = {};
      if (adharCard != null) docs["adharCard"] = adharCard;
      if (panCard != null) docs["panCard"] = panCard;
      if (bankBook != null) docs["bankBook"] = bankBook;
      if (xStandardMarksheet != null) docs["xStandardMarksheet"] = xStandardMarksheet;
      if (xiiStandardMarksheet != null) docs["xiiStandardMarksheet"] = xiiStandardMarksheet;
      if (degree != null) docs["degree"] = degree;
      if (experienceLetter != null) docs["experienceLetter"] = experienceLetter;
      if (photo != null) docs["photo"] = photo;

      // Call API
      var response = await employeeService.createEmployee(formData, docs);

      setState(() => _isLoading = false);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnackBar("✅ Employee Created Successfully");
        Navigator.pop(context, true);
      } else {
        try {
          final errorData = json.decode(response.body);
          _showSnackBar("❌ Failed: ${errorData['message'] ?? 'Unknown error'}", isError: true);
        } catch (e) {
          _showSnackBar("❌ Failed: ${response.statusCode} ${response.reasonPhrase}", isError: true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("❌ Error: ${e.toString()}", isError: true);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    firstName.dispose();
    middleName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    mobileNumber.dispose();
    dob.dispose();
    doj.dispose();
    designationId.dispose();
    street.dispose();
    city.dispose();
    state.dispose();
    zip.dispose();
    country.dispose();
    pStreet.dispose();
    pCity.dispose();
    pState.dispose();
    pZip.dispose();
    pCountry.dispose();
    super.dispose();
  }
}