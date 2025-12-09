import 'package:flutter/material.dart';
import 'package:blinkit/repository/screens/sidebar/hrms_sidebar.dart';
import 'package:blinkit/repository/screens/services/department_api_service.dart';
import 'package:blinkit/repository/screens/department/CreateDepartmentScreen.dart';
import 'package:blinkit/repository/screens/department/ViewDepartmentScreen.dart';
import 'package:blinkit/repository/screens/department/EditDepartmentScreen.dart';

class DepartmentDashboardScreen extends StatefulWidget {
  @override
  _DepartmentDashboardScreenState createState() =>
      _DepartmentDashboardScreenState();
}

class _DepartmentDashboardScreenState extends State<DepartmentDashboardScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> departments = [];
  List<dynamic> filteredDepartments = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = "";
  String filterStatus = "All";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    loadDepartments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadDepartments() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await DepartmentApiService.getDepartments();

      if (!mounted) return;

      setState(() {
        departments = data ?? [];
        filteredDepartments = departments;
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Failed to load departments: ${e.toString()}";
        departments = [];
        filteredDepartments = [];
      });
    }
  }

  void _filterDepartments() {
    setState(() {
      filteredDepartments = departments.where((dept) {
        final name = dept["deptName"]?.toString().toLowerCase() ?? "";
        final code = dept["deptCode"]?.toString().toLowerCase() ?? "";
        final status = dept["orgStatus"]?.toString() ?? "Inactive";
        
        final matchesSearch = name.contains(searchQuery.toLowerCase()) ||
            code.contains(searchQuery.toLowerCase());
        
        final matchesFilter = filterStatus == "All" ||
            status.toLowerCase() == filterStatus.toLowerCase();

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> deleteDepartment(String id, String name) async {
    if (id.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text("Confirm Delete"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '$name'?\n\nThis action cannot be undone.",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await DepartmentApiService.deleteDepartment(id);

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Department deleted successfully"),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          await loadDepartments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Failed to delete department"),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String getOrganizationName(dynamic dept) {
    try {
      if (dept == null) return "Unknown";

      if (dept["orgId"] != null) {
        if (dept["orgId"] is Map) {
          return dept["orgId"]["orgName"]?.toString() ?? "Unknown";
        } else if (dept["orgId"] is String) {
          return "Org ID: ${dept["orgId"]}";
        }
      }
      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar for desktop
          if (MediaQuery.of(context).size.width > 900)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: HRMSSidebar(),
            ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildAppBar(isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadDepartments,
                    color: Colors.blue[600],
                    child: _buildContent(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width <= 900 ? HRMSSidebar() : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateDepartmentScreen()),
          );

          if (result == true && mounted) {
            loadDepartments();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text("New Department"),
        backgroundColor: Colors.blue[600],
        elevation: 4,
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (MediaQuery.of(context).size.width <= 900)
                IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Department Management",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${filteredDepartments.length} department${filteredDepartments.length != 1 ? 's' : ''} found",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: loadDepartments,
                tooltip: "Refresh",
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      searchQuery = value;
                      _filterDepartments();
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search departments...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterStatus,
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    dropdownColor:
                        isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: ["All", "Active", "Inactive"].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        filterStatus = value!;
                        _filterDepartments();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.blue[600]!),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading departments...",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                "Error Loading Data",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadDepartments,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredDepartments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.folder_open_rounded,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? "No departments found"
                  : "No Departments Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? "Try adjusting your search or filters"
                  : "Create your first department to get started",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateDepartmentScreen()),
                  );

                  if (result == true && mounted) {
                    loadDepartments();
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text("Create Department"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: MediaQuery.of(context).size.width > 900
          ? _buildGridView(isDark)
          : _buildListView(isDark),
    );
  }

  Widget _buildGridView(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 3 : 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.4,
      ),
      itemCount: filteredDepartments.length,
      itemBuilder: (context, index) {
        return _buildDepartmentCard(filteredDepartments[index], isDark);
      },
    );
  }

  Widget _buildListView(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDepartments.length,
      itemBuilder: (context, index) {
        return _buildDepartmentCard(filteredDepartments[index], isDark);
      },
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> dept, bool isDark) {
    final String id = dept["_id"]?.toString() ?? dept["id"]?.toString() ?? "";
    final String name = dept["deptName"]?.toString() ?? "Unnamed";
    final String code = dept["deptCode"]?.toString() ?? "N/A";
    final String desc = dept["deptDesc"]?.toString() ?? "No description";
    final String status = dept["orgStatus"]?.toString() ?? "Inactive";
    final String orgName = getOrganizationName(dept);
    final bool isActive = status.toLowerCase() == "active";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewDepartmentScreen(department: dept),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[400]!],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              code,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green[600]
                                  : Colors.red[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  height: 1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.domain_rounded,
                      size: 16,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        orgName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildIconButton(
                      icon: Icons.visibility_outlined,
                      color: Colors.blue[600]!,
                      tooltip: "View",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ViewDepartmentScreen(department: dept),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.edit_outlined,
                      color: Colors.orange[600]!,
                      tooltip: "Edit",
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditDepartmentScreen(department: dept),
                          ),
                        );

                        if (result == true && mounted) {
                          loadDepartments();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.delete_outline,
                      color: Colors.red[600]!,
                      tooltip: "Delete",
                      onPressed: () => deleteDepartment(id, name),
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

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
