import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/employee_api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Data
  List<Map<String, dynamic>> attendanceRecords = [];
  Map<String, dynamic>? attendanceStats;
  Map<String, dynamic>? employeeData;
  
  // Loading states
  bool isLoading = true;
  bool isRefreshing = false;
  
  // Filters
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String selectedFilter = 'all'; // all, present, absent, late
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEmployeeData();
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        setState(() {
          employeeData = userData;
        });
      }
    } catch (e) {
      print("Error loading employee data: $e");
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      
      // Load attendance records and stats
      final records = await apiService.getAttendance();
      final stats = await apiService.getAttendanceData();
      
      if (mounted) {
        setState(() {
          attendanceRecords = _processAttendanceRecords(records);
          attendanceStats = stats ?? _generateMockStats();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading attendance data: $e");
      if (mounted) {
        setState(() {
          attendanceRecords = _generateMockAttendanceRecords();
          attendanceStats = _generateMockStats();
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _processAttendanceRecords(List<dynamic> records) {
    return records.map((record) => {
      'date': record['date'] ?? DateTime.now().toIso8601String(),
      'checkIn': record['check_in_time'] ?? record['checkIn'] ?? '--:--',
      'checkOut': record['check_out_time'] ?? record['checkOut'] ?? '--:--',
      'status': record['status'] ?? 'present',
      'workingHours': record['working_hours'] ?? record['workingHours'] ?? '0:00',
      'overtime': record['overtime'] ?? '0:00',
      'location': record['location'] ?? 'Office',
    }).toList().cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _generateMockAttendanceRecords() {
    List<Map<String, dynamic>> records = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      
      if (!isWeekend) {
        final checkIn = DateTime(date.year, date.month, date.day, 9, 0 + (i % 60));
        final checkOut = DateTime(date.year, date.month, date.day, 17, 30 + (i % 30));
        
        records.add({
          'date': date.toIso8601String(),
          'checkIn': DateFormat('HH:mm').format(checkIn),
          'checkOut': DateFormat('HH:mm').format(checkOut),
          'status': i % 10 == 0 ? 'late' : (i % 15 == 0 ? 'absent' : 'present'),
          'workingHours': '8:${30 + (i % 30)}',
          'overtime': i % 5 == 0 ? '1:00' : '0:00',
          'location': 'Office',
        });
      }
    }
    
    return records.reversed.toList();
  }

  Map<String, dynamic> _generateMockStats() {
    return {
      'totalDays': 22,
      'presentDays': 20,
      'absentDays': 2,
      'lateDays': 3,
      'totalHours': '160:00',
      'averageHours': '8:00',
      'overtimeHours': '12:00',
      'attendancePercentage': 90.9,
    };
  }

  List<Map<String, dynamic>> get filteredRecords {
    List<Map<String, dynamic>> filtered = attendanceRecords;
    
    // Filter by month
    filtered = filtered.where((record) {
      final recordDate = DateTime.parse(record['date']);
      final recordMonth = DateFormat('yyyy-MM').format(recordDate);
      return recordMonth == selectedMonth;
    }).toList();
    
    // Filter by status
    if (selectedFilter != 'all') {
      filtered = filtered.where((record) => record['status'] == selectedFilter).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isLoading
          ? _buildLoadingState()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2E7D32),
                              const Color(0xFF388E3C),
                              const Color(0xFF43A047),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.filter_list, color: Colors.white),
                                          onPressed: _showFilterDialog,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.refresh, color: Colors.white),
                                          onPressed: _refreshData,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  'My Attendance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(DateTime.now()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF2E7D32),
                          unselectedLabelColor: Colors.grey[600],
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                          ),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Records'),
                            Tab(text: 'Calendar'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildRecordsTab(),
                  _buildCalendarTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
            const Color(0xFF43A047),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading your attendance...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 30),
            _buildAttendanceProgress(),
            const SizedBox(height: 30),
            _buildMonthlyChart(),
            const SizedBox(height: 30),
            _buildRecentActivity(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = attendanceStats ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildModernStatCard(
              'Present Days',
              '${stats['presentDays'] ?? 0}',
              '${stats['totalDays'] ?? 0} total days',
              Icons.check_circle_rounded,
              const Color(0xFF10B981),
              const Color(0xFFECFDF5),
            ),
            _buildModernStatCard(
              'Absent Days',
              '${stats['absentDays'] ?? 0}',
              '${((stats['absentDays'] ?? 0) / (stats['totalDays'] ?? 1) * 100).toStringAsFixed(1)}% of month',
              Icons.cancel_rounded,
              const Color(0xFFEF4444),
              const Color(0xFFFEF2F2),
            ),
            _buildModernStatCard(
              'Late Arrivals',
              '${stats['lateDays'] ?? 0}',
              'This month',
              Icons.access_time_rounded,
              const Color(0xFFF59E0B),
              const Color(0xFFFEF3C7),
            ),
            _buildModernStatCard(
              'Attendance Rate',
              '${(stats['attendancePercentage'] ?? 0).toStringAsFixed(1)}%',
              'Overall performance',
              Icons.trending_up_rounded,
              const Color(0xFF3B82F6),
              const Color(0xFFEFF6FF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String title, String value, String subtitle, IconData icon, Color primaryColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 26,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceProgress() {
    final stats = attendanceStats ?? {};
    final attendancePercentage = (stats['attendancePercentage'] ?? 0.0) / 100;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Monthly Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(attendancePercentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: attendancePercentage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats['presentDays'] ?? 0} days present',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${stats['totalDays'] ?? 0} total days',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                'Weekly Pattern',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This Week',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final heights = [100.0, 120.0, 95.0, 110.0, 130.0, 0.0, 0.0];
                final colors = [
                  const Color(0xFF10B981), 
                  const Color(0xFF10B981), 
                  const Color(0xFFF59E0B), 
                  const Color(0xFF10B981), 
                  const Color(0xFF10B981), 
                  const Color(0xFFE5E7EB), 
                  const Color(0xFFE5E7EB)
                ];
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 800 + (index * 100)),
                      width: 28,
                      height: heights[index],
                      decoration: BoxDecoration(
                        gradient: heights[index] > 0 ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors[index],
                            colors[index].withOpacity(0.7),
                          ],
                        ) : null,
                        color: heights[index] == 0 ? colors[index] : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: heights[index] > 0 ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentRecords = filteredRecords.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                child: _buildModernActivityItem(record),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildModernActivityItem(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final status = record['status'];
    
    Color statusColor = const Color(0xFF10B981);
    IconData statusIcon = Icons.check_circle_rounded;
    Color backgroundColor = const Color(0xFFECFDF5);
    
    switch (status) {
      case 'late':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.access_time_rounded;
        backgroundColor = const Color(0xFFFEF3C7);
        break;
      case 'absent':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        backgroundColor = const Color(0xFFFEF2F2);
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.login_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record['checkIn'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.logout_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record['checkOut'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '• ${record['workingHours']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    return Column(
      children: [
        _buildModernFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF2E7D32),
            child: filteredRecords.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 80,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'No Records Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: _buildModernRecordCard(filteredRecords[index]),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernFilterBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMonth,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  items: _getMonthOptions().map((month) {
                    return DropdownMenuItem(
                      value: month['value'],
                      child: Text(month['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'present', child: Text('Present')),
                    DropdownMenuItem(value: 'absent', child: Text('Absent')),
                    DropdownMenuItem(value: 'late', child: Text('Late')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getMonthOptions() {
    List<Map<String, String>> months = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add({
        'value': DateFormat('yyyy-MM').format(month),
        'label': DateFormat('MMM yyyy').format(month),
      });
    }
    
    return months;
  }

  Widget _buildModernRecordCard(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final status = record['status'];
    
    Color statusColor = const Color(0xFF10B981);
    IconData statusIcon = Icons.check_circle_rounded;
    Color backgroundColor = const Color(0xFFECFDF5);
    
    switch (status) {
      case 'late':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.access_time_rounded;
        backgroundColor = const Color(0xFFFEF3C7);
        break;
      case 'absent':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        backgroundColor = const Color(0xFFFEF2F2);
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE').format(date),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildModernTimeInfo('In', record['checkIn'], Icons.login_rounded, const Color(0xFF10B981)),
                          const SizedBox(width: 24),
                          _buildModernTimeInfo('Out', record['checkOut'], Icons.logout_rounded, const Color(0xFFEF4444)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModernDetailInfo('Working Hours', record['workingHours'], Icons.schedule_rounded),
                Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
                _buildModernDetailInfo('Overtime', record['overtime'], Icons.timer_rounded),
                Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
                _buildModernDetailInfo('Location', record['location'], Icons.location_on_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTimeInfo(String label, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernDetailInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2E7D32),
                            const Color(0xFF388E3C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DateFormat('MMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildModernCalendarGrid(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildModernCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildModernCalendarGrid() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday;
    
    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Calendar grid
        ...List.generate((daysInMonth + startWeekday - 1) ~/ 7 + 1, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 2;
                
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return Container(width: 40, height: 40);
                }
                
                final date = DateTime(now.year, now.month, dayNumber);
                final record = attendanceRecords.firstWhere(
                  (r) => DateTime.parse(r['date']).day == dayNumber &&
                         DateTime.parse(r['date']).month == now.month,
                  orElse: () => {},
                );
                
                Color dayColor = const Color(0xFFF3F4F6);
                Color textColor = const Color(0xFF9CA3AF);
                bool hasRecord = record.isNotEmpty;
                
                if (hasRecord) {
                  switch (record['status']) {
                    case 'present':
                      dayColor = const Color(0xFF10B981);
                      textColor = Colors.white;
                      break;
                    case 'late':
                      dayColor = const Color(0xFFF59E0B);
                      textColor = Colors.white;
                      break;
                    case 'absent':
                      dayColor = const Color(0xFFEF4444);
                      textColor = Colors.white;
                      break;
                  }
                } else {
                  textColor = const Color(0xFF374151);
                }
                
                final isToday = dayNumber == DateTime.now().day && 
                               now.month == DateTime.now().month && 
                               now.year == DateTime.now().year;
                
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (dayNumber * 10)),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: dayColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday ? Border.all(
                      color: const Color(0xFF2E7D32),
                      width: 2,
                    ) : null,
                    boxShadow: hasRecord ? [
                      BoxShadow(
                        color: dayColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModernCalendarLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernLegendItem('Present', const Color(0xFF10B981), Icons.check_circle_rounded),
              _buildModernLegendItem('Late', const Color(0xFFF59E0B), Icons.access_time_rounded),
              _buildModernLegendItem('Absent', const Color(0xFFEF4444), Icons.cancel_rounded),
              _buildModernLegendItem('No Data', const Color(0xFFF3F4F6), Icons.help_outline_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernLegendItem(String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color == const Color(0xFFF3F4F6) ? const Color(0xFF9CA3AF) : Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Month'),
              subtitle: Text(DateFormat('MMM yyyy').format(DateTime.parse('$selectedMonth-01'))),
              onTap: () {
                // Show month picker
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Status'),
              subtitle: Text(selectedFilter.toUpperCase()),
              onTap: () {
                // Show status picker
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
    });
    
    await _loadAttendanceData();
    
    setState(() {
      isRefreshing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance data refreshed')),
    );
  }
}