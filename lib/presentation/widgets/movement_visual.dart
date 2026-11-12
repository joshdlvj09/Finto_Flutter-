// Imagen del movimiento: la foto del ticket si tiene, si no el icono de la categoria.
// Va dentro de un Hero para animar el paso de la lista al detalle.
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';
import '../../data/models/movement.dart';

class MovementVisual extends StatelessWidget {
  final Movement movement;
  final double size;
  final double radius;

  const MovementVisual({super.key, required this.movement, this.size = 48, this.radius = 14});

  static String heroTag(int id) => 'movement-visual-$id';

  @override
  Widget build(BuildContext context) {
    final category = Categories.byId(movement.category);
    final path = movement.metadata.imagePath;

    Widget content;
    if (path != null && path.isNotEmpty) {
      content = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Si la foto se borro del telefono mostramos el icono en vez de tronar
        errorBuilder: (_, __, ___) => _icon(category),
      );
    } else {
      content = _icon(category);
    }

    return Hero(
      tag: heroTag(movement.id ?? -1),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: content),
    );
  }

  Widget _icon(MovementCategory c) => Container(
        width: size,
        height: size,
        color: c.color.withValues(alpha: 0.18),
        child: Icon(c.icon, color: c.color, size: size * 0.5),
      );
}
