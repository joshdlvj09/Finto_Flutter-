// Etiqueta de factura: pendiente o realizada (solo gastos)
import 'package:flutter/material.dart';

import '../../core/constants/app_theme.dart';

class InvoiceBadge extends StatelessWidget {
  final String status;
  const InvoiceBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'no') return const SizedBox.shrink();
    final done = status == 'realizada';
    final color = done ? AppColors.income : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        done ? 'Facturado' : 'Factura pendiente',
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
