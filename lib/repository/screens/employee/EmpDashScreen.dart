import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/employee_api_service.dart';
import '../services/auth_api_service.dart';
import '../auth/admin_login_screen.dart';
import '../sidebar/hrms_sidebar.dart';
import '../attendance/AttendanceScreen.dart';

class EmpDashScreen extends StatefulWidget {
  const EmpDashScreen({Key? key}) : super(key: key);

  @override
  State<EmpDashScreen> createState() => _EmpDashScreenState();
}

class _EmpDashScreenState extends State<EmpDashScreen> with WidgetsBindingObserver {
  // Employee data from API
  Map<String, dynamic>? employeeData;
  Map<String, dynamic>? attendanceData;
  Map<String, dynamic>? leaveData;
  List<dynamic> upcomingHolidays = [];
  List<dynamic> recentActivities = [];
  
  // Loading states
  bool isLoading = true;
  bool isAttendanceLoading = false;

  // Attendance data
  bool isCheckedIn = false;
  String checkInTime = "--:--";
  String checkOutTime = "--:--";
  int presentDays = 0;
  int absentDays = 0;
  int leaveDays = 0;

  // Leave balance
  int totalLeaves = 0;
  int usedLeaves = 0;
  int pendingLeaves = 0;

  // Date tracking
  String todayDate = "";

  // Helper method to check if user should have sidebar access
  bool get shouldShowSidebar {
    if (employeeData == null) return false;
    
    final userRole = employeeData!['role']?.toString() ?? '';
    // Only admin and hr roles should have sidebar access
    return userRole == 'admin' || userRole == 'hr';
  }

  // Helper method to determine if attendance button should be enabled
  bool get isAttendanceButtonEnabled {
    // Button is enabled if:
    // 1. Currently checked in (can check out) OR
    // 2. Not checked in AND haven't completed both check-in and check-out today
    if (isCheckedIn) {
      return true; // Can always check out if checked in
    } else {
      // Can only check in if both check-in and check-out are NOT completed
      return !(checkInTime != "--:--" && checkOutTime != "--:--");
    }
  }

  // Helper method to determine button state
  String get attendanceButtonText {
    if (isCheckedIn) {
      return 'Check Out';
    } else if (checkInTime != "--:--" && checkOutTime != "--:--") {
      return 'Completed for Today'; // Both completed, disabled until next day
    } else {
      return 'Check In';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    todayDate = _getTodayDate();
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check if new day
      _checkForNewDay();
    }
  }

  // ----------------------------------------------------
  // PERSISTENCE HELPERS
  // ----------------------------------------------------
  String _getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadPersistedAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final persistedDate = prefs.getString('lastCheckInDate');
      final persistedCheckIn = prefs.getBool('isCheckedIn') ?? false;
      final persistedCheckInTime = prefs.getString('checkInTime') ?? "--:--";
      final persistedCheckOutTime = prefs.getString('checkOutTime') ?? "--:--";
      
      print("📊 Loading persisted attendance:");
      print("   Date: $persistedDate (today: $todayDate)");
      print("   CheckedIn: $persistedCheckIn");
      print("   CheckInTime: $persistedCheckInTime");
      print("   CheckOutTime: $persistedCheckOutTime");
      
