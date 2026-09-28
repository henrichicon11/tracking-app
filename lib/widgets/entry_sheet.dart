import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/tracker_provider.dart';
import '../theme.dart';
import 'common.dart';

/// Bottom sheet to pick servings + meal for a food. Used both for new
/// entries (food != null) and editing existing entries (entry != null).
Future<bool?> showServingSheet(
  BuildContext context, {
  required Food food,
  required MealType meal,
  FoodEntry? entry,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ServingSheet(food: food, meal: meal, entry: entry),
  );
}

Future<void> showEntrySheet(BuildContext context, FoodEntry e) async {
  await showServingSheet(context, food: e.toFood(), meal: e.meal, entry: e);
}

class _ServingSheet extends StatefulWidget {
  final Food food;
  final MealType meal;
  final FoodEntry? entry;
  const _ServingSheet({required this.food, required this.meal, this.entry});

  @override
  State<_ServingSheet> createState() => _ServingSheetState();
}

class _ServingSheetState extends State<_ServingSheet> {
  late double _servings = widget.entry?.servings ?? 1;
  late MealType _meal = widget.meal;
  late final _ctrl = TextEditingController(text: fmt(_servings, 2));

  void _set(double v) {
    setState(() {
      _servings = v.clamp(0.25, 50).toDouble();
      _ctrl.text = fmt(_servings, 2);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    final isEdit = widget.entry != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              f.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              'Serving: ${f.serving}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Nut(
                    'Calories',
                    fmt(f.calories * _servings),
                    'kcal',
                    AppColors.primary,
                  ),
                  _Nut(
                    'Protein',
                    fmt(f.protein * _servings, 1),
                    'g',
                    AppColors.protein,
                  ),
                  _Nut(
                    'Carbs',
                    fmt(f.carbs * _servings, 1),
                    'g',
                    AppColors.carbs,
                  ),
                  _Nut('Fat', fmt(f.fat * _servings, 1), 'g', AppColors.fat),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Servings',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => _set(_servings - 0.5),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(fillColor: AppColors.bg),
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null && d > 0) setState(() => _servings = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: () => _set(_servings + 0.5),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [0.5, 1.0, 1.5, 2.0, 3.0]
                  .map(
                    (v) => ChoiceChip(
                      label: Text('${fmt(v, 1)}×'),
                      selected: _servings == v,
                      onSelected: (_) => _set(v),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Meal', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<MealType>(
              showSelectedIcon: false,
              segments: MealType.values
                  .map(
                    (m) => ButtonSegment(
                      value: m,
                      label: Text(
                        m.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              selected: {_meal},
              onSelectionChanged: (s) => setState(() => _meal = s.first),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (isEdit) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        context.read<TrackerProvider>().deleteEntry(
                          widget.entry!.id,
                        );
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      final p = context.read<TrackerProvider>();
                      if (isEdit) {
                        p.updateEntry(
                          widget.entry!.copyWith(
                            servings: _servings,
                            meal: _meal,
                          ),
                        );
                      } else {
                        p.addEntry(food: f, servings: _servings, meal: _meal);
                      }
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      isEdit ? 'Save changes' : 'Add to ${_meal.label}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Nut extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _Nut(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          '$unit · $label',
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
