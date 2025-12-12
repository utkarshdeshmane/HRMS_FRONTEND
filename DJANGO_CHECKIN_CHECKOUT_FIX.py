from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from datetime import datetime, date
from django.contrib.auth.decorators import login_required
from django.utils.decorators import method_decorator
from rest_framework.permissions import IsAuthenticated

class CheckInView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # Get employee from authenticated user
            employee = Employee.objects.get(id=request.user.id)
            today = timezone.now().date()
            
            # Check for existing attendance record
            attendance = Attendance.objects.filter(employee=employee, date=today).first()
            
            # Prevent duplicate check-in
            if attendance and attendance.check_in:
                return Response({
                    "error": "Already checked in today",
                    "check_in_time": attendance.check_in.strftime("%H:%M:%S")
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get device information
            user_agent = request.headers.get("User-Agent", "")
            device_type = detect_device_type(user_agent)
            
            # Create or update attendance record
            if not attendance:
                attendance = Attendance(
                    employee=employee,
                    date=today,
                    check_in=timezone.now(),
                    check_in_device=device_type,
                    status="present",  # Set status to present on check-in
                    created_at=timezone.now(),
                    updated_at=timezone.now(),
                )
            else:
                attendance.check_in = timezone.now()
                attendance.check_in_device = device_type
                attendance.status = "present"
                attendance.updated_at = timezone.now()
            
            attendance.save()
            
            return Response({
                "message": "Check-in successful",
                "check_in_time": attendance.check_in.strftime("%H:%M:%S"),
                "device": device_type,
                "date": today.strftime("%Y-%m-%d")
            }, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Check-in failed: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CheckOutView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # Get employee from authenticated user
            employee = Employee.objects.get(id=request.user.id)
            today = timezone.now().date()
            
            # Get today's attendance record
            attendance = Attendance.objects.filter(employee=employee, date=today).first()
            
            # Validation checks
            if not attendance:
                return Response({
                    "error": "No attendance record found for today. Please check-in first."
                }, status=status.HTTP_400_BAD_REQUEST)
                
            if not attendance.check_in:
                return Response({
                    "error": "Check-in first before checking out"
                }, status=status.HTTP_400_BAD_REQUEST)
                
            if attendance.check_out:
                return Response({
                    "error": "Already checked out today",
                    "check_out_time": attendance.check_out.strftime("%H:%M:%S")
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get device information
            user_agent = request.headers.get("User-Agent", "")
            device_type = detect_device_type(user_agent)
            
            # Set check-out time
            checkout_time = timezone.now()
            attendance.check_out = checkout_time
            attendance.check_out_device = device_type
            
            # Calculate work hours (timezone safe)
            time_delta = attendance.check_out - attendance.check_in
            total_seconds = time_delta.total_seconds()
            hours = round(total_seconds / 3600, 2)
            attendance.total_work_hours = hours
            
            # Calculate overtime (assuming 8 hours is standard, adjust as needed)
            standard_hours = 8.0
            if hours > standard_hours:
                attendance.is_overtime = True
                attendance.overtime_hours = round(hours - standard_hours, 2)
            else:
                attendance.is_overtime = False
                attendance.overtime_hours = 0.0
            
            # Update status and timestamp
            attendance.status = "completed"
            attendance.updated_at = timezone.now()
            attendance.save()
            
            return Response({
                "message": "Check-out successful",
                "check_in_time": attendance.check_in.strftime("%H:%M:%S"),
                "check_out_time": attendance.check_out.strftime("%H:%M:%S"),
                "work_hours": hours,
                "overtime_hours": attendance.overtime_hours,
                "is_overtime": attendance.is_overtime,
                "device": device_type,
                "date": today.strftime("%Y-%m-%d")
            }, status=status.HTTP_200_OK)
            
        except Employee.DoesNotExist:
            return Response({
                "error": "Employee not found"
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                "error": f"Check-out failed: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Helper function for device detection
def detect_device_type(user_agent):
    """
    Detect device type from User-Agent string
    """
    if not user_agent:
        return "unknown"
    
    user_agent = user_agent.lower()
    
    if 'mobile' in user_agent or 'android' in user_agent or 'iphone' in user_agent:
        return "mobile"
    elif 'tablet' in user_agent or 'ipad' in user_agent:
        return "tablet"
    else:
        return "desktop"


# Additional view for getting today's attendance status
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
            
            response_data = {
                "status": "checked_in" if attendance.check_in and not attendance.check_out else "completed",
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