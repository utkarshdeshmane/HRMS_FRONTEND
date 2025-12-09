import 'package:flutter/material.dart';
import 'package:blinkit/repository/screens/services/department_api_service.dart';

class EditDepartmentScreen extends StatefulWidget {
  final Map<String, dynamic> department;

  const EditDepartmentScreen({
    Key? key,
    required this.department,
  }) : super(key: key);

  @override
  State<EditDepartmentScreen> createState() => _EditDepartmentScreenState();
}

class _EditDepartmentScreenState extends State<EditDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _deptNameController;
  late TextEditingController _deptCodeController;
  late TextEditingController _deptDescController;
  
  late String _orgStatus;
  bool _isLoading = false;
  String? _selectedOrgId;
  String? _selectedOrgName;
  List<dynamic> _organizations = [];
  bool _isLoadingOrgs = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadOrganizations();
  }

  void _initializeControllers() {
    _deptNameController = TextEditingController(
      text: widget.department["deptName"]?.toString() ?? "",
    );
    _deptCodeController = TextEditingController(
      text: widget.department["deptCode"]?.toString() ?? "",
    );
    _deptDescController = TextEditingController(
      text: widget.department["deptDesc"]?.toString() ?? "",
    );
    _orgStatus = widget.department["orgStatus"]?.toString() ?? "Active";
    
    // Get organization ID from department
    print('🔍 Initializing with department data: ${widget.department}');
    
    if (widget.department["orgId"] != null) {
      if (widget.department["orgId"] is Map) {
        // orgId is an object with _id/id and orgName
        _selectedOrgId = widget.department["orgId"]["_id"]?.toString() ?? 
                        widget.department["orgId"]["id"]?.toString();
        _selectedOrgName = widget.department["orgId"]["orgName"]?.toString();
        print('✅ Extracted from Map - ID: $_selectedOrgId, Name: $_selectedOrgName');
      } else if (widget.department["orgId"] is String) {
        // orgId is just a string ID
        _selectedOrgId = widget.department["orgId"].toString();
        print('✅ Extracted from String - ID: $_selectedOrgId');
      }
    }
    
    print('📝 Initial values - OrgID: $_selectedOrgId, OrgName: $_selectedOrgName');
  }

  @override
  void dispose() {
    _deptNameController.dispose();
    _deptCodeController.dispose();
    _deptDescController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() => _isLoadingOrgs = true);

    try {
      print('🔄 Loading organizations for edit screen...');
      final orgListData = await DepartmentApiService.getOrganizations();
      
      print('📦 Received ${orgListData.length} organizations');
      if (orgListData.isNotEmpty) {
        print('📋 First org: ${orgListData[0]}');
      }
      
      setState(() {
        _organizations = orgListData;
        _isLoadingOrgs = false;
      });
      
      // Verify if selected org exists in the list
      if (_selectedOrgId != null && _organizations.isNotEmpty) {
        final orgExists = _organizations.any((org) => 
          (org["_id"]?.toString() ?? org["id"]?.toString()) == _selectedOrgId
        );
        
        if (orgExists) {
          print('✅ Selected organization found in list');
        } else {
          print('⚠️ Selected organization NOT found in list. ID: $_selectedOrgId');
          print('   Available IDs: ${_organizations.map((o) => o["_id"] ?? o["id"]).toList()}');
        }
      }
    } catch (e) {
      print('❌ Error loading organizations: $e');
      
      setState(() => _isLoadingOrgs = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading organizations: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    // Prevent multiple submissions
    if (_isLoading) {
      print('⚠️ Already submitting, ignoring duplicate request');
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedOrgId == null || _selectedOrgId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select an organization'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    print('📤 Submitting department update...');

    try {
      final deptId = widget.department["_id"]?.toString() ?? 
                     widget.department["id"]?.toString();

      if (deptId == null || deptId.isEmpty) {
        throw Exception("Department ID not found");
      }

      final updateData = {
        "deptName": _deptNameController.text.trim(),
        "deptCode": _deptCodeController.text.trim(),
        "deptDesc": _deptDescController.text.trim(),
        "orgId": _selectedOrgId!,
        "orgStatus": _orgStatus,
      };

      print('📝 Update data: $updateData');
      
      final success = await DepartmentApiService.updateDepartment(
        deptId,
        updateData,
      );

      if (!mounted) return;
      
      setState(() => _isLoading = false);

      if (success) {
        print('✅ Department updated successfully');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Department updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Small delay to show snackbar before popping
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        print('❌ Department update failed');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update department'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      print('❌ Error updating department: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Department',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_isLoadingOrgs)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: _loadOrganizations,
              tooltip: 'Refresh Organizations',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingOrgs
            ? _buildLoadingState()
            : _buildForm(isDark),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading organizations...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Department',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update department information',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Department Name *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _deptNameController,
                      hint: 'e.g., Human Resources',
                      icon: Icons.corporate_fare_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter department name';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Department Code *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _deptCodeController,
                      hint: 'e.g., HR001',
                      icon: Icons.tag_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter department code';
                        }
                        if (value.trim().length < 2) {
                          return 'Code must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Description *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _deptDescController,
                      hint: 'Enter department description',
                      icon: Icons.description_rounded,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Organization *'),
                    const SizedBox(height: 8),
                    _buildDropdown(),
                    
                    if (_selectedOrgId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, 
                              color: Colors.orange[700], 
                              size: 18
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected: $_selectedOrgName',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                  Text(
                                    'ID: $_selectedOrgId',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),

                    _buildLabel('Status'),
                    const SizedBox(height: 12),
                    _buildStatusToggle(),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.orange[600], size: 22),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_organizations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[400]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[400]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No organizations available', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedOrgId == null 
              ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
              : Colors.orange[600]!,
          width: _selectedOrgId == null ? 1 : 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.domain_rounded, color: Colors.grey[600], size: 22),
              const SizedBox(width: 12),
              Text(
                'Select organization',
                style: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          value: _selectedOrgId,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          items: _organizations.map((org) {
            final orgId = org["_id"]?.toString() ?? org["id"]?.toString() ?? "";
            final orgName = org["orgName"]?.toString() ?? "Unknown";
            
            return DropdownMenuItem<String>(
              value: orgId,
              child: Row(
                children: [
                  Icon(Icons.domain_rounded, color: Colors.orange[600], size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      orgName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedOrgId = value;
              _selectedOrgName = _organizations
                  .firstWhere((org) => 
                    (org["_id"]?.toString() ?? org["id"]?.toString()) == value)
                  ["orgName"]?.toString();
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatusButton('Active', _orgStatus == 'Active')),
          Expanded(child: _buildStatusButton('Inactive', _orgStatus == 'Inactive')),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _orgStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (status == 'Active' ? Colors.green[600] : Colors.red[600])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'Active' ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Update Department',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
