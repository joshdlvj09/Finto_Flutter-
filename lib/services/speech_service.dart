// Dictado por voz: convierte lo que dice el usuario en el texto de la nota
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'hardware_result.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;
  String? _localeId;

  bool get isListening => _speech.isListening;

  // Pide el permiso del microfono y prepara el reconocedor
  Future<HardwareResult<bool>> init({void Function(String message)? onError}) async {
    if (_ready) return const HardwareResult.ok(true);
    try {
      _ready = await _speech.initialize(
        onError: (SpeechRecognitionError e) => onError?.call(_errorText(e.errorMsg)),
      );
      if (!_ready) {
        final hasPermission = await _speech.hasPermission;
        if (!hasPermission) {
          return const HardwareResult.fail(
            HardwareStatus.deniedForever,
            'Finto no tiene permiso para usar el micrófono. Actívalo en Ajustes.',
          );
        }
        return const HardwareResult.fail(
            HardwareStatus.unavailable, 'El dictado por voz no está disponible en este dispositivo');
      }
      _localeId = await _pickSpanishLocale();
      return const HardwareResult.ok(true);
    } catch (e) {
      return HardwareResult.fail(HardwareStatus.error, 'No se pudo iniciar el dictado: $e');
    }
  }

  Future<String?> _pickSpanishLocale() async {
    try {
      final locales = await _speech.locales();
      for (final wanted in ['es_MX', 'es-MX', 'es_US', 'es_ES']) {
        if (locales.any((l) => l.localeId == wanted)) return wanted;
      }
      final anySpanish = locales.where((l) => l.localeId.startsWith('es'));
      return anySpanish.isEmpty ? null : anySpanish.first.localeId;
    } catch (_) {
      return null;
    }
  }

  // onText recibe el texto parcial mientras habla y el final cuando termina
  Future<void> start({required void Function(String text, bool isFinal) onText}) async {
    await _speech.listen(
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      localeId: _localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  String _errorText(String code) {
    switch (code) {
      case 'error_no_match':
      case 'error_speech_timeout':
        return 'No te escuché, intenta otra vez';
      case 'error_network':
        return 'El dictado necesita internet en este dispositivo';
      case 'error_permission':
      case 'error_insufficient_permissions':
        return 'Falta el permiso del micrófono';
      default:
        return 'Error en el dictado ($code)';
    }
  }
}
