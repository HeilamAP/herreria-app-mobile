import 'package:intl/intl.dart';

class VisitaAgenda {
  final String id;
  String cliente;
  String fecha;
  String hora; // e.g. "09:00 AM"
  String tipo;
  String direccion;
  String telefono;
  String notas;
  String estado; // pendiente | completado | cancelado
  String equipoId; // "equipo1" | "equipo2"
  double monto; // Pago o monto cobrado por el trabajo
  String metodoPago; // 'efectivo' | 'transferencia'

  VisitaAgenda({
    required this.id,
    required this.cliente,
    required this.fecha,
    this.hora = '09:00 AM',
    required this.tipo,
    required this.direccion,
    required this.telefono,
    required this.notas,
    required this.estado,
    this.equipoId = 'equipo1',
    this.monto = 0.0,
    this.metodoPago = 'efectivo',
  });

  factory VisitaAgenda.fromJson(Map<String, dynamic> json) {
    return VisitaAgenda(
      id: json['id'] ?? json['Id'] ?? '',
      cliente: json['cliente'] ?? json['Cliente'] ?? '',
      fecha: json['fecha'] ?? json['Fecha'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      hora: json['hora'] ?? json['Hora'] ?? '09:00 AM',
      tipo: json['tipo'] ?? json['Tipo'] ?? '',
      direccion: json['direccion'] ?? json['Direccion'] ?? '',
      telefono: json['telefono'] ?? json['Telefono'] ?? '',
      notas: json['notas'] ?? json['Notas'] ?? '',
      estado: json['estado'] ?? json['Estado'] ?? 'pendiente',
      equipoId: json['equipoId'] ?? json['EquipoId'] ?? 'equipo1',
      monto: (json['monto'] ?? json['Monto'] ?? 0.0).toDouble(),
      metodoPago: json['metodoPago'] ?? json['MetodoPago'] ?? 'efectivo',
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
        'metodoPago': metodoPago,
      };
}
