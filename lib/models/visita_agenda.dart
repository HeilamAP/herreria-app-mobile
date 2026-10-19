import 'package:intl/intl.dart';

class VisitaAgenda {
  final String id;
  String cliente;
  String fecha; // yyyy-MM-dd
  String hora; // "HH:mm" (24 h). Se aceptan datos viejos tipo "09:00 AM".
  String tipo; // Instalación | Mantenimiento | Reparación | Medir y cotizar | Soldadura | Venta | Otro
  String direccion;
  String telefono;
  String notas;
  String estado; // pendiente | completado | cancelado
  String equipoId; // "equipo1" | "equipo2"
  double monto; // Lo que se cobró
  double montoEstimado; // Lo que se piensa cobrar (al agendar)
  String metodoPago; // 'efectivo' | 'transferencia'
  int duracionMin; // Cuánto tarda el trabajo, en minutos (para la vista de horario)

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
  });

  int get finMinutos => minutosDelDia + duracionMin;

  bool get completado {
    final st = estado.toLowerCase();
    return st == 'completado' || st == 'realizado';
  }

  bool get esVenta => tipo.toLowerCase() == 'venta';

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
      };
}
