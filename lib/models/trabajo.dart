import 'package:intl/intl.dart';

class Trabajo {
  final String id;
  String fecha;
  String cliente;
  String direccion;
  String descripcion;
  List<String> empleadoIds;
  double monto;
  String equipoId; // "equipo1" | "equipo2"

  Trabajo({
    required this.id,
    required this.fecha,
    required this.cliente,
    required this.direccion,
    required this.descripcion,
    required this.empleadoIds,
    required this.monto,
    this.equipoId = 'equipo1',
  });

  factory Trabajo.fromJson(Map<String, dynamic> json) {
    var rawList = json['empleadoIds'] ?? json['EmpleadoIds'];
    List<String> empIds = [];
    if (rawList is List) {
      empIds = rawList.map((e) => e.toString()).toList();
    }

    return Trabajo(
      id: json['id'] ?? json['Id'] ?? '',
      fecha: json['fecha'] ?? json['Fecha'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      cliente: json['cliente'] ?? json['Cliente'] ?? '',
      direccion: json['direccion'] ?? json['Direccion'] ?? '',
      descripcion: json['descripcion'] ?? json['Descripcion'] ?? '',
      empleadoIds: empIds,
      monto: (json['monto'] ?? json['Monto'] ?? 0.0).toDouble(),
      equipoId: json['equipoId'] ?? json['EquipoId'] ?? 'equipo1',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha,
        'cliente': cliente,
        'direccion': direccion,
        'descripcion': descripcion,
        'empleadoIds': empleadoIds,
        'monto': monto,
        'equipoId': equipoId,
      };
}
