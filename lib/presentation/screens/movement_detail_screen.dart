// Detalle de un movimiento: foto (con Hero), datos, y mapa con la ubicacion guardada
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/format.dart';
import '../../data/models/movement.dart';
import '../../data/repositories/repository_exception.dart';
import '../../services/location_service.dart';
import '../providers/movement_provider.dart';
import '../widgets/hardware_feedback.dart';
import '../widgets/invoice_badge.dart';
import '../widgets/movement_visual.dart';

class MovementDetailScreen extends StatelessWidget {
  final int movementId;
  const MovementDetailScreen({super.key, required this.movementId});

  @override
  Widget build(BuildContext context) {
    final movement = context.watch<MovementProvider>().byId(movementId);

    // Si se elimino mientras estabamos aqui
    if (movement == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Este movimiento ya no existe')),
      );
    }

    final category = Categories.byId(movement.category);
    final color = movement.isIncome ? AppColors.income : AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(movement.isIncome ? 'Ingreso' : 'Gasto'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.form, arguments: movement.id),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline, color: AppColors.expense),
            onPressed: () => _confirmDelete(context, movement),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero: la misma imagen/icono de la lista "vuela" hasta aqui
          Center(
            child: GestureDetector(
              onTap: movement.metadata.hasImage ? () => _openPhoto(context, movement) : null,
              child: MovementVisual(
                movement: movement,
                size: movement.metadata.hasImage ? MediaQuery.of(context).size.width - 32 : 110,
                radius: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${movement.isIncome ? '+' : '-'}${Format.money(movement.amount)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          if (movement.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(movement.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _row(category.icon, 'Categoría', category.label, iconColor: category.color),
                _row(Icons.event_outlined, 'Fecha', Format.fullDate(movement.date)),
                if (!movement.isIncome)
                  ListTile(
                    leading: const Icon(Icons.receipt_outlined, color: AppColors.secondary),
                    title: const Text('Factura', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    subtitle: movement.invoice == 'no'
                        ? const Text('No necesita', style: TextStyle(color: AppColors.textPrimary))
                        : Align(alignment: Alignment.centerLeft, child: InvoiceBadge(status: movement.invoice)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _LocationSection(movement: movement),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? iconColor}) => ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.secondary),
        title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        subtitle: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      );

  void _openPhoto(BuildContext context, Movement m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(child: Image.file(File(m.metadata.imagePath!))),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Movement m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('¿Eliminar movimiento?'),
        content: const Text('No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      // Primero salimos del detalle para que no se dibuje un movimiento borrado
      final provider = context.read<MovementProvider>();
      Navigator.pop(context);
      await provider.delete(m);
    } on RepositoryException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }
}

// Mapa interactivo (OpenStreetMap) + boton para abrir Google Maps
class _LocationSection extends StatelessWidget {
  final Movement movement;
  const _LocationSection({required this.movement});

  @override
  Widget build(BuildContext context) {
    final meta = movement.metadata;
    if (!meta.hasLocation) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.location_off_outlined, color: AppColors.textMuted),
          title: Text('Sin ubicación', style: TextStyle(color: AppColors.textPrimary)),
          subtitle: Text('Este movimiento se guardó sin GPS',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final point = LatLng(meta.latitude!, meta.longitude!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 16),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.josh.finto_flutter',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_pin, color: AppColors.primary, size: 44),
                  ),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${meta.latitude!.toStringAsFixed(5)}, ${meta.longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final opened = await context
                        .read<LocationService>()
                        .openInGoogleMaps(meta.latitude!, meta.longitude!);
                    if (!opened && context.mounted) {
                      showMessage(context, 'No se pudo abrir Google Maps');
                    }
                  },
                  icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                  label: const Text('Google Maps', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
