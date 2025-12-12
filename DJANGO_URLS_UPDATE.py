# Add these URL patterns to your existing Django urls.py

# Your existing attendance URLs:
urlpatterns = [
    # Existing attendance paths
    path("checkin/", CheckInView.as_view(), name="checkin"),
    path("checkout/", CheckOutView.as_view(), name="checkout"),
    path("Attendance/overall/", OverallAttendanceListView.as_view()),
    path("Attendance/allmark/", EmpMarkAllView.as_view(), name="AttendanceMarkAll"),
    path("Attendance/<str:pk>/", EmpAttendanceListView.as_view(), name="EmpAttendance"),
    path("Attendance/mark/<str:pk>/", EmpAttendanceMarkView.as_view(), name="AttendanceMark"),
    
    # ADD THESE NEW DASHBOARD ENDPOINTS:
    path("leave-balance/", LeaveBalanceView.as_view(), name="leave-balance"),
    path("attendance-summary/", AttendanceSummaryView.as_view(), name="attendance-summary"),
    path("attendance-status/", AttendanceStatusView.as_view(), name="attendance-status"),
    path("recent-activities/", RecentActivitiesView.as_view(), name="recent-activities"),
    path("dashboard/", DashboardDataView.as_view(), name="dashboard-data"),
]