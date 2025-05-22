import logging
import random
from django.core.mail import send_mail
from django.http import JsonResponse
from django.contrib.auth import get_user_model, authenticate, login, logout
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone

from .models import CustomUser

logger = logging.getLogger(__name__)

# Generate OTP
def generate_otp():
    return str(random.randint(100000, 999999))

# Send OTP to user's email
def send_otp(email):
    otp = generate_otp()
    try:
        user = CustomUser.objects.get(email=email)
        user.set_otp(otp)  # Use the new method
        
        # Send OTP via email
        send_mail(
            'Your OTP Code',
            f'Your OTP code is: {otp}',
            'malanog.aubrey@example.com',  # Replace with actual sender email
            [email],
            fail_silently=False,
        )
        return JsonResponse({"message": "OTP sent!"})
    except CustomUser.DoesNotExist:
        return JsonResponse({"message": "User not found!"}, status=404)

# Verify OTP entered by the user
@csrf_exempt
def verify_otp(request, email, otp):
    try:
        user = CustomUser.objects.get(email=email)

        # Ensure otp_expiry is timezone-aware
        if user.otp_expiry is not None and user.otp_expiry.tzinfo is None:
            user.otp_expiry = timezone.make_aware(user.otp_expiry, timezone.get_current_timezone())

        # Compare otp_expiry with the current time, ensuring both are timezone-aware
        if user.is_otp_valid() and user.otp == otp:
            # If OTP is valid, check if it is expired or not
            if user.otp_expiry > timezone.now():
                # OTP is valid and not expired
                user.otp = None  # Clear OTP after successful verification
                user.otp_expiry = None  # Clear OTP expiry time
                user.save()
                return JsonResponse({"message": "OTP verified!"})
            else:
                return JsonResponse({"message": "OTP expired!"}, status=400)
        else:
            return JsonResponse({"message": "Invalid OTP!"}, status=400)

    except CustomUser.DoesNotExist:
        return JsonResponse({"message": "User not found!"}, status=404)
    
# Sign Up API
@csrf_exempt
@api_view(['POST'])
def sign_up(request):
    if request.method == 'POST':
        email = request.data.get('email')  # Get email from the request
        password = request.data.get('password')

        # Validate email and password
        if not email or not password:
            return Response({"error": "Email and password are required"}, status=status.HTTP_400_BAD_REQUEST)

        if len(password) < 6:
            return Response({"error": "Password must be at least 6 characters"}, status=status.HTTP_400_BAD_REQUEST)

        # Check if email already exists
        if CustomUser.objects.filter(email=email).exists():
            return Response({"error": "Email already exists!"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Create user with email and password
            user = CustomUser.objects.create_user(email=email, password=password)
            user.save()

            # Send OTP after user is created
            send_otp(email)
            return Response({"message": "User created successfully! OTP sent."}, status=status.HTTP_201_CREATED)
        except Exception as e:
            logger.error(f"Error creating user: {e}")
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Login API
@csrf_exempt
@api_view(['POST'])
def login_user(request):
    if request.method == 'POST':
        email = request.data.get('email')
        password = request.data.get('password')

        if not email or not password:
            return Response({"error": "Email and password are required"}, status=status.HTTP_400_BAD_REQUEST)

        # Use email as username for authentication
        user = authenticate(request, username=email, password=password)
        if user is not None:
            login(request, user)
            return Response({"message": "Login successful!"}, status=status.HTTP_200_OK)
        else:
            return Response({"message": "Invalid credentials!"}, status=status.HTTP_401_UNAUTHORIZED)

# Forgot Password API
@csrf_exempt
@api_view(['POST'])
def forgot_password(request):
    email = request.data.get('email')

    if not email:
        return Response({"error": "Email is required!"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = CustomUser.objects.get(email=email)
        user.set_otp(generate_otp())  # Set OTP and expiry
        user.save()

        # Send OTP via email
        send_mail(
            'Your Password Reset OTP',
            f'Your OTP for password reset is: {user.otp}',
            'malanog.aubrey@gmail.com',  # Replace with your email
            [email],
            fail_silently=False,
        )

        return JsonResponse({"message": "OTP sent to email!"})

    except CustomUser.DoesNotExist:
        return JsonResponse({"error": "User not found!"}, status=404)
