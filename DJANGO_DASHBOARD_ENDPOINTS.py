# Django Backend Endpoints for Employee Dashboard Real Data

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import datetime, timedelta
from django.db.models import Count, Q
from calendar import monthrange

class AttendanceSummaryView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            current_month = timezone.now().month
            current_year = timezone.now().year
            
            # Get attendance records for current month
            attendance_records = Attendance.objects.filter(
                employee=employee,
                date__month=current_month,
                date__year=current_year
            )
            
            # Calculate statistics
            present_days = attendance_records.filter(
                check_in__isnull=False,
                status='present'
            ).count()
            
            absent_days = attendance_records.filter(
                status='absent'
            ).count()
            
            # Get leave days from Leave model (if you have one)
            leave_days = 0  # You can implement this based on your Leave model
            
            # Calculate working days in current month (excluding weekends)
            _, days_in_month = monthrange(current_year, current_month)
            working_days = 0
            for day in range(1, days_in_month + 1):
                date_obj = datetime(current_year, current_month, day)
                if date_obj.weekday() < 5:  # Monday = 0, Sunday = 6
                    working_days += 1
            
            return Response({
                "presentDays": present_days,
                "absentDays": absent_days,
                "leaveDays": leave_days,
                "workingDays": working_days,
                "month": current_month,
                "year": current_year
            }, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Failed to get attendance summary: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LeaveBalanceView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            current_year = timezone.now().year
            
            # Assuming you have a Leave model or leave allocation in Employee model
            total_leaves = 24  # Standard annual leave allocation
            
            # Calculate used leaves (you can implement based on your Leave model)
            used_leaves = 0  # Implement based on your Leave model
            pending_leaves = 0  # Implement based on your Leave model
            
            # If you have a Leave model, use something like:
            # used_leaves = Leave.objects.filter(
            #     employee=employee,
            #     status='approved',
            #     start_date__year=current_year
            # ).aggregate(total=Sum('days'))['total'] or 0
            
            # pending_leaves = Leave.objects.filter(
            #     employee=employee,
            #     status='pending',
            #     start_date__year=current_year
            # ).aggregate(total=Sum('days'))['total'] or 0
            
            available_leaves = total_leaves - used_leaves
            
            return Response({
                "totalLeaves": total_leaves,
                "usedLeaves": used_leaves,
                "availableLeaves": available_leaves,
                "pendingLeaves": pending_leaves,
                "year": current_year
            }, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Failed to get leave balance: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AttendanceStatusView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            today = timezone.now().date()
            
            attendance = Attendance.objects.filter(employee=employee, date=today).first()
            
            if not attendance:
                return Response({
                    "status": "not_checked_in",
                    "message": "No attendance record for today",
                    "date": today.strftime("%Y-%m-%d")
                }, status=status.HTTP_200_OK)
            
            # Determine status
            if attendance.check_in and not attendance.check_out:
                status_text = "checked_in"
            elif attendance.check_in and attendance.check_out:
                status_text = "completed"
            else:
                status_text = "not_checked_in"
            
            response_data = {
                "status": status_text,
                "date": today.strftime("%Y-%m-%d"),
                "check_in_time": attendance.check_in.strftime("%H:%M:%S") if attendance.check_in else None,
                "check_out_time": attendance.check_out.strftime("%H:%M:%S") if attendance.check_out else None,
                "work_hours": attendance.total_work_hours if attendance.total_work_hours else 0,
                "overtime_hours": attendance.overtime_hours if attendance.overtime_hours else 0,
                "is_overtime": attendance.is_overtime if attendance.is_overtime else False
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Failed to get attendance status: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class RecentActivitiesView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            
            activities = []
            
            # Get recent attendance records
            recent_attendance = Attendance.objects.filter(
                employee=employee,
                created_at__gte=timezone.now() - timedelta(days=7)
            ).order_by('-created_at')[:3]
            
            for attendance in recent_attendance:
                if attendance.check_in:
                    activities.append({
                        "title": f"Checked in at {attendance.check_in.strftime('%H:%M')}",
                        "time": attendance.created_at.strftime("%d %b %Y"),
                        "type": "checkin"
                    })
                if attendance.check_out:
                    activities.append({
                        "title": f"Checked out at {attendance.check_out.strftime('%H:%M')}",
                        "time": attendance.created_at.strftime("%d %b %Y"),
                        "type": "checkout"
                    })
            
            # Add other activities (you can expand this based on your models)
            activities.append({
                "title": "Profile updated",
                "time": "This week",
                "type": "profile"
            })
            
            activities.append({
                "title": "System login",
                "time": "Today",
                "type": "login"
            })
            
            # Sort by most recent first
            activities = sorted(activities, key=lambda x: x.get('time', ''), reverse=True)[:5]
            
            return Response(activities, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Failed to get recent activities: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DashboardDataView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            
            # Get all dashboard data in one call
            current_month = timezone.now().month
            current_year = timezone.now().year
            today = timezone.now().date()
            
            # Attendance summary
            attendance_records = Attendance.objects.filter(
                employee=employee,
                date__month=current_month,
                date__year=current_year
            )
            
            present_days = attendance_records.filter(
                check_in__isnull=False,
                status='present'
            ).count()
            
            # Today's attendance
            today_attendance = Attendance.objects.filter(
                employee=employee, 
                date=today
            ).first()
            
            # Leave balance
            total_leaves = 24
            used_leaves = 3  # Implement based on your Leave model
            
            dashboard_data = {
                "employee": {
                    "id": str(employee.id),
                    "name": employee.name if hasattr(employee, 'name') else str(employee),
                    "email": employee.email if hasattr(employee, 'email') else '',
                    "role": employee.role if hasattr(employee, 'role') else 'Employee',
                    "department": employee.department if hasattr(employee, 'department') else 'Department'
                },
                "attendance": {
                    "presentDays": present_days,
                    "absentDays": 0,  # Calculate based on your logic
                    "leaveDays": 1,   # Calculate based on your logic
                    "todayStatus": {
                        "isCheckedIn": bool(today_attendance and today_attendance.check_in and not today_attendance.check_out),
                        "checkInTime": today_attendance.check_in.strftime("%H:%M:%S") if today_attendance and today_attendance.check_in else None,
                        "checkOutTime": today_attendance.check_out.strftime("%H:%M:%S") if today_attendance and today_attendance.check_out else None
                    }
                },
                "leaves": {
                    "totalLeaves": total_leaves,
                    "usedLeaves": used_leaves,
                    "availableLeaves": total_leaves - used_leaves,
                    "pendingLeaves": 1
                }
            }
            
            return Response(dashboard_data, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Failed to get dashboard data: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Add these to your urls.py:
"""
from django.urls import path
from .views import (
    AttendanceSummaryView, 
    LeaveBalanceView, 
    AttendanceStatusView, 
    RecentActivitiesView,
    DashboardDataView
)

urlpatterns = [
    # ... your existing URLs
    path('api/employee/attendance-summary/', AttendanceSummaryView.as_view(), name='attendance-summary'),
    path('api/employee/leave-balance/', LeaveBalanceView.as_view(), name='leave-balance'),
    path('api/employee/attendance-status/', AttendanceStatusView.as_view(), name='attendance-status'),
    path('api/employee/recent-activities/', RecentActivitiesView.as_view(), name='recent-activities'),
    path('api/employee/dashboard/', DashboardDataView.as_view(), name='dashboard-data'),
]
"""