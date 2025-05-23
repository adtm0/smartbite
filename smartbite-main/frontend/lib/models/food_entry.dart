// lib/models/food_entry.dart
class FoodEntry {
  final int? id;
  final String name;
  final String mealType;
  final double numberOfServings;
  final double? servingSize;
  final String servingSizeUnit;
  final double calories;
  final double carbs;
  final double fat;
  final double protein;
  final DateTime entryDate;
  final String? fdcId;  // USDA FoodData Central ID

  FoodEntry({
    this.id,
    required this.name,
    this.mealType = 'Lunch',
    this.numberOfServings = 1.0,
    this.servingSize,
    this.servingSizeUnit = 'g',
    required this.calories,
    required this.carbs,
    required this.fat,
    required this.protein,
    required this.entryDate,
    this.fdcId,
  });

  // Unit conversion factors (relative to grams)
  static const Map<String, double> _unitConversionFactors = {
    'g': 1.0,
    'ml': 1.0, // Assuming density of 1g/ml for simplicity
    'oz': 28.3495,
    'lb': 453.592,
    'cup': 240.0, // Approximate conversion
    'serving': 100.0, // Standard serving size
  };

  // Helper method to calculate nutrients based on serving size and unit
  double _calculateNutrient(double baseValue) {
    // Get the conversion factor for the current unit
    double conversionFactor = _unitConversionFactors[servingSizeUnit] ?? 1.0;
    
    // Calculate the total nutrient value:
    // 1. The baseValue is per 100g
    // 2. Calculate for one unit of the selected serving size
    // 3. Multiply by the number of servings
    return (baseValue * conversionFactor / 100.0) * numberOfServings;
  }

  // Nutrition calculation methods
  double getTotalCalories() => _calculateNutrient(calories);
  double getTotalCarbs() => _calculateNutrient(carbs);
  double getTotalFat() => _calculateNutrient(fat);
  double getTotalProtein() => _calculateNutrient(protein);

  FoodEntry copyWith({
    int? id,
    String? name,
    String? mealType,
    double? numberOfServings,
    double? servingSize,
    String? servingSizeUnit,
    double? calories,
    double? carbs,
    double? fat,
    double? protein,
    DateTime? entryDate,
    String? fdcId,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      numberOfServings: numberOfServings ?? this.numberOfServings,
      servingSize: servingSize ?? this.servingSize,
      servingSizeUnit: servingSizeUnit ?? this.servingSizeUnit,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      protein: protein ?? this.protein,
      entryDate: entryDate ?? this.entryDate,
      fdcId: fdcId ?? this.fdcId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': name,
      'meal_type': mealType,
      'number_of_servings': numberOfServings,
      'serving_size': servingSize,
      'serving_size_unit': servingSizeUnit,
      'calories': calories,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'fdc_id': fdcId,
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as int?,
      name: map['food_name'] as String,
      mealType: map['meal_type'] as String,
      numberOfServings: (map['number_of_servings'] as num).toDouble(),
      servingSize: map['serving_size'] != null ? (map['serving_size'] as num).toDouble() : null,
      servingSizeUnit: map['serving_size_unit'] as String,
      calories: (map['calories'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      entryDate: DateTime.parse(map['entry_date'] as String),
      fdcId: map['fdc_id'] as String?,
    );
  }
} 