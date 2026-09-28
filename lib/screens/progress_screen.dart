import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/tracker_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TrackerProvider>();
    final days = p.lastDays(_range);
    final values = days.map((e) => e.value.calories).toList();
    final labels = days
        .map((e) => _range == 7 ? _wd[e.key.weekday - 1] : '${e.key.day}')
        .toList();
    final logged = days.where((e) => e.value.calories > 0).toList();
    final avg = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (s, e) => s + e.value.calories) /
              logged.length;
    final avgP = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (s, e) => s + e.value.protein) / logged.length;
    final avgC = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (s, e) => s + e.value.carbs) / logged.length;
    final avgF = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (s, e) => s + e.value.fat) / logged.length;
    final onTarget = logged
        .where(
          (e) =>
              (e.value.calories - p.goals.calories).abs() <=
              p.goals.calories * 0.1,
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 7, label: Text('7 days')),
                ButtonSegment(value: 14, label: Text('14 days')),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dashed line = daily goal (${fmt(p.goals.calories)} kcal)',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SimpleBarChart(
                    values: values,
                    labels: labels,
                    goal: p.goals.calories,
                    highlightIndex: values.length - 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    label: 'Daily average',
                    value: fmt(avg),
                    unit: 'kcal',
                    icon: Icons.bar_chart,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Tile(
                    label: 'Days on target',
                    value: '$onTarget/${logged.length}',
                    unit: '±10%',
                    icon: Icons.track_changes,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    label: 'Streak',
                    value: '${p.streak}',
                    unit: 'days',
                    icon: Icons.local_fire_department,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Tile(
                    label: 'Days logged',
                    value: '${logged.length}',
                    unit: 'of $_range',
                    icon: Icons.event_available,
                    color: AppColors.protein,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average macros',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _MacroSplit(p: avgP, c: avgC, f: avgF),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: MacroBar(
                          label: 'Protein',
                          value: avgP,
                          goal: p.goals.protein,
                          color: AppColors.protein,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MacroBar(
                          label: 'Carbs',
                          value: avgC,
                          goal: p.goals.carbs,
                          color: AppColors.carbs,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MacroBar(
                          label: 'Fat',
                          value: avgF,
                          goal: p.goals.fat,
                          color: AppColors.fat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _WeightCard(p: p),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _Tile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MacroSplit extends StatelessWidget {
  final double p, c, f;
  const _MacroSplit({required this.p, required this.c, required this.f});

  @override
  Widget build(BuildContext context) {
    final pk = p * 4, ck = c * 4, fk = f * 9;
    final total = pk + ck + fk;
    if (total <= 0) {
      return const Text(
        'Log some food to see your macro split.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    int pct(double v) => (v / total * 100).round();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(
                  flex: (pk * 100).round().clamp(1, 1 << 30),
                  child: Container(color: AppColors.protein),
                ),
                Expanded(
                  flex: (ck * 100).round().clamp(1, 1 << 30),
                  child: Container(color: AppColors.carbs),
                ),
                Expanded(
                  flex: (fk * 100).round().clamp(1, 1 << 30),
                  child: Container(color: AppColors.fat),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legend(AppColors.protein, 'Protein ${pct(pk)}%'),
            _legend(AppColors.carbs, 'Carbs ${pct(ck)}%'),
            _legend(AppColors.fat, 'Fat ${pct(fk)}%'),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color c, String t) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        t,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _WeightCard extends StatelessWidget {
  final TrackerProvider p;
  const _WeightCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final w = p.weights;
    final recent = w.length > 30 ? w.sublist(w.length - 30) : w;
    final change = w.length >= 2 ? w.last.kg - w.first.kg : 0.0;
    final target = p.goals.targetWeight;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_weight_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Weight',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => _logWeight(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (w.isEmpty)
            const EmptyHint(
              icon: Icons.scale_outlined,
              text: 'Log your weight to track your progress over time.',
            )
          else ...[
            Row(
              children: [
                Text(
                  '${fmt(w.last.kg, 1)} kg',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                if (w.length >= 2)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (change <= 0 ? AppColors.primary : AppColors.accent)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${change > 0 ? '+' : ''}${fmt(change, 1)} kg',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: change <= 0
                            ? AppColors.primary
                            : AppColors.accent,
                      ),
                    ),
                  ),
                const Spacer(),
                if (target != null)
                  Text(
                    'Target ${fmt(target, 1)} kg',
                    style: const TextStyle(color: AppColors.muted),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(
                  recent.map((e) => e.kg).toList(),
                  target: target,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _short(recent.first.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                Text(
                  _short(recent.last.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
            const Divider(height: 24),
            for (final e in w.reversed.take(5))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${fmt(e.kg, 1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_short(e.date)),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.muted,
                  ),
                  onPressed: () => p.deleteWeight(e.date),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _short(String key) {
    final d = parseDateKey(key);
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _logWeight(BuildContext context) async {
    final ctrl = TextEditingController(
      text: p.latestWeight == null ? '' : fmt(p.latestWeight!, 1),
    );
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log weight'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            suffixText: 'kg',
            fillColor: AppColors.bg,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v != null && v > 20 && v < 400) await p.logWeight(v);
  }
}
