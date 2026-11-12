// Estado de la sesion: registro, login con contrasena, login con huella y perfil
import 'package:flutter/foundation.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/biometric_service.dart';
import '../../services/hardware_result.dart';
import '../../services/password_hasher.dart';
import '../../services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _users;
  final SessionService _session;
  final BiometricService _biometric;
  final PasswordHasher _hasher;

  AuthProvider(this._users, this._session, this._biometric, this._hasher);

  AppUser? _user;
  bool _biometricEnabled = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get biometricEnabled => _biometricEnabled;

  // Al abrir la app: si habia sesion guardada la recuperamos
  Future<bool> restoreSession() async {
    try {
      final id = await _session.getLoggedUserId();
      if (id == null) return false;
      _user = await _users.findById(id);
      await _loadBiometricFlag();
      notifyListeners();
      return _user != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    _validate(name: name, email: email, password: password);
    final salt = _hasher.newSalt();
    final created = await _users.create(AppUser(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: _hasher.hash(password, salt),
      salt: salt,
    ));
    await _startSession(created);
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Escribe tu correo y contraseña');
    }
    final found = await _users.findByEmail(email);
    if (found == null || !_hasher.verify(password, found.salt, found.passwordHash)) {
      throw const AuthException('Correo o contraseña incorrectos');
    }
    await _startSession(found);
  }

  // ---------- Biometria ----------

  // Hay un usuario con huella activada en este telefono?
  Future<bool> canUseBiometricLogin() async {
    final id = await _session.getBiometricUserId();
    return id != null && await _biometric.isAvailable();
  }

  Future<HardwareResult<bool>> loginWithBiometrics() async {
    final id = await _session.getBiometricUserId();
    if (id == null) {
      return const HardwareResult.fail(
          HardwareStatus.unavailable, 'Primero inicia sesión y activa la huella en tu perfil');
    }
    final result = await _biometric.authenticate('Confirma tu identidad para entrar a Finto');
    if (!result.isOk) return result;

    final found = await _users.findById(id);
    if (found == null) {
      await _session.setBiometricUserId(null);
      return const HardwareResult.fail(HardwareStatus.error, 'La cuenta ya no existe');
    }
    await _startSession(found);
    return const HardwareResult.ok(true);
  }

  Future<HardwareResult<bool>> setBiometric(bool enable) async {
    if (_user == null) return const HardwareResult.fail(HardwareStatus.error, 'Sin sesión');
    if (enable) {
      if (!await _biometric.isAvailable()) {
        return const HardwareResult.fail(HardwareStatus.unavailable,
            'Tu teléfono no tiene huella o rostro registrado');
      }
      // Pedimos la huella antes de activarla para confirmar que es el dueno
      final r = await _biometric.authenticate('Confirma para activar el acceso con huella');
      if (!r.isOk) return r;
      await _session.setBiometricUserId(_user!.id);
    } else {
      await _session.setBiometricUserId(null);
    }
    _biometricEnabled = enable;
    notifyListeners();
    return const HardwareResult.ok(true);
  }

  // ---------- Perfil ----------

  Future<void> changePassword(String current, String next) async {
    final u = _user;
    if (u == null) return;
    if (!_hasher.verify(current, u.salt, u.passwordHash)) {
      throw const AuthException('La contraseña actual no es correcta');
    }
    _validate(password: next);
    final salt = _hasher.newSalt();
    final updated = u.copyWith(passwordHash: _hasher.hash(next, salt), salt: salt);
    await _users.update(updated);
    _user = updated;
  }

  Future<void> deleteAccount() async {
    final u = _user;
    if (u == null) return;
    await _users.delete(u.id!); // los movimientos se borran por ON DELETE CASCADE
    if (await _session.getBiometricUserId() == u.id) {
      await _session.setBiometricUserId(null);
    }
    await logout();
  }

  Future<void> logout() async {
    await _session.clearSession();
    _user = null;
    notifyListeners();
  }

  // ---------- Privados ----------

  Future<void> _startSession(AppUser u) async {
    _user = u;
    await _session.saveLoggedUserId(u.id!);
    await _loadBiometricFlag();
    notifyListeners();
  }

  Future<void> _loadBiometricFlag() async {
    _biometricEnabled = _user != null && await _session.getBiometricUserId() == _user!.id;
  }

  void _validate({String? name, String? email, String? password}) {
    if (name != null && name.trim().length < 2) {
      throw const AuthException('Escribe tu nombre');
    }
    if (email != null && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw const AuthException('El correo no es válido');
    }
    if (password != null && password.length < 6) {
      throw const AuthException('La contraseña debe tener al menos 6 caracteres');
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
