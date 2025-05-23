// lib/edit_entry_screen.dart
import 'package:flutter/material.dart';
import 'models/food_entry.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class EditEntryScreen extends StatefulWidget {
  final FoodEntry foodEntry;

  const EditEntryScreen({super.key, required this.foodEntry});

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late FoodEntry _currentEntry;
  late TextEditingController _servingSizeController;
  late String _selectedMealType;
  late String _selectedServingUnit;

  final List<String> _servingSizeUnitOptions = [
    'cup',
    'oz',
    'mg',
    'g',
    'lb(s)',
    'kg',
    'ml',
    'liter',
  ];
  final List<String> _mealTypeOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.foodEntry;
    _servingSizeController = TextEditingController(text: _currentEntry.numberOfServings.toString());
    _selectedMealType = _currentEntry.mealType;
    _selectedServingUnit = _currentEntry.servingSizeUnit;
  }

  @override
  void dispose() {
    _servingSizeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    print('Saving changes for entry: ${_currentEntry.name}'); // Debug print
    
    // Validate the serving size
    final double servingSize = double.tryParse(_servingSizeController.text) ?? _currentEntry.numberOfServings;
    if (servingSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid serving size greater than 0')),
      );
      return;
    }

    final updatedEntry = _currentEntry.copyWith(
      mealType: _selectedMealType,
      numberOfServings: servingSize,
      servingSizeUnit: _selectedServingUnit,
    );

    print('Updated entry: ${updatedEntry.name} with servings: $servingSize ${updatedEntry.servingSizeUnit}'); // Debug print
    Navigator.pop(context, updatedEntry);
  }

  // Calculate current nutrition values based on serving size
  double _getCurrentCalories() {
    final servingSize = double.tryParse(_servingSizeController.text) ?? _currentEntry.numberOfServings;
    final updatedEntry = _currentEntry.copyWith(
      numberOfServings: servingSize,
      servingSizeUnit: _selectedServingUnit,
    );
    return updatedEntry.getTotalCalories();
  }

  double _getCurrentProtein() {
    final servingSize = double.tryParse(_servingSizeController.text) ?? _currentEntry.numberOfServings;
    final updatedEntry = _currentEntry.copyWith(
      numberOfServings: servingSize,
      servingSizeUnit: _selectedServingUnit,
    );
    return updatedEntry.getTotalProtein();
  }

  double _getCurrentFat() {
    final servingSize = double.tryParse(_servingSizeController.text) ?? _currentEntry.numberOfServings;
    final updatedEntry = _currentEntry.copyWith(
      numberOfServings: servingSize,
      servingSizeUnit: _selectedServingUnit,
    );
    return updatedEntry.getTotalFat();
  }

  double _getCurrentCarbs() {
    final servingSize = double.tryParse(_servingSizeController.text) ?? _currentEntry.numberOfServings;
    final updatedEntry = _currentEntry.copyWith(
      numberOfServings: servingSize,
      servingSizeUnit: _selectedServingUnit,
    );
    return updatedEntry.getTotalCarbs();
  }

  String _servingDisplay(String unit) {
    return '1.0 $unit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Edit Entry',
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.black, size: 28),
                    onPressed: _saveChanges,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 20),
              child: Text(
              _currentEntry.name,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.black,
            ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Meal',
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
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMealType,
                              dropdownColor: Colors.black,
                              icon: SizedBox.shrink(),
                              style: const TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                                height: 22/20,
                                letterSpacing: 0,
                                color: Color(0xFF26C85A),
                              ),
                              alignment: Alignment.centerRight,
                              selectedItemBuilder: (context) => _mealTypeOptions.map((value) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontFamily: 'NATS',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 20,
                                      height: 22/20,
                                      letterSpacing: 0,
                                      color: Color(0xFF26C85A),
                                    ),
                                  ),
                                );
                              }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedMealType = newValue;
                            });
                          }
                        },
                        items: _mealTypeOptions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                                  alignment: Alignment.centerRight,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontFamily: 'NATS',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 20,
                                        height: 22/20,
                                        letterSpacing: 0,
                                        color: value == _selectedMealType ? Color(0xFF26C85A) : Colors.white,
                                      ),
                                    ),
                                  ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Number of Serving',
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
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () async {
                              final controller = TextEditingController(text: _servingSizeController.text);
                              final result = await showDialog<double>(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'How Much?',
                                            style: TextStyle(
                                              fontFamily: 'Lexend',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 20,
                                              height: 22/20,
                                              letterSpacing: 0,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 80,
                                                child: _greenUnderline(
                          child: TextField(
                                                    controller: controller,
                                                    autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontFamily: 'NATS',
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 32,
                                                      height: 22/32,
                                                      letterSpacing: 0,
                                                      color: Color(0xFF26C85A),
                                                    ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Serving(s) of',
                                                style: TextStyle(
                                                  fontFamily: 'NATS',
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 16,
                                                  height: 22/16,
                                                  letterSpacing: 0,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_currentEntry.servingSize ?? 1.0}${_selectedServingUnit}',
                                            style: const TextStyle(
                                              fontFamily: 'NATS',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16,
                                              height: 22/16,
                                              letterSpacing: 0,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontFamily: 'NATS',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 16,
                                                    height: 22/16,
                                                    letterSpacing: 0,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  final value = double.tryParse(controller.text);
                                                  if (value != null && value > 0) {
                                                    Navigator.pop(context, value);
                                                  }
                                                },
                                                child: const Text(
                                                  'Save',
                                                  style: TextStyle(
                                                    fontFamily: 'NATS',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 16,
                                                    height: 22/16,
                                                    letterSpacing: 0,
                                                    color: Color(0xFF26C85A),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (result != null) {
                              setState(() {
                                  _servingSizeController.text = result.toString();
                                });
                              }
                            },
                            child: Text(
                              _servingSizeController.text,
                              style: const TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                                height: 22/20,
                                letterSpacing: 0,
                                color: Color(0xFF26C85A),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Serving Size',
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
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedServingUnit,
                              dropdownColor: Colors.black,
                              icon: SizedBox.shrink(),
                              style: const TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                                height: 22/20,
                                letterSpacing: 0,
                                color: Color(0xFF26C85A),
                              ),
                              alignment: Alignment.centerRight,
                              selectedItemBuilder: (context) => _servingSizeUnitOptions.map((unit) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _servingDisplay(unit),
                                    style: const TextStyle(
                                      fontFamily: 'NATS',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 20,
                                      height: 22/20,
                                      letterSpacing: 0,
                                      color: Color(0xFF26C85A),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedServingUnit = newValue;
                                    _currentEntry = _currentEntry.copyWith(servingSizeUnit: newValue);
                                });
                              }
                            },
                              items: _servingSizeUnitOptions.map<DropdownMenuItem<String>>((unit) {
                              return DropdownMenuItem<String>(
                                  value: unit,
                                  alignment: Alignment.centerRight,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _servingDisplay(unit),
                                      style: TextStyle(
                                        fontFamily: 'NATS',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 20,
                                        height: 22/20,
                                        letterSpacing: 0,
                                        color: unit == _selectedServingUnit ? Color(0xFF26C85A) : Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              );
                            }).toList(),
                            ),
                          ),
                          ),
                        ),
                      ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFFA6CF98),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 35,
                            height: 35,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4A261),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7B6DCB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCurrentCalories().toStringAsFixed(0),
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 22/20,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Cal',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 22/14,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${_getCurrentCarbs().toStringAsFixed(1)}g',
                              style: const TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 32,
                                height: 22/32,
                                color: Color(0xFFA6CF98),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Carbs',
                              style: TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                height: 22/16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_getCurrentFat().toStringAsFixed(1)}g',
                              style: const TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 32,
                                height: 22/32,
                                color: Color(0xFFF4A261),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Fats',
                              style: TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                height: 22/16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_getCurrentProtein().toStringAsFixed(1)}g',
                              style: const TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 32,
                                height: 22/32,
                                color: Color(0xFF7B6DCB),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Protein',
                              style: TextStyle(
                                fontFamily: 'NATS',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                height: 22/16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required String label, required Widget child}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: textColor)),
        child,
      ],
    );
  }

  Widget _buildNutritionRow(BuildContext context,
      {required String label, required String value}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
        ],
      ),
    );
  }

  Widget _greenUnderline({required Widget child}) {
    return Column(
      children: [
        child,
        Container(
          margin: const EdgeInsets.only(top: 2),
          height: 2,
          color: const Color(0xFF26C85A),
        ),
      ],
    );
  }
} 