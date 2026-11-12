// Metadatos de un movimiento: foto del ticket y ubicacion GPS.
// Se guardan en SQLite como un texto JSON (columna "metadata").
import 'dart:convert';

class EntryMetadata {
  final String? imagePath;
  final double? latitude;
  final double? longitude;

  const EntryMetadata({this.imagePath, this.latitude, this.longitude});

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  EntryMetadata copyWith({
    String? imagePath,
    double? latitude,
    double? longitude,
    bool clearImage = false,
    bool clearLocation = false,
  }) {
    return EntryMetadata(
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
    );
  }

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory EntryMetadata.fromJson(Map<String, dynamic> json) => EntryMetadata(
        imagePath: json['imagePath'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  String encode() => jsonEncode(toJson());

  // Si el texto viene vacio o roto regresamos metadatos vacios en vez de tronar
  static EntryMetadata decode(String? source) {
    if (source == null || source.isEmpty) return const EntryMetadata();
    try {
      return EntryMetadata.fromJson(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return const EntryMetadata();
    }
  }
}
