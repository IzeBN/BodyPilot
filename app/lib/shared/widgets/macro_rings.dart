import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MacroRings extends StatelessWidget {
  final double caloriesFill;
  final double proteinFill;
  final double carbsFill;
  final double size;

  const MacroRings({
    super.key,
    required this.caloriesFill,
    required this.proteinFill,
    required this.carbsFill,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MacroRingsPainter(
          caloriesFill: caloriesFill,
          proteinFill: proteinFill,
          carbsFill: carbsFill,
        ),
      ),
    );
  }
}

class _MacroRingsPainter extends CustomPainter {
  final double caloriesFill;
  final double proteinFill;
  final double carbsFill;

  _MacroRingsPainter({
    required this.caloriesFill,
    required this.proteinFill,
    required this.carbsFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);

    final radii = [
      size.width / 2 - 4,
      size.width / 2 - 13,
      size.width / 2 - 22,
    ];

    final colors = [
      AppColors.calories,
      AppColors.protein,
      AppColors.carbs,
    ];

    final fills = [caloriesFill, proteinFill, carbsFill];

    for (int i = 0; i < 3; i++) {
      final r = radii[i];
      final rect = Rect.fromCircle(center: center, radius: r);

      // Track
      final trackPaint = Paint()
        ..color = AppColors.surfaceTint
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, r, trackPaint);

      // Fill
      final fillPaint = Paint()
        ..color = colors[i]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweep = fills[i].clamp(0.0, 1.0) * 2 * math.pi;
      // Start at top (-90deg = -pi/2)
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_MacroRingsPainter old) =>
      old.caloriesFill != caloriesFill ||
      old.proteinFill != proteinFill ||
      old.carbsFill != carbsFill;
}
