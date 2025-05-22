// lib/search_food_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/food_service.dart';
import 'models/food_entry.dart';

class SearchFoodScreen extends StatefulWidget {
  final String initialQuery;
  final String? preselectedMealType;
  
  const SearchFoodScreen({
    super.key,
    this.initialQuery = '',
    this.preselectedMealType,
  });

  @override
  State<SearchFoodScreen> createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends State<SearchFoodScreen> {
  late String _selectedMeal;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.preselectedMealType ?? 'Lunch';
    _searchController.addListener(_onSearchChanged);
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _onSearchChanged();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await FoodService.searchFoods(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching foods: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching foods: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Search Foods',
          style: TextStyle(color: theme.appBarTheme.foregroundColor),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search for a food...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No results found',
                style: TextStyle(color: textColor),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  ..._searchResults.map((food) => Card(
                        color: cardColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          title: Text(
                            food['name']!,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${food['data_type']} - ${food['serving_size']} ${food['serving_size_unit']}',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                          onTap: () async {
                            try {
                              final foodDetails = await FoodService.getFoodDetails(food['fdc_id']);
                              if (mounted) {
                                final newFoodEntry = FoodEntry(
                                  name: foodDetails['name'],
                                  mealType: widget.preselectedMealType ?? 'Lunch',
                                  calories: foodDetails['nutrients']['calories'].toDouble(),
                                  carbs: foodDetails['nutrients']['carbs'].toDouble(),
                                  fat: foodDetails['nutrients']['fat'].toDouble(),
                                  protein: foodDetails['nutrients']['protein'].toDouble(),
                                  numberOfServings: 1.0,
                                  servingSizeUnit: 'g',
                                  entryDate: DateTime.now(),
                                  fdcId: foodDetails['fdc_id'].toString(),
                                );
                                Navigator.pop(context, {
                                  'food_name': foodDetails['name'],
                                  'meal_type': widget.preselectedMealType,
                                  'calories': foodDetails['nutrients']['calories'],
                                  'carbs': foodDetails['nutrients']['carbs'],
                                  'fat': foodDetails['nutrients']['fat'],
                                  'protein': foodDetails['nutrients']['protein'],
                                  'serving_size': food['serving_size'],
                                  'serving_size_unit': food['serving_size_unit'],
                                  'fdc_id': food['fdc_id'].toString(),
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error getting food details: $e')),
                                );
                              }
                            }
                          },
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 