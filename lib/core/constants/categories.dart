// Catalogo de categorias para clasificar gastos e ingresos.
// Cada categoria tiene un color fijo para las graficas.
import 'package:flutter/material.dart';

class MovementCategory {
  final String id;
  final String label;
  final IconData icon;
  final String type; // 'gasto', 'ingreso' o 'ambos'
  final Color color;

  const MovementCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
    required this.color,
  });

  bool fitsType(String txType) => type == txType || type == 'ambos';
}

class Categories {
  Categories._();

  static const all = <MovementCategory>[
    MovementCategory(id: 'comida', label: 'Comidas', icon: Icons.fastfood_outlined, type: 'gasto', color: Color(0xFF3987E5)),
    MovementCategory(id: 'postres', label: 'Postres / Café', icon: Icons.icecream_outlined, type: 'gasto', color: Color(0xFFD95926)),
    MovementCategory(id: 'suscripciones', label: 'Suscripciones', icon: Icons.movie_outlined, type: 'gasto', color: Color(0xFF199E70)),
    MovementCategory(id: 'transporte', label: 'Transporte', icon: Icons.directions_car_outlined, type: 'gasto', color: Color(0xFFC98500)),
    MovementCategory(id: 'supermercado', label: 'Super', icon: Icons.shopping_cart_outlined, type: 'gasto', color: Color(0xFFD55181)),
    MovementCategory(id: 'salud', label: 'Salud', icon: Icons.medical_services_outlined, type: 'gasto', color: Color(0xFF008300)),
    MovementCategory(id: 'ocio', label: 'Ocio / Salidas', icon: Icons.sports_esports_outlined, type: 'gasto', color: Color(0xFF9085E9)),
    MovementCategory(id: 'nomina', label: 'Nómina', icon: Icons.payments_outlined, type: 'ingreso', color: Color(0xFF3987E5)),
    MovementCategory(id: 'otros', label: 'Otros', icon: Icons.more_horiz, type: 'ambos', color: Color(0xFFE66767)),
  ];

  // Busca una categoria por id; si no existe regresa "Otros"
  static MovementCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);

  static List<MovementCategory> forType(String txType) =>
      all.where((c) => c.fitsType(txType)).toList();
}
