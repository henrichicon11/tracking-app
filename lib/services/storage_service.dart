import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Thin wrapper around Hive boxes. Data is stored as plain maps.
class StorageService {
  static const _entriesBox = 'entries';
  static const _customFoodsBox = 'custom_foods';
  static const _waterBox = 'water';
  static const _weightBox = 'weight';
  static const _settingsBox = 'settings';

  late Box _entries;
  late Box _customFoods;
  late Box _water;
  late Box _weight;
  late Box _settings;

  Future<void> init() async {
    await Hive.initFlutter();
    _entries = await Hive.openBox(_entriesBox);
    _customFoods = await Hive.openBox(_customFoodsBox);
    _water = await Hive.openBox(_waterBox);
    _weight = await Hive.openBox(_weightBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // Entries
  List<FoodEntry> loadEntries() => _entries.values
      .whereType<Map>()
      .map((m) => FoodEntry.fromMap(m))
      .toList();
  Future<void> saveEntry(FoodEntry e) => _entries.put(e.id, e.toMap());
  Future<void> deleteEntry(String id) => _entries.delete(id);

  // Custom foods
  List<Food> loadCustomFoods() =>
      _customFoods.values.whereType<Map>().map((m) => Food.fromMap(m)).toList();
  Future<void> saveCustomFood(Food f) =>
      _customFoods.put(f.name.toLowerCase(), f.toMap());
  Future<void> deleteCustomFood(String name) =>
      _customFoods.delete(name.toLowerCase());

  // Water (ml per date)
  Map<String, double> loadWater() => {
    for (final k in _water.keys)
      k.toString(): (_water.get(k) as num?)?.toDouble() ?? 0,
  };
  Future<void> saveWater(String date, double ml) => _water.put(date, ml);

  // Weight (kg per date)
  Map<String, double> loadWeights() => {
    for (final k in _weight.keys)
      k.toString(): (_weight.get(k) as num?)?.toDouble() ?? 0,
  };
  Future<void> saveWeight(String date, double kg) => _weight.put(date, kg);
  Future<void> deleteWeight(String date) => _weight.delete(date);

  // Settings
  UserGoals loadGoals() {
    final m = _settings.get('goals');
    return m is Map ? UserGoals.fromMap(m) : const UserGoals();
  }

  Future<void> saveGoals(UserGoals g) => _settings.put('goals', g.toMap());

  bool get onboarded => _settings.get('onboarded', defaultValue: false) as bool;
  Future<void> setOnboarded(bool v) => _settings.put('onboarded', v);

  String? get userName => _settings.get('name') as String?;
  Future<void> setUserName(String v) => _settings.put('name', v);

  Future<void> clearAll() async {
    await _entries.clear();
    await _customFoods.clear();
    await _water.clear();
    await _weight.clear();
    await _settings.clear();
  }
}
