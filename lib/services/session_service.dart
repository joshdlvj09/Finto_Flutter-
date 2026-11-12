// Sesion y preferencias simples con SharedPreferences.
// Los movimientos van en SQLite; aqui solo guardamos datos pequenos de configuracion.
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kUserId = 'session_user_id';
  static const _kBiometricUserId = 'biometric_user_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<int?> getLoggedUserId() async => (await _prefs).getInt(_kUserId);
  Future<void> saveLoggedUserId(int id) async => (await _prefs).setInt(_kUserId, id);
  Future<void> clearSession() async => (await _prefs).remove(_kUserId);

  // Usuario que activo la huella en este telefono
  Future<int?> getBiometricUserId() async => (await _prefs).getInt(_kBiometricUserId);
  Future<void> setBiometricUserId(int? id) async {
    final prefs = await _prefs;
    if (id == null) {
      await prefs.remove(_kBiometricUserId);
    } else {
      await prefs.setInt(_kBiometricUserId, id);
    }
  }
}
