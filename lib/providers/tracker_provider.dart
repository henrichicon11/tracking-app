import 'package:flutter/foundation.dart';

import '../data/food_database.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class DayTotals {
  final double calories, protein, carbs, fat;
  const DayTotals(this.calories, this.protein, this.carbs, this.fat);
  static const zero = DayTotals(0, 0, 0, 0);
}

class TrackerProvider extends ChangeNotifier {
  final StorageService storage;
  TrackerProvider(this.storage) {
    _entries = storage.loadEntries();
    _customFoods = storage.loadCustomFoods();
    _water = storage.loadWater();
    _weights = storage.loadWeights();
    _goals = storage.loadGoals();
    _name = storage.userName ?? '';
    _onboarded = storage.onboarded;
  }

  late List<FoodEntry> _entries;
  late List<Food> _customFoods;
  late Map<String, double> _water;
  late Map<String, double> _weights;
  late UserGoals _goals;
  late String _name;
  late bool _onboarded;

  DateTime _selectedDate = DateTime.now();

  UserGoals get goals => _goals;
  String get name => _name;
  bool get onboarded => _onboarded;
  DateTime get selectedDate => _selectedDate;
  String get selectedKey => dateKey(_selectedDate);
  List<Food> get customFoods => List.unmodifiable(_customFoods);

  bool get isToday => selectedKey == dateKey(DateTime.now());

  void selectDate(DateTime d) {
    _selectedDate = DateTime(d.year, d.month, d.day);
    notifyListeners();
  }

  void shiftDay(int delta) =>
      selectDate(_selectedDate.add(Duration(days: delta)));

  // ---------- Entries ----------
  List<FoodEntry> entriesFor(String date) {
    final list = _entries.where((e) => e.date == date).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  List<FoodEntry> entriesForMeal(String date, MealType meal) =>
      entriesFor(date).where((e) => e.meal == meal).toList();

  DayTotals totalsFor(String date) {
    double c = 0, p = 0, cb = 0, f = 0;
    for (final e in _entries) {
      if (e.date != date) continue;
      c += e.totalCalories;
      p += e.totalProtein;
      cb += e.totalCarbs;
      f += e.totalFat;
    }
    return DayTotals(c, p, cb, f);
  }

  Future<void> addEntry({
    required Food food,
    required double servings,
    required MealType meal,
    String? date,
  }) async {
    final e = FoodEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: food.name,
      serving: food.serving,
      servings: servings,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      meal: meal,
      date: date ?? selectedKey,
      createdAt: DateTime.now(),
    );
    _entries.add(e);
    notifyListeners();
    await storage.saveEntry(e);
  }

  Future<void> updateEntry(FoodEntry e) async {
    final i = _entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) _entries[i] = e;
    notifyListeners();
    await storage.saveEntry(e);
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await storage.deleteEntry(id);
  }

  Future<FoodEntry?> restoreEntry(FoodEntry e) async {
    _entries.add(e);
    notifyListeners();
    await storage.saveEntry(e);
    return e;
  }

  /// Copy all entries of a meal from yesterday (relative to selected date).
  Future<int> copyMealFromPreviousDay(MealType meal) async {
    final prev = dateKey(_selectedDate.subtract(const Duration(days: 1)));
    final items = entriesForMeal(prev, meal);
    for (final e in items) {
      await addEntry(food: e.toFood(), servings: e.servings, meal: meal);
    }
    return items.length;
  }

  // ---------- Foods ----------
  List<Food> get allFoods => [..._customFoods, ...kFoodDatabase];

  List<Food> get recentFoods {
    final sorted = [..._entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = <String>{};
    final result = <Food>[];
    for (final e in sorted) {
      if (seen.add(e.name.toLowerCase())) result.add(e.toFood());
      if (result.length >= 15) break;
    }
    return result;
  }

  List<Food> searchFoods(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return allFoods;
    return allFoods
        .where((f) =>
            f.name.toLowerCase().contains(query) ||
            f.category.toLowerCase().contains(query))
        .toList();
  }

  Future<void> addCustomFood(Food f) async {
    _customFoods.removeWhere((x) => x.name.toLowerCase() == f.name.toLowerCase());
    _customFoods.insert(0, f);
    notifyListeners();
    await storage.saveCustomFood(f);
  }

  Future<void> deleteCustomFood(Food f) async {
    _customFoods.removeWhere((x) => x.name.toLowerCase() == f.name.toLowerCase());
    notifyListeners();
    await storage.deleteCustomFood(f.name);
  }

  // ---------- Water ----------
  double waterFor(String date) => _water[date] ?? 0;

  Future<void> addWater(double ml) async {
    final v = (waterFor(selectedKey) + ml).clamp(0, 20000).toDouble();
    _water[selectedKey] = v;
    notifyListeners();
    await storage.saveWater(selectedKey, v);
  }

  // ---------- Weight ----------
  List<WeightEntry> get weights {
    final list = _weights.entries.map((e) => WeightEntry(e.key, e.value)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  double? get latestWeight => weights.isEmpty ? null : weights.last.kg;

  Future<void> logWeight(double kg, {String? date}) async {
    final d = date ?? dateKey(DateTime.now());
    _weights[d] = kg;
    notifyListeners();
    await storage.saveWeight(d, kg);
  }

  Future<void> deleteWeight(String date) async {
    _weights.remove(date);
    notifyListeners();
    await storage.deleteWeight(date);
  }

  // ---------- Stats ----------
  /// Returns the last [days] days ending at today (oldest first).
  List<MapEntry<DateTime, DayTotals>> lastDays(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: days - 1 - i));
      return MapEntry(d, totalsFor(dateKey(d)));
    });
  }

  /// Consecutive days (ending today or yesterday) with at least one entry.
  int get streak {
    final dates = _entries.map((e) => e.date).toSet();
    var d = DateTime.now();
    if (!dates.contains(dateKey(d))) d = d.subtract(const Duration(days: 1));
    var count = 0;
    while (dates.contains(dateKey(d))) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }

  List<String> get loggedDates {
    final s = _entries.map((e) => e.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return s;
  }

  // ---------- Settings ----------
  Future<void> updateGoals(UserGoals g) async {
    _goals = g;
    notifyListeners();
    await storage.saveGoals(g);
  }

  Future<void> completeOnboarding({
    required String name,
    required UserGoals goals,
    double? weightKg,
  }) async {
    _name = name;
    _goals = goals;
    _onboarded = true;
    await storage.setUserName(name);
    await storage.saveGoals(goals);
    await storage.setOnboarded(true);
    if (weightKg != null) await logWeight(weightKg);
    notifyListeners();
  }

  Future<void> setName(String n) async {
    _name = n;
    notifyListeners();
    await storage.setUserName(n);
  }

  Future<void> resetAll() async {
    await storage.clearAll();
    _entries = [];
    _customFoods = [];
    _water = {};
    _weights = {};
    _goals = const UserGoals();
    _name = '';
    _onboarded = false;
    notifyListeners();
  }
}
