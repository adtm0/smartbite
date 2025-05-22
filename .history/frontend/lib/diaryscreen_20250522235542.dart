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

    // TODO: In the future, this should be fetched from user preferences
    const int calorieGoal = 2000;
    final double caloriesConsumed = _calculateTotalCaloriesConsumed();
    final int caloriesRemaining =
        (calorieGoal - caloriesConsumed).clamp(0, calorieGoal).toInt();
    final double calorieProgress =
        calorieGoal == 0 ? 0.0 : caloriesConsumed / calorieGoal;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button from working
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back arrow
          title: const Text('Food Diary'),
          actions: [
            // Theme toggle button
            IconButton(
              icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
            // Logout button
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // --- Date Navigation and Calorie Summary Header ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      color: theme.scaffoldBackgroundColor, // Ensure consistent background
                      child: Column(
                        children: [
                          // Date Navigation Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
                                onPressed: () => _changeDate(-1),
                              ),
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward_ios, color: textColor, size: 20),
                                onPressed: () => _changeDate(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Calorie Summary Circle
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: CircularPercentIndicator(
                                    key: ValueKey<double>(calorieProgress), // Key for animation
                                    radius: screenWidth * 0.2,
                                    lineWidth: 10.0,
                                    percent: calorieProgress.clamp(0.0, 1.0),
                                    center: Text(
                                      "$caloriesRemaining\nRemaining",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.greenAccent, fontSize: 18),
                                    ),
                                    progressColor: Colors.greenAccent,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatColumn(icon: Icons.flag, label: "$calorieGoal"),
                                    _StatColumn(
                                        icon: Icons.restaurant, label: "${caloriesConsumed.toStringAsFixed(0)}"),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- End Date Navigation and Calorie Summary Header ---

                    // Meal Sections (previously implemented)
                    Padding(
                      padding: const EdgeInsets.all(16.0), // Padding for the meal sections
                      child: Column(
                        children: _mealTypes.map((mealType) {
                          final entries = _diaryEntriesByMeal[mealType] ?? [];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mealType,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // List of existing entries
                                if (entries.isNotEmpty)
                                  ...entries.map((entry) => Card(
                                        color: cardColor,
                                        elevation: 2,
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: ListTile(
                                          title: Text(entry.name, style: TextStyle(color: textColor)),
                                          subtitle: Text(
                                            '${entry.numberOfServings.toStringAsFixed(0)} ${entry.servingSizeUnit} - ${entry.getTotalCalories().toStringAsFixed(0)} Cal',
                                            style: TextStyle(color: textColor.withOpacity(0.8)),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.green),
                                                onPressed: () async {
                                                  final updatedEntry = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => EditEntryScreen(foodEntry: entry),
                                                    ),
                                                  );
                                                  if (updatedEntry != null && updatedEntry is FoodEntry) {
                                                    _updateFoodEntry(entry, updatedEntry);
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteFoodEntry(entry),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )).toList(),
                                // "Add Food" button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
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
                                                      preselectedMealType: mealType,
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
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.green.withOpacity(0.7)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: Icon(Icons.add, color: Colors.green),
                                    label: Text(
                                      'Add Food to $mealType',
                                      style: TextStyle(color: Colors.green, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
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