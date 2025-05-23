import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'scan_screen.dart'; // <-- Import your scanner screen
import 'package:google_fonts/google_fonts.dart';
import 'search_food_screen.dart';
import 'services/food_service.dart';
import 'models/food_entry.dart';
import 'profile_screen.dart';

// Shared calorie goal for both Diary and Dashboard
const int baseGoal = 1800;
const int carbsGoal = 230;
const int fatGoal = 50;
const int proteinGoal = 100;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Sums for today
  double foodCalories = 0;
  double carbs = 0;
  double fat = 0;
  double protein = 0;

  @override
  void initState() {
    super.initState();
    _fetchTodayEntries();
  }

  Future<void> _fetchTodayEntries() async {
    try {
      final entries = await FoodService.getFoodEntries(DateTime.now());
      double totalCalories = 0, totalCarbs = 0, totalFat = 0, totalProtein = 0;
      for (final entry in entries) {
        print('Entry: \\${entry.name}, Calories: \\${entry.getTotalCalories()}');
        totalCalories += entry.getTotalCalories();
        totalCarbs += entry.getTotalCarbs();
        totalFat += entry.getTotalFat();
        totalProtein += entry.getTotalProtein();
      }
      setState(() {
        foodCalories = totalCalories;
        carbs = totalCarbs;
        fat = totalFat;
        protein = totalProtein;
      });
    } catch (e) {
      // Optionally show error
    }
  }

  Future<void> scanAndFetch() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );

    if (barcode != null) {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final product = data['product'];
        final int? kcal = product['nutriments']?['energy-kcal_100g']?.toInt();

        if (kcal != null) {
          setState(() {
            // Optionally update foodCalories, but _fetchTodayEntries will be the source of truth
          });
          _fetchTodayEntries();
        } else {
          showError('Calories not found for this item.');
        }
      } else {
        showError('Failed to fetch food info.');
      }
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: const Icon(Icons.person, color: Colors.black, size: 28),
                      ),
                      Text(
                        'SMARTBITE',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF22A045),
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 28,
                          letterSpacing: 0,
                        ),
                      ),
                      const Icon(Icons.notifications, color: Colors.black, size: 28),
                    ],
                  ),
                ),
                // Today label
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Today',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Calories Card
                Center(
                  child: Container(
                    width: 371,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x66000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Calories',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 24,
                              height: 22/24,
                              letterSpacing: 0,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Figma-style calories circle
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer white circle
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                              // Green inner circle
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF26C85A),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF26C85A), width: 1),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(baseGoal - foodCalories).toInt()}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      height: 22/22,
                                      letterSpacing: 0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Remaining',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      height: 22/11,
                                      letterSpacing: 0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Base Goal
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.flag, color: Colors.white, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      'Base Goal',
                                      style: TextStyle(
                                        fontFamily: 'NATS',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        height: 22 / 14,
                                        letterSpacing: 0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '$baseGoal',
                                  style: TextStyle(
                                    fontFamily: 'Russo One',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    height: 22 / 14,
                                    letterSpacing: 0,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            SizedBox(width: 48), // Adjust for symmetry
                            // Food
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.restaurant, color: Colors.white, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      'Food',
                                      style: TextStyle(
                                        fontFamily: 'NATS',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        height: 22 / 14,
                                        letterSpacing: 0,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${foodCalories.toInt()}',
                                  style: TextStyle(
                                    fontFamily: 'Russo One',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    height: 22 / 14,
                                    letterSpacing: 0,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Spacer (reduce or remove to move macros card up)
                SizedBox(height: 8),
                // Macros Card
                Center(
                  child: Container(
                    width: 371,
                    height: 225,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x66000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Macros',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _macroFigmaCircle(
                              label: 'Carbohydrates',
                              value: carbs,
                              goal: carbsGoal,
                              color: const Color(0xFFB6F7B0),
                              labelColor: const Color(0xFFB6F7B0),
                            ),
                            _macroFigmaCircle(
                              label: 'Fat',
                              value: fat,
                              goal: fatGoal,
                              color: const Color(0xFFFFE5B4),
                              labelColor: const Color(0xFFFFE5B4),
                            ),
                            _macroFigmaCircle(
                              label: 'Protein',
                              value: protein,
                              goal: proteinGoal,
                              color: const Color(0xFFD1C4E9),
                              labelColor: const Color(0xFFD1C4E9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Black curved background at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipPath(
                clipper: BottomCurveClipper(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.black,
                ),
              ),
            ),
            // Search Bar and Scanner on top of black background
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.92,
                              minChildSize: 0.6,
                              maxChildSize: 0.98,
                              expand: false,
                              builder: (context, scrollController) => Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                                ),
                                child: SearchFoodScreen(),
                              ),
                            ),
                          );
                          if (result != null) {
                            _fetchTodayEntries();
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(Icons.search, color: Colors.black),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Search for a food',
                                  style: GoogleFonts.poppins(color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroFigmaCircle({
    required String label,
    required double value,
    required int goal,
    required Color color,
    required Color labelColor,
  }) {
    final bool isCarbs = label.toLowerCase().contains('carb');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'NATS',
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ).copyWith(color: labelColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: isCarbs ? 80 : 56,
              height: isCarbs ? 80 : 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                double progress = ((goal > 0 ? value / goal : 0).clamp(0.0, 1.0)).toDouble();
                double minSize = 20;
                double maxSize = isCarbs ? 60 : 32;
                double innerSize = minSize + (maxSize - minSize) * progress;
                return Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: isCarbs ? 1 : 0),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toInt()}g / ${goal}g',
          style: const TextStyle(
            fontFamily: 'NATS',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF22A045) : Colors.white, size: 28),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? const Color(0xFF22A045) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 90);
    path.quadraticBezierTo(
      size.width / 2, 60, // control point (shallow curve, even lower)
      size.width, 90,    // end point
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
