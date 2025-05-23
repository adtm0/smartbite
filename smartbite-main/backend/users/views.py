import logging
import random
from django.core.mail import send_mail
from django.http import JsonResponse
from django.contrib.auth import get_user_model, authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from datetime import datetime
from django.shortcuts import get_object_or_404
import requests
import os
from django.conf import settings

from .models import CustomUser, FoodEntry, FoodItem
from rest_framework.permissions import IsAuthenticated
from rest_framework.authtoken.models import Token

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
        try:
            email = request.data.get('email')
            password = request.data.get('password')

            if not email or not password:
                return Response(
                    {"error": "Email and password are required"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # First check if user exists
            try:
                user = CustomUser.objects.get(email=email)
            except CustomUser.DoesNotExist:
                return Response(
                    {"error": "No user found with this email"},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            # Then try to authenticate
            user = authenticate(request, username=email, password=password)
            if user is not None:
                login(request, user)
                # Get or create token
                token, created = Token.objects.get_or_create(user=user)
                return Response({
                    "message": "Login successful!",
                    "token": token.key
                }, status=status.HTTP_200_OK)
            else:
                return Response(
                    {"error": "Invalid password"},
                    status=status.HTTP_401_UNAUTHORIZED
                )
        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            return Response(
                {"error": f"Server error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

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

# Food Entry
@api_view(['POST'])
@login_required  # Ensure that the user is authenticated before logging a food entry
def log_food_entry(request):
    """
    API view to log a new food entry for the authenticated user.
    """
    if request.method == 'POST':
        # Get the food entry data from the request
        food_name = request.data.get('food_name')
        description = request.data.get('description')
        calories = request.data.get('calories')

        if not food_name or not calories:
            return Response({"error": "Food name and calories are required."}, status=status.HTTP_400_BAD_REQUEST)

        # Create a new food entry for the logged-in user
        food_entry = FoodEntry.objects.create(
            user=request.user,  # The logged-in user
            food_name=food_name,
            description=description,
            calories=calories
        )

        return Response({"message": "Food entry logged successfully!"}, status=status.HTTP_201_CREATED)

# USDA API configuration
USDA_API_KEY = os.getenv('USDA_API_KEY')  # Get API key from environment variable
USDA_API_BASE_URL = 'https://api.nal.usda.gov/fdc/v1'

# Log API key status
if not USDA_API_KEY:
    logging.error("No USDA API key found - please set the USDA_API_KEY environment variable")
else:
    logging.info("Using USDA API key for food search")

def get_food_details(fdc_id):
    """Fetch food details from USDA API"""
    url = f"{USDA_API_BASE_URL}/food/{str(fdc_id)}"  # Ensure fdc_id is a string
    params = {'api_key': USDA_API_KEY}
    
    logging.info(f"Fetching food details for FDC ID: {fdc_id}")
    logging.info(f"Using API key: {USDA_API_KEY[:5]}...")  # Only log first 5 chars for security
    
    try:
        response = requests.get(url, params=params)
        logging.info(f"USDA API Response Status: {response.status_code}")
        logging.info(f"USDA API Response: {response.text[:200]}...")  # Log first 200 chars of response
        
        response.raise_for_status()
        data = response.json()
        
        nutrients = {
            'calories': 0,
            'protein': 0,
            'fat': 0,
            'carbs': 0
        }
        
        # Extract nutrients from the response
        for nutrient in data.get('foodNutrients', []):
            if nutrient.get('nutrient', {}).get('name') == 'Energy':
                nutrients['calories'] = nutrient.get('amount', 0)
            elif nutrient.get('nutrient', {}).get('name') == 'Protein':
                nutrients['protein'] = nutrient.get('amount', 0)
            elif nutrient.get('nutrient', {}).get('name') == 'Total lipid (fat)':
                nutrients['fat'] = nutrient.get('amount', 0)
            elif nutrient.get('nutrient', {}).get('name') == 'Carbohydrate, by difference':
                nutrients['carbs'] = nutrient.get('amount', 0)
        
        logging.info(f"Extracted nutrients: {nutrients}")
        
        return {
            'name': data.get('description', ''),
            'nutrients': nutrients,
            'fdc_id': fdc_id
        }
    except requests.exceptions.RequestException as e:
        logging.error(f"Error fetching food details: {e}")
        logging.error(f"Request URL: {url}")
        logging.error(f"Request params: {params}")
        if hasattr(e, 'response') and e.response is not None:
            logging.error(f"Response status: {e.response.status_code}")
            logging.error(f"Response text: {e.response.text}")
        return None

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_foods(request):
    """Search foods using USDA API"""
    query = request.query_params.get('query', '')
    
    if not query:
        return Response({'error': 'Query parameter is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not USDA_API_KEY:
        return Response(
            {'error': 'USDA API key not configured. Please set the USDA_API_KEY environment variable.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    url = f"{USDA_API_BASE_URL}/foods/search"
    
    data_types = ['Foundation', 'Survey', 'SR Legacy']
    params = {
        'api_key': USDA_API_KEY,
        'query': query,
        'dataType': data_types,
        'pageSize': 50,
        'sortBy': 'dataType.keyword',
        'sortOrder': 'asc',
        'requireAllWords': False
    }
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json()
        if not data.get('foods'):
            logging.warning(f"No foods found for query: {query}")
            logging.warning(f"API Response: {data}")
            return Response([])
        foods = []
        for food in data.get('foods', []):
            food_data = {
                'fdc_id': str(food.get('fdcId')),
                'name': food.get('description'),
                'brand': food.get('brandOwner', ''),
                'data_type': food.get('dataType', ''),
                'data_type_description': food.get('dataType', ''),
                'serving_size': food.get('servingSize', 100),
                'serving_size_unit': food.get('servingSizeUnit', 'g')
            }
            foods.append(food_data)
        foods.sort(key=lambda x: (
            x['data_type'] != 'Foundation',
            x['data_type'] != 'Survey',
            (x['name'] or '').lower()
        ))
        logging.info(f"Found {len(foods)} foods for query: {query}")
        return Response(foods)
    except requests.exceptions.RequestException as e:
        logging.error(f"USDA API request failed: {str(e)}")
        logging.error(f"Request URL: {url}")
        logging.error(f"Request params: {params}")
        if hasattr(e.response, 'text'):
            logging.error(f"API Error Response: {e.response.text}")
        return Response(
            {'error': f'Error searching foods: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        logging.error(f"Unexpected error in search_foods: {str(e)}")
        return Response(
            {'error': 'An unexpected error occurred while searching foods'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_food_entry(request):
    """Create a new food entry using USDA food data"""
    try:
        data = request.data
        fdc_id = data.get('fdc_id')
        food_name = data.get('food_name')
        meal_type = data.get('meal_type', 'Lunch')
        number_of_servings = float(data.get('number_of_servings', 1.0))
        serving_size = float(data.get('serving_size', 100.0))
        serving_size_unit = data.get('serving_size_unit', 'g')
        entry_date = datetime.strptime(
            data.get('entry_date', timezone.now().date().isoformat()),
            '%Y-%m-%d'
        ).date()

        # Get food details from USDA API
        food_details = get_food_details(fdc_id)
        if not food_details:
            return Response(
                {'error': 'Could not fetch food details'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Create food entry
        food_entry = FoodEntry.objects.create(
            user=request.user,
            food_name=food_name or food_details['name'],
            fdc_id=fdc_id,
            meal_type=meal_type,
            number_of_servings=number_of_servings,
            serving_size=serving_size,
            serving_size_unit=serving_size_unit,
            calories=food_details['nutrients']['calories'],
            protein=food_details['nutrients']['protein'],
            fat=food_details['nutrients']['fat'],
            carbs=food_details['nutrients']['carbs'],
            entry_date=entry_date
        )
        
        # Calculate total nutrients based on serving size
        total_nutrients = food_entry.get_total_nutrients()
        
        return Response({
            'id': food_entry.id,
            'food_name': food_entry.food_name,
            'meal_type': food_entry.meal_type,
            'number_of_servings': food_entry.number_of_servings,
            'serving_size': food_entry.serving_size,
            'serving_size_unit': food_entry.serving_size_unit,
            'calories': total_nutrients['calories'],
            'protein': total_nutrients['protein'],
            'fat': total_nutrients['fat'],
            'carbs': total_nutrients['carbs'],
            'entry_date': food_entry.entry_date.isoformat(),
            'message': 'Food entry created successfully!'
        }, status=status.HTTP_201_CREATED)
    except ValueError as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logging.error(f"Error creating food entry: {e}")
        return Response(
            {'error': 'An error occurred while creating the food entry'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_food_entries(request):
    """Get food entries for the authenticated user with optional date filtering."""
    try:
        date_str = request.query_params.get('date')
        if date_str:
            date = datetime.strptime(date_str, '%Y-%m-%d').date()
            entries = FoodEntry.objects.filter(user=request.user, entry_date=date)
        else:
            entries = FoodEntry.objects.filter(user=request.user)

        entries_data = [{
            'id': entry.id,
            'food_name': entry.food_name,
            'meal_type': entry.meal_type,
            'number_of_servings': entry.number_of_servings,
            'serving_size': entry.serving_size,
            'serving_size_unit': entry.serving_size_unit,
            'entry_date': entry.entry_date.isoformat(),
            'calories': entry.calories,
            'protein': entry.protein,
            'fat': entry.fat,
            'carbs': entry.carbs
        } for entry in entries]

        return Response(entries_data)
    except ValueError as e:
        return Response({
            'error': f'Invalid date format: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_food_entry(request, entry_id):
    """Update an existing food entry."""
    try:
        food_entry = get_object_or_404(FoodEntry, id=entry_id, user=request.user)
        data = request.data

        # Update food_name if changed
        if 'food_name' in data and data['food_name'] != food_entry.food_name:
            food_entry.food_name = data['food_name']

        # Update other fields
        if 'meal_type' in data:
            food_entry.meal_type = data['meal_type']
        if 'number_of_servings' in data:
            food_entry.number_of_servings = float(data['number_of_servings'])
        if 'serving_size' in data:
            food_entry.serving_size = float(data['serving_size'])
        if 'serving_size_unit' in data:
            food_entry.serving_size_unit = data['serving_size_unit']
        if 'entry_date' in data:
            food_entry.entry_date = datetime.strptime(data['entry_date'], '%Y-%m-%d').date()

        food_entry.save()

        return Response({
            'id': food_entry.id,
            'food_name': food_entry.food_name,
            'meal_type': food_entry.meal_type,
            'number_of_servings': food_entry.number_of_servings,
            'serving_size': food_entry.serving_size,
            'serving_size_unit': food_entry.serving_size_unit,
            'entry_date': food_entry.entry_date.isoformat(),
            'calories': food_entry.calories,
            'protein': food_entry.protein,
            'fat': food_entry.fat,
            'carbs': food_entry.carbs,
            'message': 'Food entry updated successfully!'
        })
    except FoodEntry.DoesNotExist:
        return Response({
            'error': 'Food entry not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except (ValueError, KeyError) as e:
        return Response({
            'error': f'Invalid data provided: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_food_entry(request, entry_id):
    """Delete a food entry."""
    try:
        food_entry = FoodEntry.objects.get(id=entry_id, user=request.user)
        food_entry.delete()
        return Response({
            'message': 'Food entry deleted successfully!'
        })
    except FoodEntry.DoesNotExist:
        return Response({
            'error': 'Food entry not found'
        }, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_food_items(request):
    """Search for food items by name."""
    query = request.query_params.get('q', '')
    food_items = FoodItem.objects.filter(name__icontains=query)
    
    items_data = [{
        'name': item.name,
        'calories_per_100g': item.calories_per_100g,
        'carbs_per_100g': item.carbs_per_100g,
        'fat_per_100g': item.fat_per_100g,
        'protein_per_100g': item.protein_per_100g
    } for item in food_items]
    
    return Response(items_data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_food_details_api(request, fdc_id):
    """API endpoint to get food details from USDA API"""
    try:
        food_details = get_food_details(fdc_id)
        if not food_details:
            return Response(
                {'error': 'Could not fetch food details'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        return Response(food_details)
    except requests.exceptions.RequestException as e:
        return Response(
            {'error': f'Error fetching food details: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        return Response(
            {'error': f'Unexpected error: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_foods_openfoodfacts(request):
    query = request.query_params.get('query', '')
    url = 'https://world.openfoodfacts.org/cgi/search.pl'
    params = {
        'search_terms': query,
        'search_simple': 1,
        'action': 'process',
        'json': 1,
        'page_size': 20
    }
    response = requests.get(url, params=params)
    data = response.json()
    foods = []
    for product in data.get('products', []):
        nutrients = product.get('nutriments', {})
        foods.append({
            'name': product.get('product_name', ''),
            'brand': product.get('brands', ''),
            'calories': nutrients.get('energy-kcal_100g') or nutrients.get('energy_100g'),
            'carbs': nutrients.get('carbohydrates_100g'),
            'fat': nutrients.get('fat_100g'),
            'protein': nutrients.get('proteins_100g'),
            'image': product.get('image_front_url', ''),
        })
    return Response(foods)

@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    user = request.user
    if request.method == 'GET':
        return Response({
            'username': user.username,
            'email': user.email,
            'height': getattr(user, 'height', ''),
            'sex': getattr(user, 'sex', ''),
            'dob': getattr(user, 'dob', ''),
        })
    elif request.method == 'PUT':
        data = request.data
        user.username = data.get('username', user.username)
        user.height = data.get('height', getattr(user, 'height', ''))
        user.sex = data.get('sex', getattr(user, 'sex', ''))
        user.dob = data.get('dob', getattr(user, 'dob', ''))
        user.save()
        return Response({
            'username': user.username,
            'email': user.email,
            'height': getattr(user, 'height', ''),
            'sex': getattr(user, 'sex', ''),
            'dob': getattr(user, 'dob', ''),
        })