import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_entry.dart';

class FoodService {
  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Search foods using the USDA database through our backend
  static Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${Config.foodSearchUrl}?query=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching foods: $e');
    }
  }

  // Get food details from the USDA database
  static Future<Map<String, dynamic>> getFoodDetails(String fdcId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${Config.foodDetailsUrl}$fdcId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get food details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting food details: $e');
    }
  }

  // Get food entries for a specific date
  static Future<List<FoodEntry>> getFoodEntries(DateTime date) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      final dateStr = date.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
      final response = await http.get(
        Uri.parse('${Config.foodEntriesUrl}?date=$dateStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((entry) => FoodEntry.fromMap(entry)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Failed to get food entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting food entries: $e');
    }
  }

  // Create a new food entry
  static Future<FoodEntry> createFoodEntry(FoodEntry entry, String fdcId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${Config.createFoodEntryUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'fdc_id': fdcId,
          'food_name': entry.name,
          'meal_type': entry.mealType,
          'number_of_servings': entry.numberOfServings,
          'serving_size': entry.servingSize ?? 100.0,
          'serving_size_unit': entry.servingSizeUnit,
          'entry_date': entry.entryDate.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return FoodEntry.fromMap(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to create food entry: ${errorData['error'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating food entry: $e');
    }
  }

  // Update an existing food entry
  static Future<FoodEntry> updateFoodEntry(FoodEntry entry) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = '${Config.updateFoodEntryUrl}${entry.id}/update/';
      print('Updating food entry at URL: $url'); // Debug print
      print('Request body: ${json.encode(entry.toMap())}'); // Debug print

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(entry.toMap()),
      );

      print('Response status: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FoodEntry.fromMap(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to update food entry: ${errorData['error'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Error updating food entry: $e'); // Debug print
      throw Exception('Error updating food entry: $e');
    }
  }

  // Delete a food entry
  static Future<void> deleteFoodEntry(int entryId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${Config.deleteFoodEntryUrl}$entryId/delete/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      // Debug print for troubleshooting
      print('Delete response: \\${response.statusCode} - \\${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete food entry: \\${response.statusCode}');
      }
      // No error thrown for 200/204
    } catch (e) {
      throw Exception('Error deleting food entry: $e');
    }
  }

  // Search foods using Open Food Facts through our backend
  static Future<List<Map<String, dynamic>>> searchFoodsOpenFoodFacts(String query) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/auth/foods/search_openfoodfacts/?query=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to search foods (Open Food Facts): \\${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching foods (Open Food Facts): $e');
    }
  }
} 