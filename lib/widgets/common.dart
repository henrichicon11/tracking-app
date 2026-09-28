import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

String fmt(double v, [int decimals = 0]) {
  if (decimals == 0) return v.round().toString();
  final s = v.toStringAsFixed(decimals);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Circular progress ring used for calories.
class RingPainter extends CustomPainter {
  final double progress; // 0..n
  final Color color;
  final Color track;
  final double stroke;
  RingPainter({
    required this.progress,
    required this.color,
    this.track = const Color(0xFFE8EEEA),
    this.stroke = 14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final bg = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * p,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.progress != progress || old.color != color;
}

class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${fmt(value)} / ${fmt(goal)}g',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Simple bar chart using CustomPaint-free widgets.
class SimpleBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double? goal;
  final Color color;
  final double height;
  final int? highlightIndex;
  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.goal,
    this.color = AppColors.primary,
    this.height = 160,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = [...values, goal ?? 0, 1.0].reduce(math.max) * 1.15;
    return SizedBox(
      height: height + 24,
      child: LayoutBuilder(
        builder: (context, c) {
          final goalY = goal == null ? null : height - (goal! / maxV) * height;
          return Stack(
            children: [
              if (goalY != null)
                Positioned(
                  top: goalY,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(
                      (c.maxWidth / 8).floor(),
                      (i) => Expanded(
                        child: Container(
                          height: 1.5,
                          color: i.isEven
                              ? AppColors.accent.withValues(alpha: 0.7)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (i) {
                  final h = (values[i] / maxV) * height;
                  final over = goal != null && values[i] > goal! * 1.05;
                  final hi = highlightIndex == i;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: math.max(h, values[i] > 0 ? 4 : 2),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: values[i] <= 0
                                ? const Color(0xFFE8EEEA)
                                : over
                                ? AppColors.accent
                                : color.withValues(alpha: hi ? 1 : 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 18,
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hi
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: hi ? AppColors.text : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Line chart for weight.
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double? target;
  LineChartPainter(this.values, {this.color = AppColors.primary, this.target});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final all = [...values, if (target != null) target!];
    var minV = all.reduce(math.min);
    var maxV = all.reduce(math.max);
    if ((maxV - minV).abs() < 1) {
      minV -= 1;
      maxV += 1;
    }
    final pad = (maxV - minV) * 0.15;
    minV -= pad;
    maxV += pad;
    double y(double v) =>
        size.height - (v - minV) / (maxV - minV) * size.height;
    double x(int i) => values.length == 1
        ? size.width / 2
        : i / (values.length - 1) * size.width;

    final grid = Paint()
      ..color = const Color(0xFFE8EEEA)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final gy = size.height * i / 3;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), grid);
    }

    if (target != null) {
      final tp = Paint()
        ..color = AppColors.accent
        ..strokeWidth = 1.5;
      final ty = y(target!);
      for (double dx = 0; dx < size.width; dx += 10) {
        canvas.drawLine(Offset(dx, ty), Offset(dx + 5, ty), tp);
      }
    }

    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(x(i), y(values[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fill.moveTo(p.dx, size.height);
        fill.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fill.lineTo(p.dx, p.dy);
      }
    }
    fill.lineTo(x(values.length - 1), size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(x(i), y(values[i])), 4, dot);
      canvas.drawCircle(
        Offset(x(i), y(values[i])),
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) => true;
}

class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.muted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
