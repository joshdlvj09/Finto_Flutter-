// Muestra el resultado de un servicio de hardware al usuario.
// Si el permiso esta bloqueado agrega un boton para abrir los Ajustes.
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/hardware_result.dart';

void showHardwareError(BuildContext context, HardwareResult result) {
  if (result.isOk || result.status == HardwareStatus.cancelled) return;

  SnackBarAction? action;
  if (result.status == HardwareStatus.deniedForever) {
    action = SnackBarAction(label: 'Ajustes', onPressed: () => Geolocator.openAppSettings());
  } else if (result.status == HardwareStatus.serviceDisabled) {
    action = SnackBarAction(label: 'Activar', onPressed: () => Geolocator.openLocationSettings());
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(result.message ?? 'Ocurrió un error'),
      action: action,
      duration: const Duration(seconds: 4),
    ));
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
