import 'package:intl/intl.dart';

class Gasto {
  final String id;
  String fecha;
  String descripcion;
  String categoria; // material, herramienta, transporte, otro
  double monto;
  String equipoId; // "equipo1" | "equipo2"

  Gasto({
    required this.id,
    required this.fecha,
    required this.descripcion,
    this.categoria = '',
    required this.monto,
    this.equipoId = 'equipo1',
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id'] ?? json['Id'] ?? '',
      fecha: json['fecha'] ?? json['Fecha'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      descripcion: json['descripcion'] ?? json['Descripcion'] ?? '',
      categoria: json['categoria'] ?? json['Categoria'] ?? 'material',
      monto: (json['monto'] ?? json['Monto'] ?? 0.0).toDouble(),
      equipoId: json['equipoId'] ?? json['EquipoId'] ?? 'equipo1',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha,
        'descripcion': descripcion,
        'categoria': categoria,
        'monto': monto,
        'equipoId': equipoId,
      };
}
