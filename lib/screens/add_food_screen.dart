import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/tracker_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/entry_sheet.dart';

class AddFoodScreen extends StatefulWidget {
  final MealType meal;
  const AddFoodScreen({super.key, required this.meal});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(Food f) async {
    final added = await showServingSheet(context, food: f, meal: widget.meal);
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${f.name} logged'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackerProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Add to ${widget.meal.label}'),
        actions: [
          TextButton.icon(
            onPressed: () => _openCustom(context),
            icon: const Icon(Icons.bolt),
            label: const Text('Quick add'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search foods (e.g. chicken, rice)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabs,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'All foods'),
                  Tab(text: 'Recent'),
                  Tab(text: 'My foods'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _FoodList(
              foods: p.searchFoods(_query),
              onTap: _pick,
              empty:
                  'No foods match "$_query".\nUse Quick add to log it manually.',
            ),
            _FoodList(
              foods: _filter(p.recentFoods),
              onTap: _pick,
              empty: 'Foods you log will appear here.',
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openCustom(context, save: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Create custom food'),
                  ),
                ),
                Expanded(
                  child: _FoodList(
                    foods: _filter(p.customFoods),
                    onTap: _pick,
                    onDelete: (f) => p.deleteCustomFood(f),
                    empty: 'Create your own foods and recipes.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Food> _filter(List<Food> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openCustom(BuildContext context, {bool save = false}) async {
    final food = await Navigator.of(context).push<Food>(
      MaterialPageRoute(
        builder: (_) =>
            CustomFoodScreen(saveByDefault: save, initialName: _query),
      ),
    );
    if (food != null && context.mounted) _pick(food);
  }
}

class _FoodList extends StatelessWidget {
  final List<Food> foods;
  final ValueChanged<Food> onTap;
  final ValueChanged<Food>? onDelete;
  final String empty;
  const _FoodList({
    required this.foods,
    required this.onTap,
    required this.empty,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return Center(
        child: EmptyHint(icon: Icons.search_off, text: empty),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: foods.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = foods[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(f),
            onLongPress: onDelete == null ? null : () => onDelete!(f),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${f.serving} · P ${fmt(f.protein, 1)}  C ${fmt(f.carbs, 1)}  F ${fmt(f.fat, 1)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fmt(f.calories),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    ' kcal',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.add_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomFoodScreen extends StatefulWidget {
  final bool saveByDefault;
  final String initialName;
  const CustomFoodScreen({
    super.key,
    this.saveByDefault = false,
    this.initialName = '',
  });

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  final _serving = TextEditingController(text: '1 serving');
  final _cal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();
  late bool _save = widget.saveByDefault;

  @override
  void dispose() {
    for (final c in [_name, _serving, _cal, _p, _c, _f]) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _autoCalories() {
    final kcal = _v(_p) * 4 + _v(_c) * 4 + _v(_f) * 9;
    if (kcal > 0) setState(() => _cal.text = fmt(kcal));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom food')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serving,
                decoration: const InputDecoration(
                  labelText: 'Serving size (e.g. 100g)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cal,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Calories (kcal)',
                  suffixIcon: IconButton(
                    tooltip: 'Calculate from macros',
                    icon: const Icon(Icons.calculate_outlined),
                    onPressed: _autoCalories,
                  ),
                ),
                validator: (v) {
                  final d = double.tryParse(v?.trim() ?? '');
                  if (d == null || d < 0) return 'Enter calories';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _macroField(_p, 'Protein g')),
                  const SizedBox(width: 10),
                  Expanded(child: _macroField(_c, 'Carbs g')),
                  const SizedBox(width: 10),
                  Expanded(child: _macroField(_f, 'Fat g')),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _save,
                onChanged: (v) => setState(() => _save = v),
                title: const Text('Save to My foods'),
                subtitle: const Text('Reuse it quickly later'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final food = Food(
                    name: _name.text.trim(),
                    serving: _serving.text.trim().isEmpty
                        ? '1 serving'
                        : _serving.text.trim(),
                    calories: _v(_cal),
                    protein: _v(_p),
                    carbs: _v(_c),
                    fat: _v(_f),
                    category: 'Custom',
                  );
                  if (_save) {
                    await context.read<TrackerProvider>().addCustomFood(food);
                  }
                  if (context.mounted) Navigator.pop(context, food);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroField(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );
}
