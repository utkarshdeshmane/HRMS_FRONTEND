import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/employee_api_service.dart';
import '../services/organization_api_service.dart';
import '../services/department_api_service.dart';

class EditEmployeeForm extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditEmployeeForm({Key? key, required this.employee}) : super(key: key);

  @override
  _EditEmployeeFormState createState() => _EditEmployeeFormState();
}

class _EditEmployeeFormState extends State<EditEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService employeeService = ApiService();
  bool _isLoading = false;
  bool _isSameAddress = false;
  bool _dropdownsLoaded = false;
  String? _dropdownError;

  // Text Controllers - Personal Info
  late TextEditingController firstName;
  late TextEditingController middleName;
  late TextEditingController lastName;
  late TextEditingController email;
  late TextEditingController mobileNumber;
  late TextEditingController dob;
  late TextEditingController doj;
  late TextEditingController designationId;

  // Current Address
  late TextEditingController street;
  late TextEditingController city;
  late TextEditingController state;
  late TextEditingController zip;
  late TextEditingController country;

  // Permanent Address
  late TextEditingController pStreet;
  late TextEditingController pCity;
  late TextEditingController pState;
  late TextEditingController pZip;
  late TextEditingController pCountry;

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

  String? employeeId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadEmployeeData();
    _loadDropdownData();
  }

  void _initializeControllers() {
    firstName = TextEditingController();
    middleName = TextEditingController();
    lastName = TextEditingController();
    email = TextEditingController();
    mobileNumber = TextEditingController();
    dob = TextEditingController();
    doj = TextEditingController();
    designationId = TextEditingController();
    street = TextEditingController();
    city = TextEditingController();
    state = TextEditingController();
    zip = TextEditingController();
    country = TextEditingController();
    pStreet = TextEditingController();
    pCity = TextEditingController();
    pState = TextEditingController();
    pZip = TextEditingController();
    pCountry = TextEditingController();
  }

  void _loadEmployeeData() {
    final emp = widget.employee;
    
    employeeId = emp['id']?.toString() ?? emp['_id']?.toString();
    
    firstName.text = emp['firstName']?.toString() ?? '';
    middleName.text = emp['middleName']?.toString() ?? '';
    lastName.text = emp['lastName']?.toString() ?? '';
    email.text = emp['email']?.toString() ?? '';
    mobileNumber.text = emp['mobileNumber']?.toString() ?? '';
    dob.text = emp['dob']?.toString() ?? '';
    doj.text = emp['doj']?.toString() ?? '';
    designationId.text = emp['designationId']?.toString() ?? '';
    
    selectedGender = emp['gender']?.toString();
    selectedStatus = emp['status']?.toString();
    selectedRole = emp['role']?.toString();
    selectedOrg = emp['organizationId']?.toString();
    selectedDept = emp['departmentId']?.toString();
    selectedShift = emp['shiftId']?.toString();
    selectedReportingManager = emp['reportingManager']?.toString();
    
    // Load addresses
    if (emp['currentAddress'] != null) {
      var currentAddr = emp['currentAddress'];
      if (currentAddr is String) {
        currentAddr = json.decode(currentAddr);
      }
      if (currentAddr is Map) {
        street.text = currentAddr['street']?.toString() ?? '';
        city.text = currentAddr['city']?.toString() ?? '';
        state.text = currentAddr['state']?.toString() ?? '';
        zip.text = currentAddr['zip']?.toString() ?? '';
        country.text = currentAddr['country']?.toString() ?? '';
      }
    }
    
    if (emp['permanentAddress'] != null) {
      var permAddr = emp['permanentAddress'];
      if (permAddr is String) {
        permAddr = json.decode(permAddr);
      }
      if (permAddr is Map) {
        pStreet.text = permAddr['street']?.toString() ?? '';
        pCity.text = permAddr['city']?.toString() ?? '';
        pState.text = permAddr['state']?.toString() ?? '';
        pZip.text = permAddr['zip']?.toString() ?? '';
        pCountry.text = permAddr['country']?.toString() ?? '';
      }
    }
  }

  Future<void> _loadDropdownData() async {
    print('🔄 EDIT FORM: Loading dropdown data...');
    setState(() {
      _isLoading = true;
      _dropdownsLoaded = false;
      _dropdownError = null;
    });
    
    try {
      print('📡 FORM: Fetching organizations...');
      final orgs = await OrganizationApiService.getOrganizations();
      
      print('📡 FORM: Fetching departments...');
      final depts = await DepartmentApiService.getDepartments();
      
      print('📡 FORM: Fetching shifts...');
      final shfts = await employeeService.getShifts();
      
      print('📡 FORM: Fetching managers...');
      final mgrs = await employeeService.getReportingManagers();
      
      setState(() {
        organizations = orgs is List ? orgs : [];
        departments = depts is List ? depts : [];
        shifts = shfts is List ? shfts : [];
        reportingManagers = mgrs is List ? mgrs : [];
        _isLoading = false;
        _dropdownsLoaded = true;
      });
      
      print('✅ EDIT FORM: Dropdowns loaded successfully!');
    } catch (e) {
      print('❌ EDIT FORM: Error loading dropdowns: $e');
      setState(() {
        _isLoading = false;
        _dropdownError = "Failed to load form data";
      });
    }
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
              primary: Color(0xFF2E7D32),
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF2E7D32),
        title: Text(
          "Edit Employee",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading && !_dropdownsLoaded
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text("Loading form data...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      ),
                      SizedBox(height: 16),
                      _buildDropdownFromList(
                        "Department *",
                        selectedDept,
                        departments,
                        "deptName",
                        (v) => setState(() => selectedDept = v),
                        Icons.domain_outlined,
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
                      ),
                      SizedBox(height: 16),
                      _buildDropdown(
                        "Role *",
                        selectedRole,
                        ["admin", "hr", "JR_employee", "SR_employee"],
                        (v) => setState(() => selectedRole = v),
                        Icons.admin_panel_settings_outlined,
                      ),
                      SizedBox(height: 16),
                      _buildDropdown(
                        "Status *",
                        selectedStatus,
                        ["active", "inactive"],
                        (v) => setState(() => selectedStatus = v),
                        Icons.check_circle_outline,
                      ),
                      SizedBox(height: 16),
                      _buildDropdownFromList(
                        "Reporting Manager",
                        selectedReportingManager,
                        reportingManagers,
                        "firstName",
                        (v) => setState(() => selectedReportingManager = v),
                        Icons.supervisor_account_outlined,
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
                      activeColor: Color(0xFF2E7D32),
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
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              pState,
                              "State *",
                              Icons.map_outlined,
                              validator: (v) => !_isSameAddress && v!.trim().isEmpty ? "Required" : null,
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
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              pCountry,
                              "Country *",
                              Icons.public_outlined,
                              validator: (v) => !_isSameAddress && v!.trim().isEmpty ? "Required" : null,
                            ),
                          ),
                        ],
                      ),
                    ]),

                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : updateEmployee,
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
                                "Update Employee",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF2E7D32), size: 20),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF2E7D32), size: 20),
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
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF2E7D32), size: 20),
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
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
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
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF2E7D32), size: 20),
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
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item[0].toUpperCase() + item.substring(1)),
              ))
          .toList(),
      onChanged: onChanged,
      validator: label.contains("*") ? (v) => v == null ? "Required" : null : null,
    );
  }

  Widget _buildDropdownFromList(
    String label,
    String? value,
    List<dynamic> items,
    String displayKey,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF2E7D32), size: 20),
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
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item["id"].toString(),
                child: Text(item[displayKey].toString()),
              ))
          .toList(),
      onChanged: onChanged,
      validator: label.contains("*") ? (v) => v == null ? "Required" : null : null,
    );
  }

  void updateEmployee() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fill all required fields", isError: true);
      return;
    }

    if (employeeId == null) {
      _showSnackBar("Employee ID not found", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
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

      Map<String, dynamic> formData = {
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "email": email.text.trim(),
        "mobileNumber": mobileNumber.text.trim(),
        "gender": selectedGender,
        "dob": dob.text.trim(),
        "doj": doj.text.trim(),
        "status": selectedStatus,
        "role": selectedRole,
        "designationId": designationId.text.trim(),
        "organizationId": selectedOrg,
        "departmentId": selectedDept,
        "shiftId": selectedShift,
        "currentAddress": json.encode(currentAddress),
        "permanentAddress": json.encode(permanentAddress),
      };

      if (middleName.text.trim().isNotEmpty) {
        formData["middleName"] = middleName.text.trim();
      }
      if (selectedReportingManager != null) {
        formData["reportingManager"] = selectedReportingManager;
      }

      final response = await employeeService.updateEmployee(employeeId!, formData);

      setState(() => _isLoading = false);

      if (response != null) {
        _showSnackBar("✅ Employee Updated Successfully");
        Navigator.pop(context, true);
      } else {
        _showSnackBar("❌ Failed to update employee", isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("❌ Error: ${e.toString()}", isError: true);
    }
  }

  @override
  void dispose() {
    firstName.dispose();
    middleName.dispose();
    lastName.dispose();
    email.dispose();
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
