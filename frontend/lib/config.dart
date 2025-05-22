import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost
  
  // Authentication endpoints
  static const String signUpUrl = '$baseUrl/auth/sign_up/';
  static const String loginUrl = '$baseUrl/auth/login_user/';
  static const String verifyOtpUrl = '$baseUrl/auth/verify-otp/';
  static const String forgotPasswordUrl = '$baseUrl/auth/forgot-password/';
  static const String sendOtpUrl = '$baseUrl/auth/send-otp/';
  
  // Food entry endpoints
  static String get foodSearchUrl => '$baseUrl/auth/foods/search/';
  static String get foodDetailsUrl => '$baseUrl/auth/foods/details/';
  static String get foodEntriesUrl => '$baseUrl/auth/food-entries/';
  static String get createFoodEntryUrl => '$baseUrl/auth/food-entries/create/';
  static String get updateFoodEntryUrl => '$baseUrl/auth/food-entries/';
  static String get deleteFoodEntryUrl => '$baseUrl/auth/food-entries/';
} 