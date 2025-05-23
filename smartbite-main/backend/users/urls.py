from django.urls import path, include
from . import views

urlpatterns = [
    # Authentication URLs
    path('sign_up/', views.sign_up, name='sign_up'),
    path('send-otp/', views.send_otp, name='send_otp'),
    path('verify-otp/<str:email>/<str:otp>/', views.verify_otp, name='verify_otp'),
    path('login_user/', views.login_user, name='login_user'),
    
    # Food Entry API endpoints
    path('food-entries/', views.get_food_entries, name='get-food-entries'),
    path('food-entries/create/', views.create_food_entry, name='create-food-entry'),
    path('food-entries/<int:entry_id>/update/', views.update_food_entry, name='update-food-entry'),
    path('food-entries/<int:entry_id>/delete/', views.delete_food_entry, name='delete-food-entry'),
    
    # USDA Food Search
    path('foods/search/', views.search_foods, name='search-foods'),
    path('foods/details/<str:fdc_id>/', views.get_food_details_api, name='food-details'),
    path('foods/search_openfoodfacts/', views.search_foods_openfoodfacts, name='search-foods-openfoodfacts'),
    path('user/', views.user_profile, name='user-profile'),
    path('', include('djoser.urls')),
    path('', include('djoser.urls.authtoken')),  # Only if you use token auth
]
