/// Hora y lugar en que pasó algo en un trabajo ("Llegué", el cobro o una foto).
/// Es la evidencia que ve el administrador. La ubicación puede faltar (sin permiso,
/// sin señal de GPS); la hora siempre está.
class Marca {
  final DateTime hora;
  final double? lat;
  final double? lng;
  final double? precisionM; // radio de error del GPS, en metros
  final bool falsa; // Android avisó que la ubicación la dio una app que la falsea

  const Marca({required this.hora, this.lat, this.lng, this.precisionM, this.falsa = false});

  bool get conGps => lat != null && lng != null;

  /// La misma ubicación con otra hora (p. ej. la hora exacta en que se tomó la foto).
  Marca conHora(DateTime h) => Marca(hora: h, lat: lat, lng: lng, precisionM: precisionM, falsa: falsa);

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        hora: DateTime.tryParse(json['hora'] ?? '') ?? DateTime.now(),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        precisionM: (json['precision'] as num?)?.toDouble(),
        falsa: json['falsa'] == true,
      );

  Map<String, dynamic> toJson() => {
        'hora': hora.toIso8601String(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (precisionM != null) 'precision': precisionM,
        if (falsa) 'falsa': true,
      };
}
