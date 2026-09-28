import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum GoalType { lose, maintain, gain }

extension GoalTypeX on GoalType {
  String get label => switch (this) {
    GoalType.lose => 'Lose weight',
    GoalType.maintain => 'Maintain',
    GoalType.gain => 'Build muscle',
  };
  double get adjust => switch (this) {
    GoalType.lose => -500,
    GoalType.maintain => 0,
    GoalType.gain => 300,
  };
}

/// Reusable form that computes calorie + macro goals.
class GoalCalculatorForm extends StatefulWidget {
  final void Function(UserGoals goals, double weightKg) onResult;
  final String buttonText;
  final UserGoals? initial;
  final double? initialWeight;
  const GoalCalculatorForm({
    super.key,
    required this.onResult,
    this.buttonText = 'Calculate goals',
    this.initial,
    this.initialWeight,
  });

  @override
  State<GoalCalculatorForm> createState() => _GoalCalculatorFormState();
}

class _GoalCalculatorFormState extends State<GoalCalculatorForm> {
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  GoalType _goal = GoalType.lose;
  final _age = TextEditingController(text: '30');
  final _height = TextEditingController(text: '175');
  late final _weight = TextEditingController(
    text: widget.initialWeight == null ? '75' : fmt(widget.initialWeight!, 1),
  );
  late final _target = TextEditingController(
    text: widget.initial?.targetWeight == null
        ? ''
        : fmt(widget.initial!.targetWeight!, 1),
  );

  @override
  void dispose() {
    for (final c in [_age, _height, _weight, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  UserGoals? _compute() {
    final age = int.tryParse(_age.text.trim());
    final h = double.tryParse(_height.text.trim());
    final w = double.tryParse(_weight.text.trim());
    if (age == null || h == null || w == null) return null;
    final tdee = calculateTdee(
      sex: _sex,
      age: age,
      heightCm: h,
      weightKg: w,
      activity: _activity,
    );
    final kcal = (tdee + _goal.adjust).clamp(1200, 6000).roundToDouble();
    final protein = (w * (_goal == GoalType.maintain ? 1.6 : 2.0))
        .roundToDouble();
    final fat = (kcal * 0.27 / 9).roundToDouble();
    final carbs = ((kcal - protein * 4 - fat * 9) / 4)
        .clamp(50, 1000)
        .roundToDouble();
    return UserGoals(
      calories: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      waterMl: (w * 35 / 250).round() * 250.0,
      targetWeight: double.tryParse(_target.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _compute();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<Sex>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: Sex.male,
              label: Text('Male'),
              icon: Icon(Icons.male),
            ),
            ButtonSegment(
              value: Sex.female,
              label: Text('Female'),
              icon: Icon(Icons.female),
            ),
          ],
          selected: {_sex},
          onSelectionChanged: (s) => setState(() => _sex = s.first),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _num(_age, 'Age', 'yrs')),
            const SizedBox(width: 10),
            Expanded(child: _num(_height, 'Height', 'cm')),
            const SizedBox(width: 10),
            Expanded(child: _num(_weight, 'Weight', 'kg')),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ActivityLevel>(
          initialValue: _activity,
          decoration: const InputDecoration(labelText: 'Activity level'),
          items: ActivityLevel.values
              .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
              .toList(),
          onChanged: (v) => setState(() => _activity = v ?? _activity),
        ),
        const SizedBox(height: 12),
        SegmentedButton<GoalType>(
          showSelectedIcon: false,
          segments: GoalType.values
              .map((g) => ButtonSegment(value: g, label: Text(g.label)))
              .toList(),
          selected: {_goal},
          onSelectionChanged: (s) => setState(() => _goal = s.first),
        ),
        const SizedBox(height: 12),
        _num(_target, 'Target weight (optional)', 'kg'),
        const SizedBox(height: 16),
        if (preview != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.accent.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${fmt(preview.calories)} kcal / day',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Protein ${fmt(preview.protein)}g · Carbs ${fmt(preview.carbs)}g · Fat ${fmt(preview.fat)}g',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: preview == null
              ? null
              : () => widget.onResult(
                  preview,
                  double.tryParse(_weight.text.trim()) ?? 0,
                ),
          child: Text(widget.buttonText),
        ),
      ],
    );
  }

  Widget _num(TextEditingController c, String label, String suffix) =>
      TextField(
        controller: c,
        onChanged: (_) => setState(() {}),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      );
}
