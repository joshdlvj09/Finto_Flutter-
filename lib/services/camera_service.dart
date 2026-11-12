// Camara y galeria: toma o elige la foto del ticket y la copia a la carpeta de la app
// (la ruta que devuelve image_picker es temporal y el sistema la puede borrar).
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hardware_result.dart';

class CameraService {
  final ImagePicker _picker;
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<HardwareResult<String>> takePhoto() => _pick(ImageSource.camera);
  Future<HardwareResult<String>> pickFromGallery() => _pick(ImageSource.gallery);

  Future<HardwareResult<String>> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file == null) {
        return const HardwareResult.fail(HardwareStatus.cancelled, 'No se eligió ninguna foto');
      }
      final savedPath = await _saveToAppFolder(file);
      return HardwareResult.ok(savedPath);
    } on PlatformException catch (e) {
      // image_picker avisa con estos codigos cuando el usuario nego el permiso
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        return const HardwareResult.fail(
          HardwareStatus.deniedForever,
          'Finto no tiene permiso para usar la cámara o las fotos. Actívalo en Ajustes.',
        );
      }
      if (e.code == 'no_available_camera') {
        return const HardwareResult.fail(
            HardwareStatus.unavailable, 'Este dispositivo no tiene cámara disponible');
      }
      return HardwareResult.fail(HardwareStatus.error, 'Error con la cámara: ${e.message}');
    } catch (e) {
      return HardwareResult.fail(HardwareStatus.error, 'No se pudo guardar la foto: $e');
    }
  }

  Future<String> _saveToAppFolder(XFile file) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(docs.path, 'tickets'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final name = 'ticket_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final target = p.join(folder.path, name);
    await File(file.path).copy(target);
    return target;
  }

  // Borra una foto que ya no se usa. Si falla no pasa nada grave.
  Future<void> deleteImage(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
