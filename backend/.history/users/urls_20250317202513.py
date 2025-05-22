from django.urls import path
from . import views

urlpatterns = [
    path('send-otp/', views.send_otp, name='send_otp'),
    path('verify-otp/<str:email>/<str:otp>/', views.verify_otp, name='verify_otp'),
    path('login_user/', views.login_user, name='login_user'),
]
