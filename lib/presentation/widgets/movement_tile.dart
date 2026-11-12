// Fila de la lista de movimientos en Inicio
import 'package:flutter/material.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/format.dart';
import '../../data/models/movement.dart';
import 'invoice_badge.dart';
import 'movement_visual.dart';

class MovementTile extends StatelessWidget {
  final Movement movement;
  final VoidCallback onTap;

  const MovementTile({super.key, required this.movement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = Categories.byId(movement.category);
    final color = movement.isIncome ? AppColors.income : AppColors.expense;
    final m = movement.metadata;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MovementVisual(movement: movement),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.description.isEmpty ? category.label : movement.description,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${category.label} · ${Format.dateLabel(movement.date)}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        if (m.hasLocation)
                          const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                        if (m.hasImage)
                          const Icon(Icons.photo_outlined, size: 14, color: AppColors.textMuted),
                        if (!movement.isIncome) InvoiceBadge(status: movement.invoice),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${movement.isIncome ? '+' : '-'}${Format.money(movement.amount)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
