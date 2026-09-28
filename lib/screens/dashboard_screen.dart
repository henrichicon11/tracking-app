import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/tracker_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/entry_sheet.dart';
import 'add_food_screen.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String prettyDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == -1) return 'Yesterday';
  if (diff == 1) return 'Tomorrow';
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackerProvider>();
    final key = p.selectedKey;
    final totals = p.totalsFor(key);
    final g = p.goals;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.isEmpty ? 'Hello!' : 'Hi, ${p.name}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'MacroTrack',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.streak} day${p.streak == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _DateSwitcher(p: p)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CalorieCard(totals: totals, goals: g),
                const SizedBox(height: 14),
                _WaterCard(p: p),
                const SizedBox(height: 14),
                for (final meal in MealType.values) ...[
                  _MealCard(meal: meal),
                  const SizedBox(height: 12),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSwitcher extends StatelessWidget {
  final TrackerProvider p;
  const _DateSwitcher({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => p.shiftDay(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: p.selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) p.selectDate(d);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                prettyDate(p.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => p.shiftDay(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _CalorieCard extends StatelessWidget {
  final DayTotals totals;
  final UserGoals goals;
  const _CalorieCard({required this.totals, required this.goals});

  @override
  Widget build(BuildContext context) {
    final remaining = goals.calories - totals.calories;
    final over = remaining < 0;
    final progress = goals.calories <= 0
        ? 0.0
        : totals.calories / goals.calories;
    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: RingPainter(
                    progress: progress,
                    color: over ? AppColors.accent : AppColors.primary,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmt(remaining.abs()),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: over ? AppColors.accent : AppColors.text,
                          ),
                        ),
                        Text(
                          over ? 'kcal over' : 'kcal left',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stat(
                      icon: Icons.flag_outlined,
                      label: 'Goal',
                      value: fmt(goals.calories),
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 14),
                    _Stat(
                      icon: Icons.restaurant,
                      label: 'Eaten',
                      value: fmt(totals.calories),
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 14),
                    _Stat(
                      icon: Icons.percent,
                      label: 'Of goal',
                      value: '${fmt(progress * 100)}%',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MacroBar(
                  label: 'Protein',
                  value: totals.protein,
                  goal: goals.protein,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MacroBar(
                  label: 'Carbs',
                  value: totals.carbs,
                  goal: goals.carbs,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MacroBar(
                  label: 'Fat',
                  value: totals.fat,
                  goal: goals.fat,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaterCard extends StatelessWidget {
  final TrackerProvider p;
  const _WaterCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final ml = p.waterFor(p.selectedKey);
    final goal = p.goals.waterMl;
    final glasses = (goal / 250).ceil().clamp(1, 16);
    final filled = (ml / 250).floor();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppColors.water),
              const SizedBox(width: 8),
              const Text(
                'Water',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${fmt(ml)} / ${fmt(goal)} ml',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(glasses, (i) {
              final isFilled = i < filled;
              return GestureDetector(
                onTap: () => p.addWater(isFilled ? -250 : 250),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 30,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? AppColors.water
                        : AppColors.water.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                      bottom: Radius.circular(10),
                    ),
                  ),
                  child: Icon(
                    Icons.water_drop,
                    size: 14,
                    color: isFilled
                        ? Colors.white
                        : AppColors.water.withValues(alpha: 0.5),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WaterBtn(label: '-250', onTap: () => p.addWater(-250)),
              const SizedBox(width: 8),
              _WaterBtn(label: '+250 ml', onTap: () => p.addWater(250)),
              const SizedBox(width: 8),
              _WaterBtn(label: '+500 ml', onTap: () => p.addWater(500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WaterBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.water,
          side: BorderSide(color: AppColors.water.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

IconData mealIcon(MealType m) {
  switch (m) {
    case MealType.breakfast:
      return Icons.free_breakfast_outlined;
    case MealType.lunch:
      return Icons.lunch_dining_outlined;
    case MealType.dinner:
      return Icons.dinner_dining_outlined;
    case MealType.snack:
      return Icons.cookie_outlined;
  }
}

class _MealCard extends StatelessWidget {
  final MealType meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackerProvider>();
    final entries = p.entriesForMeal(p.selectedKey, meal);
    final cals = entries.fold<double>(0, (s, e) => s + e.totalCalories);
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(mealIcon(meal), color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      entries.isEmpty
                          ? 'Nothing logged'
                          : '${fmt(cals)} kcal · ${entries.length} item${entries.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.muted),
                onSelected: (v) async {
                  if (v == 'copy') {
                    final n = await p.copyMealFromPreviousDay(meal);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            n == 0
                                ? 'No ${meal.label.toLowerCase()} logged the day before'
                                : 'Copied $n item${n == 1 ? '' : 's'}',
                          ),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'copy',
                    child: Text('Copy from previous day'),
                  ),
                ],
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddFoodScreen(meal: meal)),
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (entries.isNotEmpty) const Divider(height: 18),
          for (final e in entries)
            Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: AppColors.danger.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
              ),
              onDismissed: (_) {
                p.deleteEntry(e.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${e.name}'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => p.restoreEntry(e),
                    ),
                  ),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.only(right: 10),
                dense: true,
                onTap: () => showEntrySheet(context, e),
                title: Text(
                  e.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${fmt(e.servings, 2)} × ${e.serving} · P ${fmt(e.totalProtein)}g  C ${fmt(e.totalCarbs)}g  F ${fmt(e.totalFat)}g',
                ),
                trailing: Text(
                  '${fmt(e.totalCalories)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
