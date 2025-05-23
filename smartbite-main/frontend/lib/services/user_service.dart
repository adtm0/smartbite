import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class UserService {
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/auth/user/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> user) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/auth/user/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(user),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String reNewPassword,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/users/set_password/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
        're_new_password': reNewPassword,
      }),
    );
    if (response.statusCode != 204) {
      try {
        final error = json.decode(response.body);
        if (error is Map && error.isNotEmpty) {
          throw Exception(error.values.first is List ? error.values.first.join(' ') : error.values.first.toString());
        } else {
          throw Exception('Failed to change password');
        }
      } catch (e) {
        throw Exception(response.body);
      }
    }
  }

  static Future<void> deleteAccount({
    required String currentPassword,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/auth/users/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({
        'current_password': currentPassword,
      }),
    );
    if (response.statusCode != 204) {
      try {
        final error = json.decode(response.body);
        if (error is Map && error.isNotEmpty) {
          throw Exception(error.values.first is List ? error.values.first.join(' ') : error.values.first.toString());
        } else {
          throw Exception('Failed to delete account');
        }
      } catch (e) {
        throw Exception(response.body);
      }
    }
  }
} 