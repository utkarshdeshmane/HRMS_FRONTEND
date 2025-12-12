# Add these views to your Django views.py file

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import datetime, timedelta
from django.db.models import Count, Q
from calendar import monthrange

# ========== Leave Balance View ==========
class LeaveBalanceView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            current_year = timezone.now().year
            
            # Standard leave allocation (adjust based on your business rules)
            total_leaves = 24
            
            # Calculate used leaves (implement based on your Leave model if you have one)
            # If you have a Leave model, use something like:
            # used_leaves = Leave.objects.filter(
            #     employee=employee,
            #     status='approved',
            #     start_date__year=current_year
            # ).aggregate(total=Sum('days'))['total'] or 0
            
            used_leaves = 3  # Placeholder - replace with actual calculation
            pending_leaves = 1  # Placeholder - replace with actual calculation
            
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


# ========== Attendance Summary View ==========
class AttendanceSummaryView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            current_month = timezone.now().month
            current_year = timezone.now().year
            
            # Get attendance records for current month
            # Adjust the model name and fields based on your Attendance model
            attendance_records = Attendance.objects.filter(
                employee=employee,
                date__month=current_month,
                date__year=current_year
            )
            
            # Calculate statistics
            present_days = attendance_records.filter(
                check_in__isnull=False
            ).count()
            
            # Calculate working days in current month (excluding weekends)
            _, days_in_month = monthrange(current_year, current_month)
            working_days = 0
            for day in range(1, days_in_month + 1):
                date_obj = datetime(current_year, current_month, day)
                if date_obj.weekday() < 5:  # Monday = 0, Sunday = 6
                    working_days += 1
            
            absent_days = max(0, working_days - present_days)
            leave_days = 1  # Calculate from your Leave model if available
            
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


# ========== Attendance Status View (Today's Status) ==========
class AttendanceStatusView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            today = timezone.now().date()
            
            # Get today's attendance record
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
                "work_hours": getattr(attendance, 'total_work_hours', 0) or 0,
                "overtime_hours": getattr(attendance, 'overtime_hours', 0) or 0,
                "is_overtime": getattr(attendance, 'is_overtime', False) or False
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


# ========== Recent Activities View ==========
class RecentActivitiesView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            employee = Employee.objects.get(id=request.user.id)
            
            activities = []
            
            # Get recent attendance records (last 7 days)
            recent_attendance = Attendance.objects.filter(
                employee=employee,
                date__gte=timezone.now().date() - timedelta(days=7)
            ).order_by('-date')[:5]
            
            for attendance in recent_attendance:
                if attendance.check_in:
                    activities.append({
                        "title": f"Checked in at {attendance.check_in.strftime('%H:%M')}",
                        "time": attendance.date.strftime("%d %b %Y"),
                        "type": "checkin"
                    })
                if attendance.check_out:
                    activities.append({
                        "title": f"Checked out at {attendance.check_out.strftime('%H:%M')}",
                        "time": attendance.date.strftime("%d %b %Y"),
                        "type": "checkout"
                    })
            
            # Add other activities
            activities.extend([
                {
                    "title": "Profile accessed",
                    "time": "Today",
                    "type": "profile"
                },
                {
                    "title": "System login",
                    "time": "Today",
                    "type": "login"
                }
            ])
            
            # Sort by most recent first and limit to 5
            activities = activities[:5]
            
            return Response(activities, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Failed to get recent activities: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ========== Dashboard Data View (All data in one call) ==========
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
                check_in__isnull=False
            ).count()
            
            # Today's attendance
            today_attendance = Attendance.objects.filter(
                employee=employee, 
                date=today
            ).first()
            
            # Leave balance
            total_leaves = 24
            used_leaves = 3
            
            dashboard_data = {
                "employee": {
                    "id": str(employee.id),
                    "name": getattr(employee, 'name', str(employee)),
                    "email": getattr(employee, 'email', ''),
                    "role": getattr(employee, 'role', 'Employee'),
                    "department": getattr(employee, 'department', 'Department')
                },
                "attendance": {
                    "presentDays": present_days,
                    "absentDays": 2,
                    "leaveDays": 1,
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