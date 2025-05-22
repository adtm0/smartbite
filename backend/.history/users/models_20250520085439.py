from django.db import models
from django.contrib.auth.models import AbstractUser
from django.contrib.auth.models import BaseUserManager
from django.utils import timezone
import datetime

class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        """
        Create and return a user with an email and password.
        """
        if not email:
            raise ValueError("The Email must be set")
        
        email = self.normalize_email(email)  # Normalize the email address
        
        # Create the user instance
        user = self.model(email=email, **extra_fields)
        user.set_password(password)  # Set the password properly
        user.save(using=self._db)  # Save the user to the database
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """
        Create and return a superuser with an email and password.
        """
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)
    
class CustomUser(AbstractUser):
    # Optional field for phone number
    phone_number = models.CharField(max_length=15, blank=True, null=True, unique=True)
    
    # OTP
    otp = models.CharField(max_length=6, blank=True, null=True)
    otp_expiry = models.DateTimeField(blank=True, null=True)

    # Make email the unique field
    email = models.EmailField(unique=True)

    objects = CustomUserManager()

    # Use email as the unique identifier for login
    USERNAME_FIELD = 'email'  # Email as the unique identifier
    REQUIRED_FIELDS = []  # Email is the only required field for user creation

    def set_otp(self, otp):
        self.otp = otp
        self.otp_expiry = timezone.now() + datetime.timedelta(minutes=10)  # OTP expiry time
        self.save()
        
    def is_otp_valid(self):
        # Ensure both times are timezone-aware
        if self.otp_expiry and self.otp_expiry > timezone.now():
            return True
        return False
  
    def __str__(self):
        return self.email

    def save(self, *args, **kwargs):
        # Ensure that the username is not empty and is set to email
        if not self.username:  # If username is empty or None
            self.username = self.email  # Set username to email address
        super().save(*args, **kwargs)  # Call the original save method
