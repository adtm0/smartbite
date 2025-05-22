from django.db import models
from django.conf import settings
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
        
class FoodItem(models.Model):
    name = models.CharField(max_length=255, unique=True)
    calories_per_100g = models.FloatField()
    carbs_per_100g = models.FloatField(default=0)
    fat_per_100g = models.FloatField(default=0)
    protein_per_100g = models.FloatField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    def get_nutrients_for_serving(self, serving_size, serving_unit='g'):
        # Convert serving size to grams
        grams = self.convert_to_grams(serving_size, serving_unit)
        
        # Calculate nutrients based on the converted amount
        multiplier = grams / 100.0
        return {
            'calories': self.calories_per_100g * multiplier,
            'carbs': self.carbs_per_100g * multiplier,
            'fat': self.fat_per_100g * multiplier,
            'protein': self.protein_per_100g * multiplier
        }

    def convert_to_grams(self, amount, unit):
        # Common conversion factors
        conversion_factors = {
            'g': 1,
            'kg': 1000,
            'oz': 28.3495,
            'lb': 453.592,
            'cup': 128,  # Approximate, varies by food
            'tbsp': 15,  # Approximate, varies by food
            'tsp': 5,    # Approximate, varies by food
        }
        
        return amount * conversion_factors.get(unit.lower(), 1)

class FoodEntry(models.Model):
    MEAL_TYPE_CHOICES = [
        ('Breakfast', 'Breakfast'),
        ('Lunch', 'Lunch'),
        ('Dinner', 'Dinner'),
        ('Snack', 'Snack'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='food_entries')
    food_name = models.CharField(max_length=255, default='Unknown Food')
    fdc_id = models.CharField(max_length=50, null=True, blank=True)  # USDA FoodData Central ID
    meal_type = models.CharField(max_length=20, choices=MEAL_TYPE_CHOICES, default='Lunch')
    number_of_servings = models.FloatField(default=1.0)
    serving_size = models.FloatField(default=100.0)  # Amount in grams
    serving_size_unit = models.CharField(max_length=20, default='g')
    calories = models.FloatField(default=0)  # Stored as per 100g
    protein = models.FloatField(default=0)   # Stored as per 100g
    fat = models.FloatField(default=0)       # Stored as per 100g
    carbs = models.FloatField(default=0)     # Stored as per 100g
    entry_date = models.DateField(default=timezone.now)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-entry_date', '-created_at']

    def __str__(self):
        return f"{self.food_name} - {self.meal_type} ({self.entry_date})"

    def convert_to_grams(self, amount, unit):
        """Convert various units to grams"""
        conversion_factors = {
            'g': 1,
            'kg': 1000,
            'oz': 28.3495,
            'lb': 453.592,
            'cup': 128,  # Approximate, varies by food
            'tbsp': 15,  # Approximate, varies by food
            'tsp': 5,    # Approximate, varies by food
            'serving': 100,  # Default serving size
            'medium': 100,   # Default medium size
            'large': 150,    # Default large size
            'small': 50,     # Default small size
            'item': 100,     # Default item size
            'egg': 50,       # Average egg size
            'unit': 100,     # Default unit size
        }
        return amount * conversion_factors.get(unit.lower(), 100)  # Default to 100g if unit unknown

    def get_total_nutrients(self):
        """Calculate total nutrients based on serving size and unit conversion"""
        # Convert the serving size to grams
        total_grams = self.convert_to_grams(self.serving_size, self.serving_size_unit)
        
        # Calculate the multiplier based on number of servings and converted grams
        multiplier = (total_grams / 100.0) * self.number_of_servings
        
        return {
            'calories': self.calories * multiplier,
            'protein': self.protein * multiplier,
            'fat': self.fat * multiplier,
            'carbs': self.carbs * multiplier
        }