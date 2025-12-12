import 'package:blinkit/repository/screens/sidebar/hrms_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/employee_api_service.dart';
import 'package:blinkit/repository/screens/employee/create_employee_form.dart';
import 'package:blinkit/repository/screens/employee/edit_employee_form.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> employees = [];
  List<dynamic> filteredEmployees = [];
  String searchQuery = '';
  String selectedStatus = 'all';
  String selectedDepartment = 'all';
  bool isLoading = false;
  bool isGridView = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  // Helper to get employee ID (handles both 'id' and '_id')
  String _getEmployeeId(dynamic emp) {
    return emp['id']?.toString() ?? emp['_id']?.toString() ?? 'N/A';
  }

  Future<void> _loadEmployees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      print('📡 Fetching employees from API...');
      final data = await _apiService.getEmployees();
      
      print('✅ API Response received: ${data.length} employees');
      if (data.isNotEmpty) {
        print('📄 First employee: ${data[0]}');
        print('🆔 First employee ID: ${_getEmployeeId(data[0])}');
      }
      
      setState(() {
        employees = data;
        filteredEmployees = data;
        isLoading = false;
      });
      
      if (data.isEmpty) {
        print('⚠️ No employees found in API response');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading employees: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      _showSnackBar('Error loading employees: $e', Colors.red);
    }
  }

  void _filterEmployees() {
    setState(() {
      filteredEmployees = employees.where((emp) {
        String firstName = emp['firstName']?.toString() ?? '';
        String middleName = emp['middleName']?.toString() ?? '';
        String lastName = emp['lastName']?.toString() ?? '';
        String fullName = '$firstName $middleName $lastName'.toLowerCase().trim();
        
        String email = emp['email']?.toString().toLowerCase() ?? '';
        String empId = _getEmployeeId(emp).toLowerCase();
        
        bool matchesSearch = fullName.contains(searchQuery.toLowerCase()) ||
            email.contains(searchQuery.toLowerCase()) ||
            empId.contains(searchQuery.toLowerCase());
        
        String status = emp['status']?.toString().toLowerCase() ?? 'inactive';
        bool matchesStatus = selectedStatus == 'all' || status == selectedStatus.toLowerCase();
        
        String deptName = '';
        if (emp['departmentId'] != null) {
          if (emp['departmentId'] is Map) {
            deptName = emp['departmentId']['departmentName']?.toString() ?? '';
          } else if (emp['departmentId'] is String) {
            deptName = emp['departmentId'].toString();
          }
        }
        
        bool matchesDepartment = selectedDepartment == 'all' || deptName == selectedDepartment;
        
        return matchesSearch && matchesStatus && matchesDepartment;
      }).toList();
      
      print('🔍 Filtered: ${filteredEmployees.length} of ${employees.length} employees');
    });
  }

  String _getFullName(dynamic emp) {
    if (emp == null) return 'N/A';
    String firstName = emp['firstName']?.toString() ?? '';
    String middleName = emp['middleName']?.toString() ?? '';
    String lastName = emp['lastName']?.toString() ?? '';
    
    String fullName = firstName;
    if (middleName.isNotEmpty && middleName != 'v') fullName += ' $middleName';
    if (lastName.isNotEmpty) fullName += ' $lastName';
    
    return fullName.trim().isEmpty ? 'N/A' : fullName.trim();
  }

  String _getDepartmentName(dynamic emp) {
    if (emp == null || emp['departmentId'] == null) return 'N/A';
    
    if (emp['departmentId'] is Map) {
      return emp['departmentId']['departmentName']?.toString() ?? 'N/A';
    } else if (emp['departmentId'] is String) {
      return emp['departmentId'].toString();
    }
    return 'N/A';
  }

  String _getInitials(dynamic emp) {
    if (emp == null) return '??';
    String firstName = emp['firstName']?.toString() ?? '';
    String lastName = emp['lastName']?.toString() ?? '';
    
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();
    
    return initials.isEmpty ? '??' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HRMSSidebar(),
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[700],
        title: const Text('Employee Management'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() => isGridView = !isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusChips(),
          _buildEmployeeCount(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading employees...'),
                      ],
                    ),
                  )
                : errorMessage != null
                    ? _buildErrorState()
                    : filteredEmployees.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadEmployees,
                            child: isGridView ? _buildGridView() : _buildListView(),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEmployee,
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          searchQuery = value;
          _filterEmployees();
        },
        decoration: InputDecoration(
          hintText: 'Search by name, email or ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      _filterEmployees();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', selectedStatus),
            const SizedBox(width: 8),
            _buildFilterChip('Active', 'active', selectedStatus),
            const SizedBox(width: 8),
            _buildFilterChip('Inactive', 'inactive', selectedStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue) {
    bool isSelected = selectedValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = value;
          _filterEmployees();
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmployeeCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${filteredEmployees.length} Employees',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Total: ${employees.length}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEmployees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeCard(filteredEmployees[index]);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredEmployees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeGridCard(filteredEmployees[index]);
      },
    );
  }

  Widget _buildEmployeeCard(dynamic employee) {
    String fullName = _getFullName(employee);
    String department = _getDepartmentName(employee);
    String designation = employee['designationId']?.toString() ?? 'N/A';
    String empId = _getEmployeeId(employee);
    String status = employee['status']?.toString() ?? 'inactive';
    String initials = _getInitials(employee);
    String email = employee['email']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewEmployee(employee),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[100],
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      designation,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            department,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(status),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    color: Colors.green[700],
                    onPressed: () => _viewEmployee(employee),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue[700],
                    onPressed: () => _editEmployee(employee),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red[700],
                    onPressed: () => _deleteEmployee(employee),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeGridCard(dynamic employee) {
    String fullName = _getFullName(employee);
    String designation = employee['designationId']?.toString() ?? 'N/A';
    String status = employee['status']?.toString() ?? 'inactive';
    String initials = _getInitials(employee);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewEmployee(employee),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.blue[100],
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                designation,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(status),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    color: Colors.green[700],
                    onPressed: () => _viewEmployee(employee),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: Colors.blue[700],
                    onPressed: () => _editEmployee(employee),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red[700],
                    onPressed: () => _deleteEmployee(employee),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status.toLowerCase() == 'active' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            employees.isEmpty ? 'No employees in database' : 'No employees found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            employees.isEmpty 
                ? 'Add your first employee to get started'
                : 'Try adjusting your filters or search',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (employees.isEmpty)
            ElevatedButton.icon(
              onPressed: _createEmployee,
              icon: const Icon(Icons.add),
              label: const Text('Add Employee'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load employees',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    Set<String> departments = {};
    for (var emp in employees) {
      String dept = _getDepartmentName(emp);
      if (dept != 'N/A') departments.add(dept);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Employees'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Department', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedDepartment,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Departments')),
                  ...departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedDepartment = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedDepartment = 'all';
                  selectedStatus = 'all';
                  _filterEmployees();
                });
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                _filterEmployees();
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewEmployee(dynamic employee) {
    if (employee == null) return;
    
    String fullName = _getFullName(employee);
    String department = _getDepartmentName(employee);
    
    DateTime? dob = employee['dob'] != null ? DateTime.tryParse(employee['dob'].toString()) : null;
    DateTime? doj = employee['doj'] != null ? DateTime.tryParse(employee['doj'].toString()) : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fullName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Employee ID', _getEmployeeId(employee)),
              _buildInfoRow('Email', employee['email']?.toString() ?? 'N/A'),
              _buildInfoRow('Mobile', employee['mobileNumber']?.toString() ?? 'N/A'),
              _buildInfoRow('Gender', employee['gender']?.toString() ?? 'N/A'),
              _buildInfoRow('DOB', dob != null ? DateFormat('dd MMM yyyy').format(dob) : 'N/A'),
              _buildInfoRow('DOJ', doj != null ? DateFormat('dd MMM yyyy').format(doj) : 'N/A'),
              _buildInfoRow('Department', department),
              _buildInfoRow('Designation', employee['designationId']?.toString() ?? 'N/A'),
              _buildInfoRow('Role', employee['role']?.toString() ?? 'N/A'),
              _buildInfoRow('Status', employee['status']?.toString() ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editEmployee(employee);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _createEmployee() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEmployeeForm()),
    );
  }

  void _editEmployee(dynamic employee) async {
    if (employee == null) return;
    
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditEmployeeForm(employee: employee),
        ),
      );
      
      // If employee was updated, refresh the list
      if (result == true) {
        _showSnackBar('Employee updated successfully', Colors.green);
        _loadEmployees(); // Refresh the employee list
      }
    } catch (e) {
      print('Error navigating to edit form: $e');
      _showSnackBar('Error opening edit form', Colors.red);
    }
  }

  void _deleteEmployee(dynamic employee) {
    if (employee == null) return;
    
    String fullName = _getFullName(employee);
    String employeeId = _getEmployeeId(employee);

    if (employeeId.isEmpty || employeeId == 'N/A') {
      _showSnackBar('Cannot delete: Invalid employee ID', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete $fullName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final apiService = ApiService();
                bool success = await apiService.deleteEmployee(employeeId);
                
                Navigator.pop(context);

                if (success) {
                  _showSnackBar('$fullName deleted successfully', Colors.green);
                  _loadEmployees();
                } else {
                  _showSnackBar('Failed to delete employee', Colors.red);
                }
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error deleting employee: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}