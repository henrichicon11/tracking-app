/// Core data models for MacroTrack. Stored in Hive as plain maps
/// (no code generation required).
library;

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snacks';
    }
  }
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

double _d(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

/// A food definition (per single serving).
class Food {
  final String name;
  final String serving; // e.g. "1 medium (118g)"
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String category;

  const Food({
    required this.name,
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.category = 'Other',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'serving': serving,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'category': category,
  };

  factory Food.fromMap(Map map) => Food(
    name: (map['name'] as String?) ?? 'Food',
    serving: (map['serving'] as String?) ?? '1 serving',
    calories: _d(map['calories']),
    protein: _d(map['protein']),
    carbs: _d(map['carbs']),
    fat: _d(map['fat']),
    category: (map['category'] as String?) ?? 'Custom',
  );
}

/// A logged food entry for a specific day and meal.
class FoodEntry {
  final String id;
  final String name;
  final String serving;
  final double servings;
  final double calories; // per serving
  final double protein;
  final double carbs;
  final double fat;
  final MealType meal;
  final String date; // yyyy-mm-dd
  final DateTime createdAt;

  FoodEntry({
    required this.id,
    required this.name,
    required this.serving,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meal,
    required this.date,
    required this.createdAt,
  });

  double get totalCalories => calories * servings;
  double get totalProtein => protein * servings;
  double get totalCarbs => carbs * servings;
  double get totalFat => fat * servings;

  FoodEntry copyWith({double? servings, MealType? meal}) => FoodEntry(
    id: id,
    name: name,
    serving: serving,
    servings: servings ?? this.servings,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    meal: meal ?? this.meal,
    date: date,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'serving': serving,
    'servings': servings,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'meal': meal.index,
    'date': date,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory FoodEntry.fromMap(Map map) {
    final mealIdx = (map['meal'] as num?)?.toInt() ?? 3;
    return FoodEntry(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? 'Food',
      serving: (map['serving'] as String?) ?? '1 serving',
      servings: _d(map['servings'], 1),
      calories: _d(map['calories']),
      protein: _d(map['protein']),
      carbs: _d(map['carbs']),
      fat: _d(map['fat']),
      meal: MealType.values[mealIdx.clamp(0, MealType.values.length - 1)],
      date: (map['date'] as String?) ?? dateKey(DateTime.now()),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Food toFood() => Food(
    name: name,
    serving: serving,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    category: 'Recent',
  );
}

class WeightEntry {
  final String date;
  final double kg;
  WeightEntry(this.date, this.kg);
}

enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

extension ActivityLevelX on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Lightly active';
      case ActivityLevel.moderate:
        return 'Moderately active';
      case ActivityLevel.active:
        return 'Very active';
      case ActivityLevel.veryActive:
        return 'Extra active';
    }
  }

  double get factor {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }
}

class UserGoals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double waterMl;
  final double? targetWeight;

  const UserGoals({
    this.calories = 2000,
    this.protein = 150,
    this.carbs = 200,
    this.fat = 67,
    this.waterMl = 2500,
    this.targetWeight,
  });

  UserGoals copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? waterMl,
    double? targetWeight,
  }) => UserGoals(
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    waterMl: waterMl ?? this.waterMl,
    targetWeight: targetWeight ?? this.targetWeight,
  );

  Map<String, dynamic> toMap() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'waterMl': waterMl,
    'targetWeight': targetWeight,
  };

  factory UserGoals.fromMap(Map map) => UserGoals(
    calories: _d(map['calories'], 2000),
    protein: _d(map['protein'], 150),
    carbs: _d(map['carbs'], 200),
    fat: _d(map['fat'], 67),
    waterMl: _d(map['waterMl'], 2500),
    targetWeight: map['targetWeight'] == null ? null : _d(map['targetWeight']),
  );
}

/// Mifflin-St Jeor BMR -> TDEE calculator.
double calculateTdee({
  required Sex sex,
  required int age,
  required double heightCm,
  required double weightKg,
  required ActivityLevel activity,
}) {
  final bmr =
      10 * weightKg + 6.25 * heightCm - 5 * age + (sex == Sex.male ? 5 : -161);
  return bmr * activity.factor;
}
