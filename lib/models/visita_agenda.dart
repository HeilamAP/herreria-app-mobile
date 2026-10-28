import 'package:intl/intl.dart';
import 'direccion.dart';
import 'marca.dart';

class VisitaAgenda {
  final String id;
  String cliente;
  String fecha; // yyyy-MM-dd
  String hora; // "HH:mm" (24 h). Se aceptan datos viejos tipo "09:00 AM".
  String tipo; // Instalación | Mantenimiento | Reparación | Medir y cotizar | Soldadura | Venta | Otro
  String direccion; // La dirección en una línea (lo que se muestra y se busca en el mapa)
  PartesDireccion? partes; // La misma dirección por partes (null en trabajos de antes del formulario)
  String telefono;
  String notas;
  String estado; // pendiente | completado | cancelado
  String equipoId; // "equipo1" | "equipo2"
  double monto; // Lo que se cobró
  double montoEstimado; // Lo que se piensa cobrar (al agendar)
  String metodoPago; // 'efectivo' | 'transferencia'
  int duracionMin; // Cuánto tarda el trabajo, en minutos (para la vista de horario)
  String notaFinal; // Lo que se anota al terminar (aparte de las notas de cuando se agenda)
  List<String> fotos; // Ids de las fotos guardadas en el teléfono (ver FotoStore)
  // Evidencia (ver Marca): cuándo y dónde llegaron, cobraron y tomaron cada foto.
  Marca? llegada;
  Marca? salida; // al cobrar
  Map<String, Marca> marcasFotos; // id de foto → marca (solo fotos de la cámara)
  // Dónde queda la dirección en el mapa, para comparar con las marcas. Se calcula una vez
  // por dirección (domDireccion es la dirección con la que se calculó).
  double? domLat;
  double? domLng;
  String domDireccion;

  VisitaAgenda({
    required this.id,
    required this.cliente,
    required this.fecha,
    this.hora = '09:00',
    required this.tipo,
    required this.direccion,
    required this.telefono,
    required this.notas,
    required this.estado,
    this.equipoId = 'equipo1',
    this.monto = 0.0,
    this.montoEstimado = 0.0,
    this.metodoPago = 'efectivo',
    this.duracionMin = 60,
    this.notaFinal = '',
    List<String>? fotos,
    this.partes,
    this.llegada,
    this.salida,
    Map<String, Marca>? marcasFotos,
    this.domLat,
    this.domLng,
    this.domDireccion = '',
  })  : fotos = fotos ?? [],
        marcasFotos = marcasFotos ?? {};

  static const maxFotos = 10;

  int get finMinutos => minutosDelDia + duracionMin;

  bool get completado {
    final st = estado.toLowerCase();
    return st == 'completado' || st == 'realizado';
  }

  bool get esVenta => tipo.toLowerCase() == 'venta';

  String get referencias => partes?.referencias.trim() ?? '';

  /// La dirección actual ya está ubicada en el mapa.
  bool get domicilioUbicado => domLat != null && domLng != null && domDireccion == direccion;

  /// Minutos desde medianoche, para ordenar y para el selector de hora.
  int get minutosDelDia => minutosDeHora(hora);

  static int minutosDeHora(String hora) {
    final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(hora);
    if (m == null) return 9 * 60;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ampm = m.group(3)?.toUpperCase();
    if (ampm == 'PM' && h < 12) h += 12;
    if (ampm == 'AM' && h == 12) h = 0;
    return h * 60 + min;
  }

  static String horaDeMinutos(int minutos) =>
      '${(minutos ~/ 60).toString().padLeft(2, '0')}:${(minutos % 60).toString().padLeft(2, '0')}';

  VisitaAgenda copia() => VisitaAgenda.fromJson(toJson());

  factory VisitaAgenda.fromJson(Map<String, dynamic> json) {
    return VisitaAgenda(
      id: json['id'] ?? json['Id'] ?? '',
      cliente: json['cliente'] ?? json['Cliente'] ?? '',
      fecha: json['fecha'] ?? json['Fecha'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      hora: json['hora'] ?? json['Hora'] ?? '09:00',
      tipo: json['tipo'] ?? json['Tipo'] ?? '',
      direccion: json['direccion'] ?? json['Direccion'] ?? '',
      telefono: json['telefono'] ?? json['Telefono'] ?? '',
      notas: json['notas'] ?? json['Notas'] ?? '',
      estado: json['estado'] ?? json['Estado'] ?? 'pendiente',
      equipoId: json['equipoId'] ?? json['EquipoId'] ?? 'equipo1',
      monto: (json['monto'] ?? json['Monto'] ?? 0.0).toDouble(),
      montoEstimado: (json['montoEstimado'] ?? json['MontoEstimado'] ?? 0.0).toDouble(),
      metodoPago: json['metodoPago'] ?? json['MetodoPago'] ?? 'efectivo',
      duracionMin: (json['duracionMin'] as num?)?.toInt() ?? 60,
      notaFinal: json['notaFinal'] ?? '',
      fotos: (json['fotos'] as List?)?.map((e) => e.toString()).toList(),
      partes: json['partes'] is Map ? PartesDireccion.fromJson(Map<String, dynamic>.from(json['partes'])) : null,
      llegada: json['llegada'] is Map ? Marca.fromJson(Map<String, dynamic>.from(json['llegada'])) : null,
      salida: json['salida'] is Map ? Marca.fromJson(Map<String, dynamic>.from(json['salida'])) : null,
      marcasFotos: json['marcasFotos'] is Map
          ? {
              for (final e in (json['marcasFotos'] as Map).entries)
                if (e.value is Map) e.key.toString(): Marca.fromJson(Map<String, dynamic>.from(e.value)),
            }
          : null,
      domLat: (json['domLat'] as num?)?.toDouble(),
      domLng: (json['domLng'] as num?)?.toDouble(),
      domDireccion: json['domDireccion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente': cliente,
        'fecha': fecha,
        'hora': hora,
        'tipo': tipo,
        'direccion': direccion,
        'telefono': telefono,
        'notas': notas,
        'estado': estado,
        'equipoId': equipoId,
        'monto': monto,
        'montoEstimado': montoEstimado,
        'metodoPago': metodoPago,
        'duracionMin': duracionMin,
        'notaFinal': notaFinal,
        'fotos': fotos,
        if (partes != null) 'partes': partes!.toJson(),
        if (llegada != null) 'llegada': llegada!.toJson(),
        if (salida != null) 'salida': salida!.toJson(),
        if (marcasFotos.isNotEmpty) 'marcasFotos': {for (final e in marcasFotos.entries) e.key: e.value.toJson()},
        if (domLat != null) 'domLat': domLat,
        if (domLng != null) 'domLng': domLng,
        if (domDireccion.isNotEmpty) 'domDireccion': domDireccion,
      };
}
