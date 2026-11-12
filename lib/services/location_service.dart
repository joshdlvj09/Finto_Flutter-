// GPS: obtiene la ubicacion actual y abre Google Maps con unas coordenadas
import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'hardware_result.dart';

class LocationService {
  Future<HardwareResult<Position>> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const HardwareResult.fail(
            HardwareStatus.serviceDisabled, 'El GPS está apagado. Actívalo para guardar la ubicación.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const HardwareResult.fail(
            HardwareStatus.denied, 'Sin permiso de ubicación el movimiento se guarda sin mapa.');
      }
      if (permission == LocationPermission.deniedForever) {
        return const HardwareResult.fail(HardwareStatus.deniedForever,
            'El permiso de ubicación está bloqueado. Actívalo en Ajustes.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return HardwareResult.ok(position);
    } on TimeoutException {
      // Si tarda mucho usamos la ultima ubicacion conocida
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return HardwareResult.ok(last);
      return const HardwareResult.fail(
          HardwareStatus.error, 'El GPS tardó demasiado. Intenta en un lugar abierto.');
    } catch (e) {
      return HardwareResult.fail(HardwareStatus.error, 'No se pudo obtener la ubicación: $e');
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  // Abre la app de Google Maps (o el navegador) en las coordenadas guardadas
  Future<bool> openInGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
