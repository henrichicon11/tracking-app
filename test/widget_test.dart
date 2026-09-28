import 'package:flutter_test/flutter_test.dart';
import 'package:macrotrack/models/models.dart';

void main() {
  test('TDEE calculation is sensible', () {
    final tdee = calculateTdee(
      sex: Sex.male,
      age: 30,
      heightCm: 175,
      weightKg: 75,
      activity: ActivityLevel.sedentary,
    );
    expect(tdee, closeTo(1698.75 * 1.2, 0.01));
  });

  test('FoodEntry round-trips through map', () {
    final e = FoodEntry(
      id: '1',
      name: 'Apple',
      serving: '1 medium',
      servings: 2,
      calories: 95,
      protein: 0.5,
      carbs: 25,
      fat: 0.3,
      meal: MealType.snack,
      date: '2025-01-01',
      createdAt: DateTime(2025),
    );
    final r = FoodEntry.fromMap(e.toMap());
    expect(r.totalCalories, 190);
    expect(r.meal, MealType.snack);
  });
}
