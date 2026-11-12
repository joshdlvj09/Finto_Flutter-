// Login biometrico (huella / Face ID) con local_auth
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

import 'hardware_result.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<HardwareResult<bool>> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return ok
          ? const HardwareResult.ok(true)
          : const HardwareResult.fail(HardwareStatus.cancelled, 'Autenticación cancelada');
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return const HardwareResult.fail(
              HardwareStatus.unavailable, 'Este dispositivo no tiene sensor biométrico');
        case auth_error.notEnrolled:
        case auth_error.passcodeNotSet:
          return const HardwareResult.fail(HardwareStatus.unavailable,
              'Registra una huella o rostro en los ajustes del teléfono primero');
        case auth_error.lockedOut:
          return const HardwareResult.fail(
              HardwareStatus.denied, 'Demasiados intentos. Espera un momento.');
        case auth_error.permanentlyLockedOut:
          return const HardwareResult.fail(HardwareStatus.deniedForever,
              'Biometría bloqueada. Desbloquea el teléfono con tu PIN y vuelve a intentar.');
        default:
          return HardwareResult.fail(HardwareStatus.error, 'Error biométrico: ${e.message}');
      }
    }
  }
}
