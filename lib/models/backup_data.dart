import 'venta.dart';
import 'gasto.dart';
import 'trabajo.dart';
import 'empleado.dart';
import 'pago_semanal.dart';
import 'visita_agenda.dart';
import 'usuario.dart';

class BackupData {
  List<Venta> ventas;
  List<Gasto> gastos;
  List<Trabajo> trabajos;
  List<Empleado> empleados;
  List<PagoSemanal> pagosSemanales;
  List<VisitaAgenda> agenda;
  List<Usuario> usuarios;

  BackupData({
    List<Venta>? ventas,
    List<Gasto>? gastos,
    List<Trabajo>? trabajos,
    List<Empleado>? empleados,
    List<PagoSemanal>? pagosSemanales,
    List<VisitaAgenda>? agenda,
    List<Usuario>? usuarios,
  })  : ventas = ventas ?? [],
        gastos = gastos ?? [],
        trabajos = trabajos ?? [],
        empleados = empleados ?? [],
        pagosSemanales = pagosSemanales ?? [],
        agenda = agenda ?? [],
        usuarios = usuarios ?? [];

  factory BackupData.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      if (raw is List) {
        return raw.map((item) => fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    }

    return BackupData(
      ventas: parseList(json['ventas'] ?? json['Ventas'], Venta.fromJson),
      gastos: parseList(json['gastos'] ?? json['Gastos'], Gasto.fromJson),
      trabajos: parseList(json['trabajos'] ?? json['Trabajos'], Trabajo.fromJson),
      empleados: parseList(json['empleados'] ?? json['Empleados'], Empleado.fromJson),
      pagosSemanales: parseList(json['pagosSemanales'] ?? json['PagosSemanales'], PagoSemanal.fromJson),
      agenda: parseList(json['agenda'] ?? json['Agenda'], VisitaAgenda.fromJson),
      usuarios: parseList(json['usuarios'] ?? json['Usuarios'], Usuario.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'ventas': ventas.map((v) => v.toJson()).toList(),
        'gastos': gastos.map((g) => g.toJson()).toList(),
        'trabajos': trabajos.map((t) => t.toJson()).toList(),
        'empleados': empleados.map((e) => e.toJson()).toList(),
        'pagosSemanales': pagosSemanales.map((p) => p.toJson()).toList(),
        'agenda': agenda.map((a) => a.toJson()).toList(),
        'usuarios': usuarios.map((u) => u.toJson()).toList(),
      };
}
