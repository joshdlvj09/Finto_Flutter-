// Graficas de Analisis dibujadas con CustomPainter (sin librerias extra)
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/periods.dart';

// ---------------- Barras: ingresos vs gastos ----------------

class IncomeExpenseBarChart extends StatelessWidget {
  final List<Bucket> buckets;
  const IncomeExpenseBarChart({super.key, required this.buckets});

  @override
  Widget build(BuildContext context) {
    // La animacion hace que las barras "crezcan" al cambiar de periodo
    return TweenAnimationBuilder<double>(
      key: ValueKey(buckets.map((b) => '${b.label}${b.totals.income}${b.totals.expenses}').join()),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        height: 180,
        child: CustomPaint(painter: _BarPainter(buckets, t), size: Size.infinite),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<Bucket> buckets;
  final double progress;
  _BarPainter(this.buckets, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 20.0;
    final chartH = size.height - labelHeight;
    final maxValue = buckets
        .map((b) => math.max(b.totals.income, b.totals.expenses))
        .fold<double>(0, math.max);

    // Lineas guia
    final grid = Paint()..color = AppColors.chartGrid..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartH * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (buckets.isEmpty) return;

    final groupW = size.width / buckets.length;
    final barW = math.min(14.0, groupW / 3.2);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      final cx = groupW * i + groupW / 2;

      void bar(double value, double x, Color color) {
        if (maxValue <= 0 || value <= 0) return;
        final h = chartH * (value / maxValue) * progress;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, chartH - h, barW, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, Paint()..color = color);
      }

      bar(b.totals.income, cx - barW - 1, AppColors.chartIncome);
      bar(b.totals.expenses, cx + 1, AppColors.chartExpense);

      textPainter.text = TextSpan(
          text: b.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11));
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, chartH + 4));
    }

    // Valor maximo arriba a la izquierda
    if (maxValue > 0) {
      textPainter.text = TextSpan(
          text: Format.moneyShort(maxValue),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, const Offset(0, 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.progress != progress || old.buckets != buckets;
}

// ---------------- Dona: gastos por categoria ----------------

class CategoryDonutChart extends StatelessWidget {
  final List<CategoryTotal> data;
  final double total;
  const CategoryDonutChart({super.key, required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(data.map((d) => d.amount).join(',')),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        width: 170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: const Size(170, 170), painter: _DonutPainter(data, t)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text(Format.money(total),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategoryTotal> data;
  final double progress;
  _DonutPainter(this.data, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.card;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    var start = -math.pi / 2;
    const gap = 0.03; // pequeno espacio entre segmentos
    for (final d in data) {
      final sweep = (d.percent / 100) * math.pi * 2 * progress;
      if (sweep <= gap) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = d.category.color;
      canvas.drawArc(rect, start, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress || old.data != data;
}