      // Check if it's a new day
      if (persistedDate != todayDate) {
        // New day - reset attendance completely
        print("🔄 New day detected - resetting attendance");
        await prefs.remove('isCheckedIn');
        await prefs.remove('checkInTime');
        await prefs.remove('checkOutTime');
        await prefs.remove('lastCheckInDate');
        
        setState(() {
          isCheckedIn = false;
          checkInTime = "--:--";
          checkOutTime = "--:--";
        });
      } else if (persistedDate == todayDate) {
        // Same day - restore the exact state
        print("📊 Restoring current day state");
        setState(() {
          isCheckedIn = persistedCheckIn;
          checkInTime = persistedCheckInTime;
          checkOutTime = persistedCheckOutTime;
        });
        
        // Log completion status
        if (persistedCheckOutTime != "--:--" && persistedCheckInTime != "--:--") {
          print("✅ Both check-in and check-out completed today - button will be disabled");
        }
      } else {
        // Fallback - reset everything
        print("🔄 Fallback - resetting attendance");
        setState(() {
          isCheckedIn = false;
          checkInTime = "--:--";
          checkOutTime = "--:--";
        });
      }
    } catch (e) {
      print("❌ Error loading persisted attendance: $e");
    }
  }

  Future<void> _saveAttendanceState(bool checkedIn, String checkIn, String checkOut) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print("💾 Saving attendance state:");
      print("   CheckedIn: $checkedIn");
      print("   CheckInTime: $checkIn");
      print("   CheckOutTime: $checkOut");
      print("   Date: $todayDate");
      
      await prefs.setBool('isCheckedIn', checkedIn);
      await prefs.setString('checkInTime', checkIn);
      await prefs.setString('checkOutTime', checkOut);
      await prefs.setString('lastCheckInDate', todayDate);
      
      // If both check-in and check-out are completed, attendance is done for the day
      if (checkIn != "--:--" && checkOut != "--:--" && !checkedIn) {
        print("✅ Both check-in and check-out completed - attendance button will be disabled until next day");
      }
    } catch (e) {
      print("❌ Error saving attendance state: $e");
    }
  }

  Future<void> _resetAttendanceForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final persistedDate = prefs.getString('lastCheckInDate');
    final persistedCheckOut = prefs.getString('checkOutTime') ?? "--:--";
    
    // Reset if it's a new day OR if both check-in and check-out were completed yesterday
    bool shouldReset = false;
    
    if (persistedDate != todayDate) {
      // It's a new day
      shouldReset = true;
      print("🔄 New day detected: $persistedDate -> $todayDate");
    } else if (persistedDate == todayDate && persistedCheckOut != "--:--") {
      // Same day but both check-in and check-out are completed
      // This shouldn't happen normally, but handles edge cases
      print("🔄 Both check-in and check-out completed today");
    }
    
    if (shouldReset) {
      print("🔄 Resetting attendance state for new day");
      await prefs.remove('isCheckedIn');
      await prefs.remove('checkInTime');
      await prefs.remove('checkOutTime');
      await prefs.remove('lastCheckInDate');
      
      setState(() {
        isCheckedIn = false;
        checkInTime = "--:--";
        checkOutTime = "--:--";
      });
    }
  }

  Future<void> _checkForNewDay() async {
    final currentDate = _getTodayDate();
    if (currentDate != todayDate) {
      print("📅 Date changed from $todayDate to $currentDate");
      setState(() {
        todayDate = currentDate;
      });
      await _resetAttendanceForNewDay();
    }
  }

  // ----------------------------------------------------
  // API DATA LOADING METHODS
  // ----------------------------------------------------
  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First check/reset for new day
      await _resetAttendanceForNewDay();
      
      // Then load persisted state
      await _loadPersistedAttendance();
      
      // Then load all data
      await _loadEmployeeProfile();
      await Future.wait([
        _loadTodayAttendanceStatus(),
        _loadAttendanceData(),
        _loadLeaveData(),
        _loadHolidays(),
        _loadRecentActivities(),
      ]);
    } catch (e) {
      print("Error loading dashboard data: $e");
      _snack("Failed to load dashboard data");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodayAttendanceStatus() async {
    try {
      final apiService = ApiService();
      final statusData = await apiService.getTodayAttendanceStatus();
      print("📊 Today's Attendance Status: $statusData");
      
      if (statusData != null && mounted) {
        setState(() {
          // Update check-in/check-out status from API
          if (statusData['status'] == 'checked_in') {
            isCheckedIn = true;
            checkInTime = statusData['check_in_time'] ?? "--:--";
            checkOutTime = "--:--";
          } else if (statusData['status'] == 'completed') {
            isCheckedIn = false;
            checkInTime = statusData['check_in_time'] ?? "--:--";
            checkOutTime = statusData['check_out_time'] ?? "--:--";
          } else {
            isCheckedIn = false;
            checkInTime = "--:--";
            checkOutTime = "--:--";
          }
        });
        
        // Save to local storage for persistence
        await _saveAttendanceState(isCheckedIn, checkInTime, checkOutTime);
      }
    } catch (e) {
      print("❌ Error loading today's attendance status: $e");
      // Keep existing local state if API fails
    }
  }

  Future<void> _loadEmployeeProfile() async {
    try {
      // First try to get data from SharedPreferences (login data)
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        print("📊 Using login user data: $userData");
        
        if (mounted) {
          setState(() {
            employeeData = {
              'username': userData['name'] ?? userData['username'] ?? 'User',
              'role': userData['role'] ?? 'Employee',
              'department': userData['department'] ?? 'Department',
              'employee_id': userData['empId'] ?? userData['employee_id'] ?? 'N/A',
              'email': userData['email'] ?? 'N/A',
              'presentDays': 22,
              'absentDays': 2,
              'leaveDays': 1,
              'totalLeaves': 24,
              'usedLeaves': 5,
              'pendingLeaves': 1,
            };
          });
        }
        return;
      }
      
      // Fallback: Try API call
      final apiService = ApiService();
      final data = await apiService.getLoggedEmployee();
      print("📊 Employee Profile API Response: $data");
      
      if (data != null && mounted) {
        setState(() {
          employeeData = data;
        });
        
        // Debug: Print all employee data keys
        print("🔑 Employee Data Keys: ${data.keys.toList()}");
        print("👤 Username: ${data['username']}");
        print("🏢 Department: ${data['department']}");
        print("🎯 Role: ${data['role']}");
        print("🆔 Employee ID: ${data['employee_id']}");
      } else {
        // Final fallback to mock data for development
        print("🔄 Using mock employee data due to API unavailability");
        if (mounted) {
          setState(() {
            employeeData = {
              'username': 'admin-user',
              'role': 'admin',
              'department': 'Human Resources',
              'employee_id': 'EMP001',
              'email': 'admin@gmail.com',
              'presentDays': 22,
              'absentDays': 2,
              'leaveDays': 1,
              'totalLeaves': 24,
              'usedLeaves': 5,
              'pendingLeaves': 1,
            };
          });
        }
      }
    } catch (e) {
      print("❌ Error loading employee profile: $e");
      // Fallback to mock data on error
      print("🔄 Using mock employee data due to error");
      if (mounted) {
        setState(() {
          employeeData = {
            'username': 'admin-user',
            'role': 'admin',
            'department': 'Human Resources',
            'employee_id': 'EMP001',
            'email': 'admin@gmail.com',
            'presentDays': 22,
            'absentDays': 2,
            'leaveDays': 1,
            'totalLeaves': 24,
            'usedLeaves': 5,
            'pendingLeaves': 1,
          };
        });
      }
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final apiService = ApiService();
      
      // Try to get real attendance data from API
      final attendanceData = await apiService.getAttendanceData();
      print("📊 Attendance API Response: $attendanceData");
      
      if (attendanceData != null && mounted) {
        setState(() {
          presentDays = attendanceData['presentDays'] ?? 0;
          absentDays = attendanceData['absentDays'] ?? 0;
          leaveDays = attendanceData['leaveDays'] ?? 0;
        });
      } else {
        // Fallback to calculating from current month data
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final workingDays = daysInMonth - 8; // Assuming 8 weekends
        
        if (mounted) {
          setState(() {
            presentDays = workingDays - 3; // Mock calculation
            absentDays = 2;
            leaveDays = 1;
          });
        }
      }
    } catch (e) {
      print("❌ Error loading attendance data: $e");
      // Use fallback data
      if (mounted) {
        setState(() {
          presentDays = 20;
          absentDays = 2;
          leaveDays = 1;
        });
      }
    }
  }

  Future<void> _loadLeaveData() async {
    try {
      final apiService = ApiService();
      
      // Try to get real leave data from API
      final leaveData = await apiService.getLeaveBalance();
      print("📊 Leave API Response: $leaveData");
      
      if (leaveData != null && mounted) {
        setState(() {
          totalLeaves = leaveData['totalLeaves'] ?? 24;
          usedLeaves = leaveData['usedLeaves'] ?? 0;
          pendingLeaves = leaveData['pendingLeaves'] ?? 0;
        });
      } else {
        // Fallback to default leave allocation
        if (mounted) {
          setState(() {
            totalLeaves = 24; // Standard annual leave
            usedLeaves = 3;   // Some leaves used
            pendingLeaves = 1; // One pending request
          });
        }
      }
    } catch (e) {
      print("❌ Error loading leave data: $e");
      // Use fallback data
      if (mounted) {
        setState(() {
          totalLeaves = 24;
          usedLeaves = 3;
          pendingLeaves = 1;
        });
      }
    }
  }

  Future<void> _loadHolidays() async {
    try {
      // Note: You might need to implement getHolidays in ApiService
      // For now, using dynamic data based on current date
      final now = DateTime.now();
      final currentYear = now.year;
      
      if (mounted) {
        setState(() {
          upcomingHolidays = [
            {"name": "Republic Day", "date": "26 Jan ${currentYear + 1}"},
            {"name": "Holi", "date": "25 Mar ${currentYear + 1}"},
            {"name": "Independence Day", "date": "15 Aug ${currentYear + 1}"},
            {"name": "Diwali", "date": "12 Nov ${currentYear + 1}"},
          ];
        });
      }
    } catch (e) {
      print("❌ Error loading holidays: $e");
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final apiService = ApiService();
      final activities = await apiService.getRecentActivities();
      print("📊 Recent Activities API Response: $activities");
      
      if (activities.isNotEmpty && mounted) {
        setState(() {
          recentActivities = activities.map((activity) => {
            "title": activity['title'] ?? activity['description'] ?? 'Activity',
            "time": activity['time'] ?? activity['created_at'] ?? 'Recently',
            "icon": _getIconForActivity(activity['type'] ?? activity['title'] ?? ''),
          }).toList();
        });
      } else {
        // Fallback to dynamic activities based on current data
        final now = DateTime.now();
        final today = DateFormat('dd MMM yyyy').format(now);
        final yesterday = DateFormat('dd MMM yyyy').format(now.subtract(const Duration(days: 1)));
        
        if (mounted) {
          setState(() {
            recentActivities = [
              {
                "title": "Logged in to system", 
                "time": "Today at ${DateFormat('HH:mm').format(now)}", 
                "icon": Icons.login
              },
              if (isCheckedIn || checkInTime != "--:--")
                {
                  "title": "Attendance marked", 
                  "time": "Today at $checkInTime", 
                  "icon": Icons.calendar_today
                },
              {
                "title": "${employeeData?['department'] ?? 'Department'} updates", 
                "time": yesterday, 
                "icon": Icons.business
              },
              if (usedLeaves > 0)
                {
                  "title": "Leave balance updated", 
                  "time": "This week", 
                  "icon": Icons.beach_access
                },
              {
                "title": "Profile synchronized", 
                "time": "This week", 
                "icon": Icons.sync
              },
            ];
          });
        }
      }
    } catch (e) {
      print("❌ Error loading recent activities: $e");
      // Use fallback activities
      if (mounted) {
        setState(() {
          recentActivities = [
            {
              "title": "System login", 
              "time": "Today", 
              "icon": Icons.login
            },
            {
              "title": "Dashboard accessed", 
              "time": "Just now", 
              "icon": Icons.dashboard
            },
          ];
        });
      }
    }
  }

  IconData _getIconForActivity(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'login':
      case 'signin':
        return Icons.login;
      case 'attendance':
      case 'checkin':
      case 'checkout':
        return Icons.calendar_today;
      case 'leave':
      case 'vacation':
        return Icons.beach_access;
      case 'profile':
      case 'update':
        return Icons.person;
      case 'meeting':
        return Icons.people;
      case 'document':
        return Icons.description;
      default:
        return Icons.notifications;
    }
  }

  // ----------------------------------------------------
  // ATTENDANCE METHODS
  // ----------------------------------------------------
  Future<void> _toggleCheckInOut() async {
    if (isAttendanceLoading) return;

    setState(() {
      isAttendanceLoading = true;
    });

    try {
      bool success;
      final now = DateTime.now();
      final currentTime = DateFormat('HH:mm').format(now);
      
      if (!isCheckedIn) {
        // Only allow check-in if not already completed for the day
        if (checkInTime != "--:--" && checkOutTime != "--:--") {
          _snack('Attendance already completed for today');
          return;
        }
        
        try {
          final apiService = ApiService();
          success = await apiService.checkIn();
        } catch (e) {
          print("❌ Check-in API error: $e");
          success = false;
        }
        
        // Always allow check-in for development (fallback to local storage)
        if (!success) {
          print("🔄 Using local check-in due to API unavailability");
          success = true;
        }
        
        if (success && mounted) {
          // Save to local storage
          await _saveAttendanceState(true, currentTime, "--:--");
          
          setState(() {
            isCheckedIn = true;
            checkInTime = currentTime;
            checkOutTime = "--:--";
            presentDays++;
          });
          
          // Add to recent activities
          _addRecentActivity(
            "Checked in at $checkInTime", 
            "Just now", 
            Icons.login
          );
          
          _snack('Checked in at $checkInTime');
        } else {
          _snack('Check-in failed');
        }
      } else {
        try {
          final apiService = ApiService();
          success = await apiService.checkOut();
        } catch (e) {
          print("❌ Check-out API error: $e");
          success = false;
        }
        
        // Always allow check-out for development (fallback to local storage)
        if (!success) {
          print("🔄 Using local check-out due to API unavailability");
          success = true;
        }
        
        if (success && mounted) {
          // Save to local storage
          await _saveAttendanceState(false, checkInTime, currentTime);
          
          setState(() {
            isCheckedIn = false;
            checkOutTime = currentTime;
          });
          
          // Add to recent activities
          _addRecentActivity(
            "Checked out at $checkOutTime", 
            "Just now", 
            Icons.logout
          );
          
          _snack('Checked out at $checkOutTime');
        } else {
          _snack('Check-out failed');
        }
      }
    } catch (e) {
      print("❌ Error in check-in/out: $e");
      _snack('Attendance action failed');
    } finally {
      if (mounted) {
        setState(() {
          isAttendanceLoading = false;
        });
      }
    }
  }

  void _addRecentActivity(String title, String time, IconData icon) {
    if (mounted) {
      setState(() {
        recentActivities.insert(0, {
          "title": title,
          "time": time,
          "icon": icon,
        });
        
        // Keep only last 5 activities
        if (recentActivities.length > 5) {
          recentActivities = recentActivities.sublist(0, 5);
        }
      });
    }
  }

  // ----------------------------------------------------
  // UI BUILD METHODS
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading Dashboard...', 
                   style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: shouldShowSidebar ? HRMSSidebar() : null,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[800],
        title: const Text('Employee Dashboard', 
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.blue[800]),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.blue[800]),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildAttendanceSection(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildLeaveBalance(),
              const SizedBox(height: 20),
              _buildUpcomingHolidays(),
              const SizedBox(height: 20),
              _buildRecentActivities(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ----------------------------------------------------
  // PROFILE HEADER - IMPROVED DESIGN
  // ----------------------------------------------------
  Widget _buildProfileHeader() {
    // Extract data from API response with proper fallbacks
    final String username = employeeData?['username']?.toString() ?? "User";
    final String role = employeeData?['role']?.toString() ?? "Employee";
    final String department = employeeData?['department']?.toString() ?? "Department";
    final String employeeId = employeeData?['employee_id']?.toString() ?? "ID Not Found";
    
    // Format username to display name (capitalize first letters)
    String formatName(String name) {
      if (name.contains('-')) {
        return name.split('-').map((part) => 
          part[0].toUpperCase() + part.substring(1)
        ).join(' ');
      }
      return name[0].toUpperCase() + name.substring(1);
    }

    final String displayName = formatName(username);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[800]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                "https://ui-avatars.com/api/?name=$displayName&background=0D8ABC&color=fff&size=150",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(Icons.person, size: 40, color: Colors.blue[700]),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.blue[700],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business_center, size: 14, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        department,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge, size: 14, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Text(
                      employeeId,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ATTENDANCE SECTION - IMPROVED DESIGN
  // ----------------------------------------------------
  Widget _buildAttendanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _attendanceCard(
                  'Check In',
                  checkInTime,
                  Icons.login_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _attendanceCard(
                  'Check Out',
                  checkOutTime,
                  Icons.logout_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (isAttendanceLoading || !isAttendanceButtonEnabled) ? null : _toggleCheckInOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: !isAttendanceButtonEnabled 
                    ? Colors.grey[400] 
                    : (isCheckedIn ? Colors.red[600] : Colors.green[600]),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: isCheckedIn ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
              ),
              child: isAttendanceLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          !isAttendanceButtonEnabled 
                              ? Icons.check_circle_rounded 
                              : (isCheckedIn ? Icons.logout_rounded : Icons.login_rounded),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          attendanceButtonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCheckedIn && checkInTime != "--:--") ...[
                          const SizedBox(width: 8),
                          Text(
                            '($checkInTime)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusItem('Present', presentDays.toString(), Colors.green[600]!),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                _statusItem('Absent', absentDays.toString(), Colors.red[600]!),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                _statusItem('Leave', leaveDays.toString(), Colors.orange[600]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // QUICK ACTIONS - IMPROVED DESIGN
  // ----------------------------------------------------
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _actionItem(Icons.calendar_today, 'Apply\nLeave', Colors.blue[600]!, _applyLeave),
              _actionItem(Icons.receipt_long, 'Payslip', Colors.green[600]!, _viewPayslip),
              _actionItem(Icons.people_alt, 'Team', Colors.purple[600]!, _viewTeam),
              _actionItem(Icons.description, 'Documents', Colors.orange[600]!, _viewDocuments),
              _actionItem(Icons.schedule, 'Shift', Colors.teal[600]!, _viewShift),
              _actionItem(Icons.announcement, 'Announce\nments', Colors.red[600]!, _viewAnnouncements),
              _actionItem(Icons.person, 'Profile', Colors.indigo[600]!, _viewProfile),
              _actionItem(Icons.more_horiz, 'More', Colors.grey[600]!, _showMoreOptions),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // LEAVE BALANCE - IMPROVED DESIGN
  // ----------------------------------------------------
  Widget _buildLeaveBalance() {
    int availableLeaves = totalLeaves - usedLeaves;
    double leavePercentage = totalLeaves > 0 ? usedLeaves / totalLeaves : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leave Balance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: _viewLeaveHistory,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[600],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text(
                  'View History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth * leavePercentage,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[400]!],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(leavePercentage * 100).toStringAsFixed(0)}% Used',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$usedLeaves of $totalLeaves days',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _leaveCard('Total', totalLeaves.toString(), Colors.blue[600]!, Icons.calendar_month_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _leaveCard('Used', usedLeaves.toString(), Colors.red[600]!, Icons.event_busy_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _leaveCard('Available', availableLeaves.toString(), Colors.green[600]!, Icons.event_available_rounded),
              ),
            ],
          ),
          if (pendingLeaves > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pending_actions_rounded, color: Colors.orange[600], size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$pendingLeaves leave request(s) pending approval',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _leaveCard(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // HOLIDAYS - IMPROVED DESIGN
  // ----------------------------------------------------
  Widget _buildUpcomingHolidays() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Holidays',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: _viewAllHolidays,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[600],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcomingHolidays.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No upcoming holidays',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...upcomingHolidays.map((holiday) => _holidayItem(holiday['name']!, holiday['date']!)),
        ],
      ),
    );
  }

  Widget _holidayItem(String name, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event_rounded, color: Colors.blue[600], size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // RECENT ACTIVITIES - IMPROVED DESIGN
  // ----------------------------------------------------
  Widget _buildRecentActivities() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (recentActivities.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No recent activities',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentActivities.map((activity) =>
                _activityItem(activity['title'], activity['time'], activity['icon'])),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green[600], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // BOTTOM NAVIGATION - IMPROVED DESIGN
  // ----------------------------------------------------
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded, size: 24),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.beach_access_rounded, size: 24),
              label: 'Leave',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 24),
              label: 'Profile',
            ),
          ],
          onTap: _handleBottomNavigation,
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // LOGIC FUNCTIONS
  // ----------------------------------------------------
  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
    _snack("Dashboard updated");
  }

  void _applyLeave() {
    _addRecentActivity("Leave application started", "Just now", Icons.beach_access_rounded);
    _snack("Opening Leave Form...");
  }

  void _viewPayslip() {
    _addRecentActivity("Payslip viewed", "Just now", Icons.receipt_long_rounded);
    _snack("Opening Payslip...");
  }

  void _viewTeam() => _snack("Opening Team...");
  void _viewDocuments() => _snack("Opening Documents...");
  void _viewShift() => _snack("Opening Shift Details...");
  void _viewAnnouncements() => _snack("Opening Announcements...");
  void _viewProfile() => _snack("Opening Profile...");
  void _viewLeaveHistory() => _snack("Opening Leave History...");
  void _viewAllHolidays() => _snack("Opening All Holidays...");
  void _showNotifications(BuildContext context) => _snack("Opening Notifications...");
  void _navigateToSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.person_outline, color: Colors.blue[700]),
              title: Text('Profile Settings'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _snack("Profile settings coming soon");
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_outlined, color: Colors.orange[700]),
              title: Text('Notifications'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _snack("Notification settings coming soon");
              },
            ),
            ListTile(
              leading: Icon(Icons.security_outlined, color: Colors.green[700]),
              title: Text('Privacy & Security'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _snack("Privacy settings coming soon");
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red[700]),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[700]),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Logging out...'),
              ],
            ),
          ),
        ),
      );

      final authService = AuthApiService();
      final success = await authService.logout();

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        _snack('Logged out successfully');
        
        // Navigate to login screen and clear all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginScreen()),
          (route) => false,
        );
      } else {
        _snack('Logout failed. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('Logout error: $e');
      _snack('Logout failed. Please try again.');
    }
  }

  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        // Home - already on dashboard
        break;
      case 1:
        // Attendance
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AttendanceScreen()),
        );
        break;
      case 2:
        // Leave
        _snack("Leave management coming soon");
        break;
      case 3:
        // Profile
        _snack("Profile management coming soon");
        break;
      default:
        _snack("Navigation index: $index");
    }
  }

  // ----------------------------------------------------
  // HELPERS
  // ----------------------------------------------------
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.help_outline_rounded, color: Colors.blue),
              title: Text("Help & Support", style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            const ListTile(
              leading: Icon(Icons.policy_rounded, color: Colors.green),
              title: Text("Policies", style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            const ListTile(
              leading: Icon(Icons.feedback_rounded, color: Colors.orange),
              title: Text("Feedback", style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}