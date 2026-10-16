import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/backup_data.dart';
import '../models/empleado.dart';
import '../models/usuario.dart';
import '../models/visita_agenda.dart';

class StorageService extends ChangeNotifier {
  BackupData _data = BackupData();
  File? _file;

  BackupData get data => _data;

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/storage.json');

      if (await _file!.exists()) {
        final jsonString = await _file!.readAsString();
        if (jsonString.isNotEmpty) {
          final decoded = jsonDecode(jsonString);
          _data = BackupData.fromJson(decoded);
        } else {
          _data = BackupData();
          _seedDefaultData();
        }
      } else {
        _data = BackupData();
        _seedDefaultData();
        await saveData();
      }
      _seedDefaultUsers();
    } catch (e) {
      if (kDebugMode) {
        print('Error initialising storage: $e');
      }
      _data = BackupData();
      _seedDefaultData();
    }
    notifyListeners();
  }

  Future<void> saveData() async {
    try {
      if (_file != null) {
        final jsonString = const JsonEncoder.withIndent('  ').convert(_data.toJson());
        await _file!.writeAsString(jsonString);
      }
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
    sb.write('\uFEFF');

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

    if (_data.agenda.isEmpty) {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      final nextWeekStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 3)));

      _data.agenda.addAll([
        VisitaAgenda(
          id: 'vis_1',
          cliente: 'Carlos Mendoza',
          tipo: 'Instalación Motor Corredizo',
          fecha: todayStr,
          hora: '09:00 AM',
          direccion: 'Calle 60 #450 x 53 y 55, Centro',
          telefono: '9991234567',
          notas: 'Motor Merik 230V. Traer soldadora y extensiones.',
          estado: 'pendiente',
          equipoId: 'equipo1',
        ),
        VisitaAgenda(
          id: 'vis_2',
          cliente: 'María Torres',
          tipo: 'Mantenimiento Preventivo',
          fecha: todayStr,
          hora: '11:30 AM',
          direccion: 'Fracc. Las Américas, Calle 53 #120',
          telefono: '9999876543',
          notas: 'Portón batiente de 2 hojas, lubricación y ajuste.',
          estado: 'pendiente',
          equipoId: 'equipo2',
        ),
        VisitaAgenda(
          id: 'vis_3',
          cliente: 'Roberto Gómez',
          tipo: 'Cotización Portón Ascendente',
          fecha: tomorrowStr,
          hora: '02:00 PM',
          direccion: 'Col. México Norte, Calle 18 #95',
          telefono: '9995554433',
          notas: 'Medir claro de cochera y mostrar catálogo de paneles.',
          estado: 'pendiente',
          equipoId: 'equipo1',
        ),
        VisitaAgenda(
          id: 'vis_4',
          cliente: 'Taller Industrial HEC',
          tipo: 'Reparación de Pistones',
          fecha: nextWeekStr,
          hora: '04:30 PM',
          direccion: 'Periférico Sur Km 12',
          telefono: '9994443322',
          notas: 'Falla en tarjeta electrónica LiftMaster.',
          estado: 'pendiente',
          equipoId: 'equipo2',
        ),
      ]);
    }

    _seedDefaultUsers();
  }

  void _seedDefaultUsers() {
    bool changed = false;

    // Admin Account: Hei-lam Ay
    if (!_data.usuarios.any((u) => u.username.toLowerCase() == 'heilamay' || u.username.toLowerCase() == 'admin')) {
      _data.usuarios.add(Usuario(
        id: 'usr_admin',
        nombre: 'Hei-lam Ay',
        username: 'heilamay',
        password: 'admin123',
        rol: 'Administrador',
        equipoId: 'todos',
      ));
      changed = true;
    }

    // Equipo 1: Jose Ay
    if (!_data.usuarios.any((u) => u.username.toLowerCase() == 'joseay' || u.username.toLowerCase() == 'equipo1')) {
      _data.usuarios.add(Usuario(
        id: 'usr_equipo1',
        nombre: 'Jose Ay (Equipo 1)',
        username: 'joseay',
        password: '1234',
        rol: 'Empleado',
        equipoId: 'equipo1',
      ));
      changed = true;
    }

    // Equipo 2: Nefy Dzul
    if (!_data.usuarios.any((u) => u.username.toLowerCase() == 'nefydzul' || u.username.toLowerCase() == 'equipo2')) {
      _data.usuarios.add(Usuario(
        id: 'usr_equipo2',
        nombre: 'Nefy Dzul (Equipo 2)',
        username: 'nefydzul',
        password: '1234',
        rol: 'Empleado',
        equipoId: 'equipo2',
      ));
      changed = true;
    }

    // Update legacy default admin or user team IDs if missing
    for (var u in _data.usuarios) {
      if (u.rol.toLowerCase() == 'administrador') {
        if (u.nombre == 'Administrador' || u.nombre.isEmpty) {
          u.nombre = 'Hei-lam Ay';
          changed = true;
        }
        if (u.equipoId.isEmpty) {
          u.equipoId = 'todos';
          changed = true;
        }
      } else if (u.username.toLowerCase() == 'joseay') {
        u.equipoId = 'equipo1';
        changed = true;
      } else if (u.username.toLowerCase() == 'nefydzul') {
        u.equipoId = 'equipo2';
        changed = true;
      }
    }

    if (changed) {
      saveData();
    }
  }
}
