// Repositorio de movimientos.
// La UI solo conoce la interfaz (MovementRepository); la implementacion con SQLite
// se puede cambiar sin tocar las pantallas (principio de inversion de dependencias).
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/movement.dart';
import 'repository_exception.dart';

abstract class MovementRepository {
  Future<List<Movement>> getAll(int userId);
  Future<Movement> insert(Movement movement);
  Future<void> insertMany(List<Movement> movements);
  Future<void> update(Movement movement);
  Future<void> delete(int id);
  Future<void> deleteAllForUser(int userId);
}

class SqliteMovementRepository implements MovementRepository {
  final AppDatabase _appDb;
  SqliteMovementRepository(this._appDb);

  static const _table = 'movements';

  @override
  Future<List<Movement>> getAll(int userId) async {
    try {
      final db = await _appDb.database;
      final rows = await db.query(
        _table,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      return rows.map(Movement.fromMap).toList();
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudieron leer los movimientos', e);
    }
  }

  @override
  Future<Movement> insert(Movement movement) async {
    try {
      final db = await _appDb.database;
      final id = await db.insert(_table, movement.toMap());
      return movement.copyWith(id: id);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudo guardar el movimiento', e);
    }
  }

  // Varios movimientos en una sola transaccion: o se guardan todos o ninguno
  @override
  Future<void> insertMany(List<Movement> movements) async {
    try {
      final db = await _appDb.database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final m in movements) {
          batch.insert(_table, m.toMap());
        }
        await batch.commit(noResult: true);
      });
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudieron guardar los movimientos', e);
    }
  }

  @override
  Future<void> update(Movement movement) async {
    try {
      final db = await _appDb.database;
      await db.update(_table, movement.toMap(), where: 'id = ?', whereArgs: [movement.id]);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudo actualizar el movimiento', e);
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      final db = await _appDb.database;
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudo eliminar el movimiento', e);
    }
  }

  @override
  Future<void> deleteAllForUser(int userId) async {
    try {
      final db = await _appDb.database;
      await db.delete(_table, where: 'user_id = ?', whereArgs: [userId]);
    } on DatabaseException catch (e) {
      throw RepositoryException('No se pudieron borrar los datos', e);
    }
  }
}
