import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/backup_data.dart';
import '../models/empleado.dart';
import '../models/usuario.dart';
import '../models/visita_agenda.dart';
import 'seguridad.dart';

/// Guarda todos los datos como un JSON en SharedPreferences.
/// Funciona igual en Android, iOS y en la versión web (localStorage),
/// así que lo capturado desde el iPhone ya no se pierde al recargar.
class StorageService extends ChangeNotifier {
  static const _clave = 'ayoy_datos_v2';

  BackupData _data = BackupData();
  SharedPreferences? _prefs;

  BackupData get data => _data;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final jsonString = _prefs!.getString(_clave);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          _data = BackupData.fromJson(jsonDecode(jsonString));
        } catch (e) {
          // No sobrescribir datos que no se pudieron leer: se apartan antes de empezar de nuevo.
          await _prefs!.setString('${_clave}_ilegible_${DateTime.now().millisecondsSinceEpoch}', jsonString);
          if (kDebugMode) print('Datos ilegibles, se apartaron: $e');
          _data = BackupData();
          _seedDefaultData();
        }
      } else {
        _data = BackupData();
        _seedDefaultData();
      }
      _seedDefaultUsers();
      await saveData();
    } catch (e) {
      if (kDebugMode) {
        print('Error initialising storage: $e');
      }
      _data = BackupData();
      _seedDefaultData();
      _seedDefaultUsers();
    }
    notifyListeners();
  }

  Future<void> saveData() async {
    try {
      await _prefs?.setString(_clave, jsonEncode(_data.toJson()));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data: $e');
      }
    }
    notifyListeners();
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert(_data.toJson());
  }

  bool importJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        _data = BackupData.fromJson(decoded);
        _seedDefaultUsers();
        saveData();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error importing JSON: $e');
      }
    }
    return false;
  }

  String exportMonthlyCsv(int year, int month) {
    final sb = StringBuffer();
    // UTF-8 BOM
    sb.write('﻿');

    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(DateTime(year, month, 1));

    sb.writeln('RESUMEN MENSUAL DE EMPRESA - ${monthName.toUpperCase()}');
    sb.writeln('Fecha de emisión: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    sb.writeln();

    // Ventas
    final ventas = _data.ventas.where((v) => v.fecha.startsWith(prefix)).toList();
    final totalVentas = ventas.fold<double>(0, (sum, v) => sum + v.montoVenta);
    final totalGananciaVentas = ventas.fold<double>(0, (sum, v) => sum + v.calcularGanancia());
    sb.writeln('=== VENTAS DEL MES (${ventas.length} registros) ===');
    sb.writeln('Fecha,Cliente,Tipo,Descripción,Monto Venta,Costo Compra,Ganancia');
    for (var v in ventas) {
      sb.writeln('"${v.fecha}","${_escapeCsv(v.cliente)}","${v.tipo}","${_escapeCsv(v.descripcion)}",${v.montoVenta.toStringAsFixed(2)},${v.costoCompra.toStringAsFixed(2)},${v.calcularGanancia().toStringAsFixed(2)}');
    }
    sb.writeln('TOTAL VENTAS,,,$totalVentas,,$totalGananciaVentas');
    sb.writeln();

    // Gastos
    final gastos = _data.gastos.where((g) => g.fecha.startsWith(prefix)).toList();
    final totalGastos = gastos.fold<double>(0, (sum, g) => sum + g.monto);
    sb.writeln('=== GASTOS DEL MES (${gastos.length} registros) ===');
    sb.writeln('Fecha,Categoría,Descripción,Monto');
    for (var g in gastos) {
      sb.writeln('"${g.fecha}","${g.categoria}","${_escapeCsv(g.descripcion)}",${g.monto.toStringAsFixed(2)}');
    }
    sb.writeln('TOTAL GASTOS,,,$totalGastos');
    sb.writeln();

    // Trabajos
    final trabajos = _data.trabajos.where((t) => t.fecha.startsWith(prefix)).toList();
    final totalTrabajos = trabajos.fold<double>(0, (sum, t) => sum + t.monto);
    sb.writeln('=== TRABAJOS REALIZADOS (${trabajos.length} registros) ===');
    sb.writeln('Fecha,Cliente,Dirección,Descripción,Monto');
    for (var t in trabajos) {
      sb.writeln('"${t.fecha}","${_escapeCsv(t.cliente)}","${_escapeCsv(t.direccion)}","${_escapeCsv(t.descripcion)}",${t.monto.toStringAsFixed(2)}');
    }
    sb.writeln('TOTAL TRABAJOS,,,$totalTrabajos');
    sb.writeln();

    // Agenda
    final agenda = _data.agenda.where((a) => a.fecha.startsWith(prefix)).toList();
    sb.writeln('=== AGENDA Y VISITAS (${agenda.length} registros) ===');
    sb.writeln('Fecha,Cliente,Tipo,Monto Cobrado,Teléfono,Dirección,Estado,Notas');
    for (var a in agenda) {
      sb.writeln('"${a.fecha}","${_escapeCsv(a.cliente)}","${a.tipo}",${a.monto.toStringAsFixed(2)},"${_escapeCsv(a.telefono)}","${_escapeCsv(a.direccion)}","${a.estado}","${_escapeCsv(a.notas)}"');
    }
    sb.writeln();

    // Pagos Semanales
    final pagos = _data.pagosSemanales.where((p) => p.semana.startsWith(prefix)).toList();
    final totalPagos = pagos.fold<double>(0, (sum, p) => sum + p.calcularNeto());
    sb.writeln('=== NÓMINA Y PAGOS (${pagos.length} registros) ===');
    sb.writeln('Semana,Empleado,Pago Base,Extras,Ayuda Especial,Descuento Préstamo,Total Neto');
    for (var p in pagos) {
      final emp = _data.empleados.firstWhere(
        (e) => e.id == p.empleadoId,
        orElse: () => Empleado(id: p.empleadoId, nombre: p.empleadoId, puesto: ''),
      );
      sb.writeln('"${p.semana}","${_escapeCsv(emp.nombre)}",${p.pagoBase.toStringAsFixed(2)},${p.extraTrabajos.toStringAsFixed(2)},${p.ayudaEspecial.toStringAsFixed(2)},${p.descuentoPrestamo.toStringAsFixed(2)},${p.calcularNeto().toStringAsFixed(2)}');
    }
    sb.writeln('TOTAL NÓMINA,,,,,,${totalPagos.toStringAsFixed(2)}');

    return sb.toString();
  }

  String _escapeCsv(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.replaceAll('"', '""');
  }

  void _seedDefaultData() {
    if (_data.empleados.isEmpty) {
      _data.empleados.add(Empleado(
        id: 'emp_jose_ay',
        nombre: 'Jose Ay',
        puesto: 'Encargado Equipo 1',
        equipoId: 'equipo1',
      ));
      _data.empleados.add(Empleado(
        id: 'emp_nefy_dzul',
        nombre: 'Nefy Dzul',
        puesto: 'Encargado Equipo 2',
        equipoId: 'equipo2',
      ));
    }

    // Citas de ejemplo solo al probar en modo desarrollo; la app real empieza vacía.
    if (kDebugMode && _data.agenda.isEmpty) {
      final now = DateTime.now();
      String dia(int n) => DateFormat('yyyy-MM-dd').format(now.add(Duration(days: n)));

      _data.agenda.addAll([
        VisitaAgenda(
          id: 'vis_1',
          cliente: 'Carlos Mendoza',
          tipo: 'Instalación',
          fecha: dia(0),
          hora: '09:00',
          direccion: 'Calle 60 #450 x 53 y 55, Centro, Mérida',
          telefono: '9991234567',
          notas: 'Motor Merik 230V',
          estado: 'pendiente',
          equipoId: 'equipo1',
          montoEstimado: 4500,
        ),
        VisitaAgenda(
          id: 'vis_2',
          cliente: 'Ana Pech',
          tipo: 'Venta',
          fecha: dia(0),
          hora: '14:30',
          direccion: 'Calle 33 #210, García Ginerés, Mérida',
          telefono: '9997771122',
          notas: '2 controles remotos',
          estado: 'pendiente',
          equipoId: 'equipo1',
          montoEstimado: 900,
        ),
        VisitaAgenda(
          id: 'vis_3',
          cliente: 'María Torres',
          tipo: 'Mantenimiento',
          fecha: dia(0),
          hora: '11:30',
          direccion: 'Fracc. Las Américas, Calle 53 #120, Mérida',
          telefono: '9999876543',
          notas: 'Portón batiente de 2 hojas',
          estado: 'pendiente',
          equipoId: 'equipo2',
          montoEstimado: 800,
        ),
        VisitaAgenda(
          id: 'vis_4',
          cliente: 'Roberto Gómez',
          tipo: 'Medir y cotizar',
          fecha: dia(1),
          hora: '10:00',
          direccion: 'Col. México Norte, Calle 18 #95, Mérida',
          telefono: '9995554433',
          notas: '',
          estado: 'pendiente',
          equipoId: 'equipo1',
        ),
        VisitaAgenda(
          id: 'vis_5',
          cliente: 'Taller Industrial HEC',
          tipo: 'Reparación',
          fecha: dia(17),
          hora: '16:15',
          direccion: 'Periférico Sur Km 12, Mérida',
          telefono: '9994443322',
          notas: 'Falla en tarjeta LiftMaster',
          estado: 'pendiente',
          equipoId: 'equipo2',
          montoEstimado: 2200,
        ),
      ]);
    }
  }

  void _seedDefaultUsers() {
    // Admin Account: Hei-lam Ay
    if (!_data.usuarios.any((u) => u.isAdmin)) {
      _data.usuarios.add(Usuario(
        id: 'usr_admin',
        nombre: 'Hei-lam Ay',
        username: 'heilamay',
        password: Seguridad.cifrar('admin123'),
        rol: 'Administrador',
        equipoId: 'todos',
      ));
    }

    // Encargados: entran con su nombre y un PIN que ellos mismos crean la primera vez.
    if (!_data.usuarios.any((u) => u.username.toLowerCase() == 'joseay')) {
      _data.usuarios.add(Usuario(
        id: 'usr_equipo1',
        nombre: 'Jose Ay',
        username: 'joseay',
        password: '',
        rol: 'Empleado',
        equipoId: 'equipo1',
      ));
    }
    if (!_data.usuarios.any((u) => u.username.toLowerCase() == 'nefydzul')) {
      _data.usuarios.add(Usuario(
        id: 'usr_equipo2',
        nombre: 'Nefy Dzul',
        username: 'nefydzul',
        password: '',
        rol: 'Empleado',
        equipoId: 'equipo2',
      ));
    }

    // Cualquier contraseña o PIN que siga en texto plano se cifra al cargar.
    for (final u in _data.usuarios) {
      if (u.password.isNotEmpty && !Seguridad.esHash(u.password)) {
        u.password = Seguridad.cifrar(u.password);
      }
      if (u.pin.isNotEmpty && !Seguridad.esHash(u.pin)) {
        u.pin = Seguridad.cifrar(u.pin);
      }
      if (u.isAdmin && u.equipoId.isEmpty) u.equipoId = 'todos';
    }
  }
}
