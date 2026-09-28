import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/tracker_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackerProvider>();
    final dates = p.loggedDates;
    final goal = p.goals.calories;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: dates.isEmpty
            ? const Center(
                child: EmptyHint(
                  icon: Icons.history,
                  text:
                      'No meals logged yet.\nStart by logging your first food!',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: dates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = dates[i];
                  final t = p.totalsFor(d);
                  final entries = p.entriesFor(d);
                  final pct = goal <= 0 ? 0.0 : t.calories / goal;
                  final over = pct > 1.05;
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openDay(context, d),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 54,
                              height: 54,
                              child: CustomPaint(
                                painter: RingPainter(
                                  progress: pct,
                                  stroke: 6,
                                  color: over
                                      ? AppColors.accent
                                      : AppColors.primary,
                                ),
                                child: Center(
                                  child: Text(
                                    '${fmt(pct * 100)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prettyDate(parseDateKey(d)),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${entries.length} items · P ${fmt(t.protein)}g  C ${fmt(t.carbs)}g  F ${fmt(t.fat)}g',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  fmt(t.calories),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: over
                                        ? AppColors.accent
                                        : AppColors.text,
                                  ),
                                ),
                                const Text(
                                  'kcal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _openDay(BuildContext context, String d) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _DayDetail(date: d)));
  }
}

class _DayDetail extends StatelessWidget {
  final String date;
  const _DayDetail({required this.date});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackerProvider>();
    final t = p.totalsFor(date);
    return Scaffold(
      appBar: AppBar(
        title: Text(prettyDate(parseDateKey(date))),
        actions: [
          TextButton(
            onPressed: () {
              p.selectDate(parseDateKey(date));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Day opened in Today tab for editing'),
                ),
              );
            },
            child: const Text('Edit day'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _kv('Calories', fmt(t.calories), AppColors.primary),
                  _kv('Protein', '${fmt(t.protein)}g', AppColors.protein),
                  _kv('Carbs', '${fmt(t.carbs)}g', AppColors.carbs),
                  _kv('Fat', '${fmt(t.fat)}g', AppColors.fat),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final m in MealType.values)
              if (p.entriesForMeal(date, m).isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                  child: Text(
                    m.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      for (final e in p.entriesForMeal(date, m))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.name),
                          subtitle: Text(
                            '${fmt(e.servings, 2)} × ${e.serving}',
                          ),
                          trailing: Text(
                            '${fmt(e.totalCalories)} kcal',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, Color c) => Column(
    children: [
      Text(
        v,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: c),
      ),
      Text(k, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ],
  );
}
