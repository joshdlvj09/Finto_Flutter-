// Repositorio de usuarios locales
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_user.dart';
import 'repository_exception.dart';

abstract class UserRepository {
  Future<AppUser?> findByEmail(String email);
  Future<AppUser?> findById(int id);
  Future<AppUser> create(AppUser user);
  Future<void> update(AppUser user);
  Future<void> delete(int id);
}

class SqliteUserRepository implements UserRepository {
  final AppDatabase _appDb;
  SqliteUserRepository(this._appDb);

  static const _table = 'users';

  @override
  Future<AppUser?> findByEmail(String email) async {
    try {
      final db = await _appDb.database;
      final rows = await db.query(_table,
          where: 'email = ?', whereArgs: [email.trim().toLowerCase()], limit: 1);
      return rows.isEmpty ? null : AppUser.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudo consultar el usuario', e);
    }
  }

  @override
  Future<AppUser?> findById(int id) async {
    try {
      final db = await _appDb.database;
      final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
      return rows.isEmpty ? null : AppUser.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudo consultar el usuario', e);
    }
  }

  @override
  Future<AppUser> create(AppUser user) async {
    try {
      final db = await _appDb.database;
      final id = await db.insert(_table, user.toMap());
      return AppUser.fromMap({...user.toMap(), 'id': id});
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw const RepositoryException('Ya existe una cuenta con ese correo');
      }
      throw RepositoryException('No se pudo crear la cuenta', e);
    }
  }

  @override
  Future<void> update(AppUser user) async {
    try {
      final db = await _appDb.database;
      await db.update(_table, user.toMap(), where: 'id = ?', whereArgs: [user.id]);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudo actualizar la cuenta', e);
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      final db = await _appDb.database;
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudo eliminar la cuenta', e);
    }
  }
}
