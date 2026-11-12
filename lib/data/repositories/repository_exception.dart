// Error de la capa de datos con un mensaje que se puede mostrar al usuario
class RepositoryException implements Exception {
  final String message;
  final Object? cause;
  const RepositoryException(this.message, [this.cause]);

  @override
  String toString() => message;
}
