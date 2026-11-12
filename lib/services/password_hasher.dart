// Hash de contrasenas con sal aleatoria (SHA-256 repetido).
// Asi en la base de datos nunca queda la contrasena real.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const _rounds = 10000;

  String newSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String hash(String password, String salt) {
    List<int> digest = utf8.encode('$salt:$password');
    for (var i = 0; i < _rounds; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return base64UrlEncode(digest);
  }

  bool verify(String password, String salt, String expectedHash) =>
      hash(password, salt) == expectedHash;
}
