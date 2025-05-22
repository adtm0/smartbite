// lib/edit_entry_screen.dart
import 'package:flutter/material.dart';
import 'models/food_entry.dart';

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
    'g',
    'ml',
    'oz',
    'lb',
    'cup',
    'serving',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Entry',
          style: TextStyle(color: theme.appBarTheme.foregroundColor),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentEntry.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildRow(
                    context,
                    label: 'Meal Type',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMealType,
                        dropdownColor: cardColor,
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
                            child: Text(value, style: TextStyle(color: textColor)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _buildRow(
                    context,
                    label: 'Servings',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _servingSizeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            style: TextStyle(color: textColor),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              // Update nutrition values immediately
                              setState(() {
                                // No need to do anything else, the build method will use the new value
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedServingUnit,
                            dropdownColor: cardColor,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedServingUnit = newValue;
                                  // Update current entry with new unit to trigger recalculation
                                  _currentEntry = _currentEntry.copyWith(
                                    servingSizeUnit: newValue,
                                  );
                                });
                              }
                            },
                            items: _servingSizeUnitOptions.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: TextStyle(color: textColor)),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nutrition Facts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  _buildNutritionRow(
                    context,
                    label: 'Total Calories',
                    value: '${_getCurrentCalories().toStringAsFixed(0)} kcal',
                  ),
                  _buildNutritionRow(
                    context,
                    label: 'Total Protein',
                    value: '${_getCurrentProtein().toStringAsFixed(1)} g',
                  ),
                  _buildNutritionRow(
                    context,
                    label: 'Total Fat',
                    value: '${_getCurrentFat().toStringAsFixed(1)} g',
                  ),
                  _buildNutritionRow(
                    context,
                    label: 'Total Carbs',
                    value: '${_getCurrentCarbs().toStringAsFixed(1)} g',
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
} 