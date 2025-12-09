import 'package:flutter/material.dart';
import 'package:blinkit/repository/screens/services/department_api_service.dart';

// Organization model
class Organization {
  final String id;
  final String orgName;
  final String? orgCode;

  Organization({
    required this.id,
    required this.orgName,
    this.orgCode,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      orgName: json['orgName']?.toString() ?? 'Unknown',
      orgCode: json['orgCode']?.toString(),
    );
  }
}

class CreateDepartmentScreen extends StatefulWidget {
  const CreateDepartmentScreen({Key? key}) : super(key: key);

  @override
  State<CreateDepartmentScreen> createState() => _CreateDepartmentScreenState();
}

class _CreateDepartmentScreenState extends State<CreateDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deptNameController = TextEditingController();
  final _deptCodeController = TextEditingController();
  final _deptDescController = TextEditingController();
  
  String? _selectedOrgId;
  String? _selectedOrgName;
  String _orgStatus = 'Active';
  bool _isLoading = false;
  bool _isLoadingOrgs = true;
  
  List<Organization> _organizations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  @override
  void dispose() {
    _deptNameController.dispose();
    _deptCodeController.dispose();
    _deptDescController.dispose();
    super.dispose();
  }

  /// Fetch organizations from API - FIXED VERSION
  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoadingOrgs = true;
      _errorMessage = null;
      _organizations = [];
    });

    try {
      print('🔄 Loading organizations...');
      
      // Fetch organizations - returns List<dynamic>
      final orgListData = await DepartmentApiService.getOrganizations();
      
      print('📦 Received ${orgListData.length} organizations from API');
      
      if (orgListData.isEmpty) {
        print('⚠️ No organizations found in API response');
        setState(() {
          _isLoadingOrgs = false;
          _errorMessage = 'No organizations available. Please create an organization first.';
        });
        return;
      }
      
      // Debug: Print raw data
      print('📋 Raw organization data structure:');
      if (orgListData.isNotEmpty && orgListData[0] is Map) {
        final firstOrg = orgListData[0] as Map<String, dynamic>;
        print('   First org keys: ${firstOrg.keys.toList()}');
        print('   First org data: $firstOrg');
      }
      
      // Convert to Organization objects
      final List<Organization> organizations = [];
      
      for (var i = 0; i < orgListData.length; i++) {
        try {
          final item = orgListData[i];
          if (item is Map<String, dynamic>) {
            final org = Organization.fromJson(item);
            organizations.add(org);
            print('   ✅ Added organization: ${org.orgName} (ID: ${org.id})');
          } else {
            print('   ⚠️ Item $i is not a Map: $item');
          }
        } catch (e) {
          print('   ❌ Error parsing item $i: $e');
        }
      }
      
      print('✅ Successfully loaded ${organizations.length} organizations');
      
      if (organizations.isEmpty) {
        print('⚠️ Could not parse any organizations');
        setState(() {
          _isLoadingOrgs = false;
          _errorMessage = 'Could not load organizations. Invalid data format.';
        });
        return;
      }
      
      // Auto-select first organization
      if (organizations.isNotEmpty) {
        setState(() {
          _organizations = organizations;
          _selectedOrgId = organizations[0].id;
          _selectedOrgName = organizations[0].orgName;
          _isLoadingOrgs = false;
        });
        
        print('✅ Auto-selected first organization: $_selectedOrgName ($_selectedOrgId)');
      } else {
        setState(() {
          _organizations = organizations;
          _isLoadingOrgs = false;
        });
      }
      
    } catch (e) {
      print('❌ Error loading organizations: $e');
      
      setState(() {
        _isLoadingOrgs = false;
        _errorMessage = 'Failed to load organizations: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadOrganizations,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Submit form
  Future<void> _submitForm() async {
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

    try {
      print('📤 Submitting department...');
      print('🔑 Organization ID: $_selectedOrgId');
      print('📝 Department Name: ${_deptNameController.text}');
      print('🔢 Department Code: ${_deptCodeController.text}');
      
      final result = await DepartmentApiService.createDepartment(
        deptName: _deptNameController.text.trim(),
        deptCode: _deptCodeController.text.trim(),
        deptDesc: _deptDescController.text.trim(),
        orgId: _selectedOrgId!,
        orgStatus: _orgStatus,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success'] == true) {
          // ✅ Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Department created successfully!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Clear form
          _deptNameController.clear();
          _deptCodeController.clear();
          _deptDescController.clear();
          _formKey.currentState?.reset();
          
          Navigator.pop(context, true);
        } else {
          // ❌ Failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create department'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      print('❌ Error submitting form: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
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
          'Create Department',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _isLoadingOrgs ? null : _loadOrganizations,
            tooltip: 'Refresh Organizations',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingOrgs
            ? _buildLoadingState()
            : _errorMessage != null && _organizations.isEmpty
                ? _buildErrorState()
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
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch available organizations',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Organizations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    _errorMessage ?? 'An unknown error occurred',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please ensure:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text('Backend server is running', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text('Ngrok tunnel is active', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text('At least one organization exists', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadOrganizations,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
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
                        Icons.business_rounded,
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
                            'New Department',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _organizations.isEmpty 
                                ? 'No organizations available'
                                : '${_organizations.length} organizations available',
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
                        if (value.length > 50) {
                          return 'Maximum 50 characters allowed';
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
                        if (value.length > 100) {
                          return 'Maximum 100 characters allowed';
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
                        if (value.length > 200) {
                          return 'Maximum 200 characters allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Organization *'),
                    const SizedBox(height: 8),
                    if (_organizations.isEmpty)
                      _buildNoOrganizationsWarning()
                    else
                      _buildDropdown(),
                    
                    // Show selected org details
                    if (_selectedOrgId != null && _selectedOrgName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, 
                              color: Colors.blue[700], 
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
                                      color: Colors.blue[700],
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

  Widget _buildNoOrganizationsWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Organizations Available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You need to create an organization first before creating departments.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        prefixIcon: Icon(icon, color: Colors.blue[600], size: 22),
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
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedOrgId == null 
              ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
              : Colors.blue[600]!,
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
            return DropdownMenuItem<String>(
              value: org.id,
              child: Row(
                children: [
                  Icon(Icons.domain_rounded, color: Colors.blue[600], size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          org.orgName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (org.orgCode != null && org.orgCode!.isNotEmpty)
                          Text(
                            org.orgCode!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedOrgId = value;
                _selectedOrgName = _organizations
                    .firstWhere((org) => org.id == value)
                    .orgName;
              });
              print('🔑 Selected Organization ID: $value');
              print('📝 Selected Organization Name: $_selectedOrgName');
            }
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
    final bool isFormValid = _organizations.isNotEmpty && 
                           _selectedOrgId != null && 
                           _selectedOrgId!.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (isFormValid ? _submitForm : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid ? Colors.blue[600] : Colors.grey[400],
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_rounded, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Create Department',
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