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
  List<FoodEntry> _historyEntries = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.preselectedMealType ?? 'Lunch';
    _searchController.addListener(_onSearchChanged);
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _onSearchChanged();
    } else {
      _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    try {
      // Fetch all entries, sort by date, and take the most recent 10
      final now = DateTime.now();
      final entries = await FoodService.getFoodEntries(now.subtract(const Duration(days: 30)));
      entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      setState(() {
        _historyEntries = entries.take(10).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyEntries = [];
        _isLoadingHistory = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
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
      _fetchHistory();
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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Custom Top Bar
              Padding(
                padding: const EdgeInsets.only(top: 40, left: 8, right: 8, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: DropdownButton<String>(
                          value: _selectedMeal,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          underline: const SizedBox(),
                          dropdownColor: Colors.white,
                          items: <String>['Breakfast', 'Lunch', 'Dinner', 'Snack']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMeal = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // To balance the back arrow
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 22, right: 22, bottom: 0),
                child: SizedBox(
                  width: 368,
                  height: 56,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Search for a food...',
                      hintStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 18),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: const Color(0xFFD9D9D9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.90,
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: _searchController.text.isEmpty
                          ? _isLoadingHistory
                              ? const Center(child: CircularProgressIndicator())
                              : SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 0.0, top: 8.0, bottom: 12.0),
                                        child: Text(
                                          'History',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                            height: 22 / 20,
                                            letterSpacing: 0,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                      if (_historyEntries.isEmpty)
                                        const Text('No history yet', style: TextStyle(color: Colors.white70)),
                                      ..._historyEntries.map((entry) => GestureDetector(
                                            onTap: () async {
                                              try {
                                                final newEntry = entry.copyWith(
                                                  entryDate: DateTime.now(),
                                                  mealType: _selectedMeal,
                                                );
                                                final createdEntry = await FoodService.createFoodEntry(newEntry, entry.fdcId ?? '');
                                                if (mounted) {
                                                  Navigator.pop(context, createdEntry);
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error adding food: $e')),
                                                  );
                                                }
                                              }
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(bottom: 10),
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[900],
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white24, width: 1),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(entry.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                  Text(
                                                    '${entry.calories.toStringAsFixed(0)} cal, ${entry.servingSize?.toStringAsFixed(0) ?? ''} ${entry.servingSizeUnit}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Russo One',
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 14,
                                                      height: 22 / 14,
                                                      letterSpacing: 0,
                                                      color: Colors.white70,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Text(
                                                    'Food',
                                                    style: const TextStyle(
                                                      fontFamily: 'Russo One',
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 14,
                                                      height: 22 / 14,
                                                      letterSpacing: 0,
                                                      color: Colors.white70,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )),
                                    ],
                                  ),
                                )
                          : _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _searchResults.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No results found',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ListView(
                                            children: _searchResults.map((food) => GestureDetector(
                                              onTap: () async {
                                                try {
                                                  print('Fetching food details for FDC ID: ${food['fdc_id']}');
                                                  final foodDetails = await FoodService.getFoodDetails(food['fdc_id']);
                                                  print('Received food details: $foodDetails');
                                                  if (mounted) {
                                                    final newFoodEntry = FoodEntry(
                                                      name: foodDetails['name'],
                                                      mealType: _selectedMeal,
                                                      calories: foodDetails['nutrients']['calories'].toDouble(),
                                                      carbs: foodDetails['nutrients']['carbs'].toDouble(),
                                                      fat: foodDetails['nutrients']['fat'].toDouble(),
                                                      protein: foodDetails['nutrients']['protein'].toDouble(),
                                                      numberOfServings: 1.0,
                                                      servingSizeUnit: 'g',
                                                      entryDate: DateTime.now(),
                                                      fdcId: foodDetails['fdc_id'].toString(),
                                                    );
                                                    print('Creating food entry with data: ${newFoodEntry.toMap()}');
                                                    final createdEntry = await FoodService.createFoodEntry(newFoodEntry, foodDetails['fdc_id'].toString());
                                                    print('Successfully created food entry: ${createdEntry.toMap()}');
                                                    Navigator.pop(context, createdEntry);
                                                  }
                                                } catch (e) {
                                                  print('Error adding food: $e');
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error adding food: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 10),
                                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[900],
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.white24, width: 1),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(food['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                    Text('${food['data_type'] ?? ''} - ${food['serving_size'] ?? ''} ${food['serving_size_unit'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                                  ],
                                                ),
                                              ),
                                            )).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 