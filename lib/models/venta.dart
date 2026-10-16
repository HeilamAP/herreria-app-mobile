import 'package:intl/intl.dart';

class Venta {
  final String id;
  String fecha;
  String cliente;
  String tipo; // servicio | reventa
  String descripcion;
  double montoVenta;
  double costoCompra;
  String equipoId; // "equipo1" | "equipo2"

  Venta({
    required this.id,
    required this.fecha,
    required this.cliente,
    required this.tipo,
    required this.descripcion,
    required this.montoVenta,
    required this.costoCompra,
    this.equipoId = 'equipo1',
  });

  double calcularGanancia() {
    return montoVenta - costoCompra;
  }

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] ?? json['Id'] ?? '',
      fecha: json['fecha'] ?? json['Fecha'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      cliente: json['cliente'] ?? json['Cliente'] ?? '',
      tipo: json['tipo'] ?? json['Tipo'] ?? 'servicio',
      descripcion: json['descripcion'] ?? json['Descripcion'] ?? '',
      montoVenta: (json['montoVenta'] ?? json['MontoVenta'] ?? 0.0).toDouble(),
      costoCompra: (json['costoCompra'] ?? json['CostoCompra'] ?? 0.0).toDouble(),
      equipoId: json['equipoId'] ?? json['EquipoId'] ?? 'equipo1',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha,
        'cliente': cliente,
        'tipo': tipo,
        'descripcion': descripcion,
        'montoVenta': montoVenta,
        'costoCompra': costoCompra,
        'equipoId': equipoId,
      };
}
