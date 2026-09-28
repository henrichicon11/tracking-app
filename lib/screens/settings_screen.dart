import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'goal_calculator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackerProvider>();
    final g = p.goals;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Goals')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SectionCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.isEmpty ? 'Set your name' : p.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          p.latestWeight == null
                              ? 'No weight logged'
                              : 'Current weight ${fmt(p.latestWeight!, 1)} kg',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editName(context, p),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _Header('Daily goals'),
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _GoalTile(
                    icon: Icons.local_fire_department,
                    color: AppColors.accent,
                    label: 'Calories',
                    value: g.calories,
                    unit: 'kcal',
                    onSave: (v) => p.updateGoals(g.copyWith(calories: v)),
                  ),
                  _GoalTile(
                    icon: Icons.fitness_center,
                    color: AppColors.protein,
                    label: 'Protein',
                    value: g.protein,
                    unit: 'g',
                    onSave: (v) => p.updateGoals(g.copyWith(protein: v)),
                  ),
                  _GoalTile(
                    icon: Icons.grain,
                    color: AppColors.carbs,
                    label: 'Carbs',
                    value: g.carbs,
                    unit: 'g',
                    onSave: (v) => p.updateGoals(g.copyWith(carbs: v)),
                  ),
                  _GoalTile(
                    icon: Icons.opacity,
                    color: AppColors.fat,
                    label: 'Fat',
                    value: g.fat,
                    unit: 'g',
                    onSave: (v) => p.updateGoals(g.copyWith(fat: v)),
                  ),
                  _GoalTile(
                    icon: Icons.water_drop,
                    color: AppColors.water,
                    label: 'Water',
                    value: g.waterMl,
                    unit: 'ml',
                    onSave: (v) => p.updateGoals(g.copyWith(waterMl: v)),
                  ),
                  _GoalTile(
                    icon: Icons.flag_outlined,
                    color: AppColors.primary,
                    label: 'Target weight',
                    value: g.targetWeight ?? 0,
                    unit: 'kg',
                    onSave: (v) => p.updateGoals(g.copyWith(targetWeight: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Recalculate goals')),
                    body: SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          GoalCalculatorForm(
                            initial: g,
                            initialWeight: p.latestWeight,
                            buttonText: 'Save goals',
                            onResult: (goals, _) {
                              p.updateGoals(goals);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Recalculate with goal calculator'),
            ),
            const SizedBox(height: 18),
            const _Header('Data'),
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: const Text('Custom foods'),
                    trailing: Text(
                      '${p.customFoods.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_note),
                    title: const Text('Days logged'),
                    trailing: Text(
                      '${p.loggedDates.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: AppColors.danger,
                    ),
                    title: const Text(
                      'Reset all data',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    onTap: () => _confirmReset(context, p),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'MacroTrack v1.0.0 · Data stored on device',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, TrackerProvider p) async {
    final c = TextEditingController(text: p.name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(fillColor: AppColors.bg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v != null) p.setName(v);
  }

  Future<void> _confirmReset(BuildContext context, TrackerProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This deletes all logged foods, weights, water and goals. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await p.resetAll();
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.muted,
        fontSize: 13,
      ),
    ),
  );
}

class _GoalTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final String unit;
  final ValueChanged<double> onSave;
  const _GoalTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value <= 0 ? 'Not set' : '${fmt(value, 1)} $unit',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
      onTap: () async {
        final c = TextEditingController(text: value <= 0 ? '' : fmt(value, 1));
        final v = await showDialog<double>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('$label goal'),
            content: TextField(
              controller: c,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                suffixText: unit,
                fillColor: AppColors.bg,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, double.tryParse(c.text.trim())),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (v != null && v > 0) onSave(v);
      },
    );
  }
}
