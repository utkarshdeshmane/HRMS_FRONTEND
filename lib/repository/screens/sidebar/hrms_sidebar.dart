import 'package:flutter/material.dart';
import '../dashboard/dashboard.dart';

// // Employee Screens
// import '../employee/employee_profile.dart';
// import '../employee/employees.dart';
// import '../employee/shift_requests.dart';
// import '../employee/policies.dart';
// import '../employee/org_chart.dart';

// // Attendance Screens
// import '../attendance/attendance_dashboard.dart';
// import '../attendance/attendances.dart';
// import '../attendance/attendance_requests.dart';
// import '../attendance/my_attendances.dart';

// // Leave Screens
// import '../leave/leave_dashboard.dart';
// import '../leave/my_leave_requests.dart';
// import '../leave/leave_requests.dart';
// import '../leave/leave_types.dart';
// import '../leave/assigned_leave.dart';

// // Other modules
// import '../recruitment/recruitment.dart';
// import '../onboarding/onboarding.dart';
// import '../payroll/payroll.dart';
// import '../reports/reports.dart';
import '../organization/OrganizationScreen.dart';
import '../organization/OrganizationDashboardScreen.dart';
import '../department/DepartmentDashboardScreen.dart';
import '../employee/EmpDashScreen.dart';
import '../employee/EmpListScreen.dart';



import 'sidebar_menu.dart';

class HRMSSidebar extends StatefulWidget {
  @override
  _HRMSSidebarState createState() => _HRMSSidebarState();
}

class _HRMSSidebarState extends State<HRMSSidebar> {
  int? expandedIndex;

  List<SidebarMenuItem> get hrmsMenu => [
        SidebarMenuItem(
          title: "Dashboard",
          icon: Icons.dashboard,
          onTap: () => _openScreen(DashboardScreen()),
        ),

                SidebarMenuItem(
          title: "Company",
          icon: Icons.house,
          children: [
            SidebarMenuItem(title: "Organization", icon: Icons.abc_rounded,
            onTap: ()=> _openScreen(OrganizationDashboardScreen())),
            
            SidebarMenuItem(title: "Departments", icon: Icons.ac_unit,
            onTap: ()=> _openScreen(DepartmentDashboardScreen())),
            
          ],
        ),


        SidebarMenuItem(
          title: "Employee",
          icon: Icons.people,
          children: [
            SidebarMenuItem(
                title: "Profile", icon: Icons.person,
                onTap: ()=> _openScreen(EmpDashScreen())
            ),
            SidebarMenuItem(
                title: "Employees", icon: Icons.groups_3,
                onTap: ()=> _openScreen(EmployeeListScreen())
                ),
            SidebarMenuItem(
                title: "Shift Requests", icon: Icons.access_time_filled,
                // onTap: ()=> _openScreen(ShiftRequests())),
            ),
            SidebarMenuItem(
                title: "Policies", icon: Icons.rule_folder,
                // onTap: ()=> _openScreen(PoliciesScreen())),
            ),
            SidebarMenuItem(
                title: "Organization Chart", icon: Icons.account_tree,
                // onTap: ()=> _openScreen(OrgChartScreen())),
            ),
          ],
        ),

        SidebarMenuItem(
          title: "Attendance",
          icon: Icons.access_time,
          children: [
            SidebarMenuItem(
                title: "Dashboard", icon: Icons.dashboard_customize,
                // onTap: ()=> _openScreen(AttendanceDashboard())),
            ),
            SidebarMenuItem(
                title: "Attendances", icon: Icons.calendar_month,
                // onTap: ()=> _openScreen(Attendances())),
            ),
            SidebarMenuItem(
                title: "Attendance Requests", icon: Icons.pending_actions,
                // onTap: ()=> _openScreen(AttendanceRequests())),
            ),
            SidebarMenuItem(
                title: "My Attendances", icon: Icons.person_pin_circle,
                // onTap: ()=> _openScreen(MyAttendances())),
            ),
          ],
        ),

        SidebarMenuItem(
          title: "Leave",
          icon: Icons.beach_access,
          children: [
            SidebarMenuItem(
                title: "Dashboard", icon: Icons.dashboard,
                // onTap: ()=> _openScreen(LeaveDashboard())),
            ),
            SidebarMenuItem(
                title: "My Leave Requests", icon: Icons.note_alt,
                // onTap: ()=> _openScreen(MyLeaveRequests())),
            ),
            SidebarMenuItem(
                title: "Leave Requests", icon: Icons.assignment_turned_in,
                // onTap: ()=> _openScreen(LeaveRequests())),
            ),
            SidebarMenuItem(
                title: "Leave Types", icon: Icons.category,
                // onTap: ()=> _openScreen(LeaveTypes())),
            ),
            SidebarMenuItem(
                title: "Assigned Leave", icon: Icons.task_alt,
                // onTap: ()=> _openScreen(AssignedLeave())),
            ),
          ],
        ),

        SidebarMenuItem(
            title: "Recruitment", icon: Icons.how_to_reg,
            // onTap: ()=> _openScreen(RecruitmentScreen())),
        ),
        SidebarMenuItem(
            title: "Onboarding", icon: Icons.person_add_alt_1,
            // onTap: ()=> _openScreen(OnboardingScreen())),
        ),
        SidebarMenuItem(
            title: "Payroll", icon: Icons.payments,
            // onTap: ()=> _openScreen(PayrollScreen())),
        ),
        SidebarMenuItem(
            title: "Reports", icon: Icons.analytics,
            // onTap: ()=> _openScreen(ReportsScreen())),
        ),
      ];

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView.builder(
        itemCount: hrmsMenu.length,
        itemBuilder: (context, index) {
          final item = hrmsMenu[index];

          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                onTap: () {
                  if (item.children == null) {
                    item.onTap?.call();
                  } else {
                    setState(() {
                      expandedIndex = expandedIndex == index ? null : index;
                    });
                  }
                },
              ),

              if (item.children != null && expandedIndex == index)
                ...item.children!.map((child) => Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: ListTile(
                        leading: Icon(child.icon, size: 20),
                        title: Text(child.title),
                        onTap: () => child.onTap?.call(),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
