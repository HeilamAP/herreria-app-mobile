import 'package:intl/intl.dart';

class PagoSemanal {
  final String id;
  String empleadoId;
  String semana;
  double pagoBase;
  double descuentoPrestamo;
  String motivoPrestamo;
  double extraTrabajos;
  String motivoExtra;
  double ayudaEspecial;
  String motivoAyuda;

  PagoSemanal({
    required this.id,
    required this.empleadoId,
    required this.semana,
    this.pagoBase = 0.0,
    this.descuentoPrestamo = 0.0,
    this.motivoPrestamo = '',
    this.extraTrabajos = 0.0,
    this.motivoExtra = '',
    this.ayudaEspecial = 0.0,
    this.motivoAyuda = '',
  });

  double calcularNeto() {
    return pagoBase + extraTrabajos + ayudaEspecial - descuentoPrestamo;
  }

  factory PagoSemanal.fromJson(Map<String, dynamic> json) {
    return PagoSemanal(
      id: json['id'] ?? json['Id'] ?? '',
      empleadoId: json['empleadoId'] ?? json['EmpleadoId'] ?? '',
      semana: json['semana'] ?? json['Semana'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      pagoBase: (json['pagoBase'] ?? json['PagoBase'] ?? 0.0).toDouble(),
      descuentoPrestamo: (json['descuentoPrestamo'] ?? json['DescuentoPrestamo'] ?? 0.0).toDouble(),
      motivoPrestamo: json['motivoPrestamo'] ?? json['MotivoPrestamo'] ?? '',
      extraTrabajos: (json['extraTrabajos'] ?? json['ExtraTrabajos'] ?? 0.0).toDouble(),
      motivoExtra: json['motivoExtra'] ?? json['MotivoExtra'] ?? '',
      ayudaEspecial: (json['ayudaEspecial'] ?? json['AyudaEspecial'] ?? 0.0).toDouble(),
      motivoAyuda: json['motivoAyuda'] ?? json['MotivoAyuda'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empleadoId': empleadoId,
        'semana': semana,
        'pagoBase': pagoBase,
        'descuentoPrestamo': descuentoPrestamo,
        'motivoPrestamo': motivoPrestamo,
        'extraTrabajos': extraTrabajos,
        'motivoExtra': motivoExtra,
        'ayudaEspecial': ayudaEspecial,
        'motivoAyuda': motivoAyuda,
      };
}
