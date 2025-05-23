// lib/diary_screen.dart
import 'package:flutter/material.dart';
import 'edit_entry_screen.dart';
import 'models/food_entry.dart';
import 'search_food_screen.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:percent_indicator/circular_percent_indicator.dart'; // For calorie circle
import 'package:shared_preferences/shared_preferences.dart';
import 'services/food_service.dart';
import 'scan_screen.dart';

class DiaryScreen extends StatefulWidget {
  final void Function()? onToggleTheme;

  const DiaryScreen({super.key, this.onToggleTheme});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

const int baseGoal = 1800; // Shared calorie goal for both Diary and Dashboard

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _selectedMeal = 'Lunch';

  // Initialize empty diary entries, grouped by meal type
  final Map<String, List<FoodEntry>> _diaryEntriesByMeal = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
    'Snack': [],
  };

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _loadFoodEntries();
  }

  Future<void> _loadFoodEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await FoodService.getFoodEntries(_selectedDate);
      
      // Reset all meal type lists
      for (var mealType in _mealTypes) {
        _diaryEntriesByMeal[mealType] = [];
      }
      
      // Group entries by meal type
      for (var entry in entries) {
        _diaryEntriesByMeal[entry.mealType]?.add(entry);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading food entries: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Clear the auth token
    if (!mounted) return;
    
    // Navigate to login screen and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _addFoodEntry(FoodEntry newEntry) async {
    try {
      if (newEntry.fdcId == null) {
        throw Exception('Food ID is required');
      }
      
      // Create the entry in the backend
      final createdEntry = await FoodService.createFoodEntry(newEntry, newEntry.fdcId!);
      
      setState(() {
        _diaryEntriesByMeal[createdEntry.mealType]?.add(createdEntry);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${createdEntry.name} added to ${createdEntry.mealType}!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding food entry: $e')),
      );
    }
  }

  Future<void> _updateFoodEntry(FoodEntry originalEntry, FoodEntry updatedEntry) async {
    try {
      // Update the entry in the backend
      final savedEntry = await FoodService.updateFoodEntry(updatedEntry);
      
      setState(() {
        // Remove from original meal type
        _diaryEntriesByMeal[originalEntry.mealType]?.removeWhere((entry) => entry.id == originalEntry.id);
        // Add to new meal type (if meal type changed)
        _diaryEntriesByMeal[savedEntry.mealType]?.add(savedEntry);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating food entry: $e')),
      );
    }
  }

  Future<void> _deleteFoodEntry(FoodEntry entry) async {
    try {
      await FoodService.deleteFoodEntry(entry.id!);
      setState(() {
        _diaryEntriesByMeal[entry.mealType]?.removeWhere((e) => e.id == entry.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.name} removed from diary')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting food entry: $e')),
      );
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadFoodEntries(); // Load entries for the new date
  }

  // Helper to calculate total calories for the current day
  double _calculateTotalCaloriesConsumed() {
    double total = 0;
    _diaryEntriesByMeal.values.forEach((mealEntries) {
      mealEntries.forEach((entry) {
        total += entry.getTotalCalories();
      });
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;
    final screenWidth = MediaQuery.of(context).size.width;

    final double caloriesConsumed = _calculateTotalCaloriesConsumed();
    final int caloriesRemaining =
        (baseGoal - caloriesConsumed).clamp(0, baseGoal).toInt();
    final double calorieProgress =
        baseGoal == 0 ? 0.0 : caloriesConsumed / baseGoal;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button from working
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back arrow
          title: const Text(
            'Diary',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 22/32,
              letterSpacing: 0,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.black),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Date Navigation and Calorie Summary Header ---
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                            onPressed: () => _changeDate(-1),
                          ),
                          Text(
                            _selectedDate.isAtSameMomentAs(DateTime.now())
                                ? 'Today'
                                : DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
                            onPressed: () => _changeDate(1),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Calories Remaining',
                                style: TextStyle(
                                  fontFamily: 'NATS',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 20,
                                  height: 22/20,
                                  letterSpacing: 0,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  children: [
                                    Text('1800',
                                        style: TextStyle(
                                          fontFamily: 'NATS',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 20,
                                          height: 22/20,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center),
                                    Text('Goal',
                                        style: TextStyle(
                                          fontFamily: 'NATS',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                          height: 22/15,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                                SizedBox(width: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 0.0),
                                  child: Text('-', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  children: [
                                    Text('${caloriesConsumed.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontFamily: 'NATS',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 20,
                                          height: 22/20,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center),
                                    Text('Food',
                                        style: TextStyle(
                                          fontFamily: 'NATS',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                          height: 22/15,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                                SizedBox(width: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 0.0),
                                  child: Text('=', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  children: [
                                    Text('$caloriesRemaining',
                                        style: TextStyle(
                                          fontFamily: 'NATS',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 20,
                                          height: 22/20,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center),
                                    Text('Remaining',
                                        style: TextStyle(
                                          fontFamily: 'NATS',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                          height: 22/15,
                                          letterSpacing: 0,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // --- Meal Sections ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        children: _mealTypes.map((mealType) {
                          final entries = _diaryEntriesByMeal[mealType] ?? [];
                          final mealCalories = entries.fold<double>(0, (sum, entry) => sum + entry.getTotalCalories());
                          return Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          mealType.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: 'Lexend',
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        mealCalories > 0 ? '${mealCalories.toStringAsFixed(0)}cal' : '0',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (entries.isNotEmpty)
                                    Column(
                                      children: [
                                        ...entries.map((entry) => Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: () async {
                                                    final updatedEntry = await showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      backgroundColor: Colors.transparent,
                                                      builder: (context) => Padding(
                                                        padding: EdgeInsets.only(
                                                          bottom: MediaQuery.of(context).viewInsets.bottom,
                                                        ),
                                                        child: EditEntryScreen(foodEntry: entry),
                                                      ),
                                                    );
                                                    if (updatedEntry != null && updatedEntry is FoodEntry) {
                                                      _updateFoodEntry(entry, updatedEntry);
                                                    }
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 4,
                                                        child: Text(
                                                          entry.name,
                                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                          '${entry.numberOfServings.toStringAsFixed(0)} ${entry.servingSizeUnit}',
                                                          style: const TextStyle(color: Colors.white, fontSize: 15),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                          '${entry.getTotalCalories().toStringAsFixed(0)}cal',
                                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                                          textAlign: TextAlign.right,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Divider(color: Colors.white24, height: 12, thickness: 1),
                                              ],
                                            )),
                                      ],
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SearchFoodScreen(
                                              preselectedMealType: mealType,
                                            ),
                                          ),
                                        );
                                        if (result != null && result is FoodEntry) {
                                          setState(() {
                                            _diaryEntriesByMeal[result.mealType]?.add(result);
                                          });
                                        }
                                      },
                                      child: const Text(
                                        'ADD FOOD',
                                        style: TextStyle(
                                          fontFamily: 'NATS',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 20,
                                          height: 22/20,
                                          letterSpacing: 0,
                                          color: Color(0xFF26C85A),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Search Food'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchFoodScreen(
                            preselectedMealType: _selectedMeal,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Scan Food'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// Reusing _StatColumn for calories consumed/goal
class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatColumn({super.key, required this.icon, required this.label}); // Added super.key

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: textColor)),
      ],
    );
  }
} 