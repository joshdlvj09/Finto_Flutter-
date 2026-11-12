// Resultado comun para los servicios de hardware.
// Asi la UI sabe si fue exito, si el usuario nego el permiso, etc., sin manejar excepciones.
enum HardwareStatus {
  ok,
  cancelled, // el usuario cerro la camara / galeria sin elegir nada
  denied, // permiso negado (se puede volver a pedir)
  deniedForever, // permiso negado para siempre -> hay que abrir Ajustes
  serviceDisabled, // por ejemplo el GPS apagado
  unavailable, // el dispositivo no tiene el sensor
  error,
}

class HardwareResult<T> {
  final HardwareStatus status;
  final T? data;
  final String? message;

  const HardwareResult._(this.status, this.data, this.message);

  const HardwareResult.ok(T value) : this._(HardwareStatus.ok, value, null);
  const HardwareResult.fail(HardwareStatus status, String message) : this._(status, null, message);

  bool get isOk => status == HardwareStatus.ok;
  bool get needsSettings => status == HardwareStatus.deniedForever;
}
