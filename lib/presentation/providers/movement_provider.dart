// Estado de los movimientos del usuario. Las pantallas leen de aqui y
// este provider habla con el repositorio (SQLite).
import 'package:flutter/foundation.dart';

import '../../core/utils/periods.dart';
import '../../data/models/movement.dart';
import '../../data/repositories/movement_repository.dart';
import '../../services/camera_service.dart';

class MovementProvider extends ChangeNotifier {
  final MovementRepository _repo;
  final CameraService _camera;

  MovementProvider(this._repo, this._camera);

  int? _userId;
  List<Movement> _movements = [];

  List<Movement> get movements => List.unmodifiable(_movements);
  Totals get totals => Periods.totals(_movements);

  Movement? byId(int id) {
    for (final m in _movements) {
      if (m.id == id) return m;
    }
    return null;
  }

  // Lo usa el FutureBuilder de Inicio. Si falla, el error llega al builder.
  Future<List<Movement>> load(int userId) async {
    _userId = userId;
    _movements = await _repo.getAll(userId);
    notifyListeners();
    return _movements;
  }

  Future<void> add(Movement m) async {
    final saved = await _repo.insert(m);
    _movements = [saved, ..._movements]..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addMany(List<Movement> list) async {
    await _repo.insertMany(list);
    if (_userId != null) await load(_userId!);
  }

  Future<void> update(Movement m, {String? oldImagePath}) async {
    await _repo.update(m);
    // Si cambio la foto borramos la anterior para no llenar el telefono
    if (oldImagePath != null && oldImagePath != m.metadata.imagePath) {
      await _camera.deleteImage(oldImagePath);
    }
    _movements = _movements.map((e) => e.id == m.id ? m : e).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> delete(Movement m) async {
    await _repo.delete(m.id!);
    await _camera.deleteImage(m.metadata.imagePath);
    _movements = _movements.where((e) => e.id != m.id).toList();
    notifyListeners();
  }

  Future<void> resetAll() async {
    if (_userId == null) return;
    for (final m in _movements) {
      await _camera.deleteImage(m.metadata.imagePath);
    }
    await _repo.deleteAllForUser(_userId!);
    _movements = [];
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _movements = [];
  }
}
