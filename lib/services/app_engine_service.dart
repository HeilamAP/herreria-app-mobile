import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../models/gasto.dart';
import '../models/trabajo.dart';
import '../models/empleado.dart';
import '../models/pago_semanal.dart';
import '../models/marca.dart';
import '../models/visita_agenda.dart';
import '../models/backup_data.dart';
import 'storage_service.dart';

class AppEngineService extends ChangeNotifier {
  final StorageService storage;

  AppEngineService({required this.storage}) {
    storage.addListener(notifyListeners);
  }

  BackupData get data => storage.data;

  // --- FILTROS POR EQUIPO ---
  List<Venta> getVentasFiltered(String equipoId) {
    if (equipoId == 'todos' || equipoId.isEmpty) {
      return storage.data.ventas;
    }
    return storage.data.ventas.where((v) => v.equipoId == equipoId).toList();
  }

  List<Gasto> getGastosFiltered(String equipoId) {
    if (equipoId == 'todos' || equipoId.isEmpty) {
      return storage.data.gastos;
    }
    return storage.data.gastos.where((g) => g.equipoId == equipoId).toList();
  }

  List<Trabajo> getTrabajosFiltered(String equipoId) {
    if (equipoId == 'todos' || equipoId.isEmpty) {
      return storage.data.trabajos;
    }
    return storage.data.trabajos.where((t) => t.equipoId == equipoId).toList();
  }

  List<VisitaAgenda> getAgendaFiltered(String equipoId) {
    if (equipoId == 'todos' || equipoId.isEmpty) {
      return storage.data.agenda;
    }
    return storage.data.agenda.where((a) => a.equipoId == equipoId).toList();
  }

  List<Empleado> getEmpleadosFiltered(String equipoId) {
    if (equipoId == 'todos' || equipoId.isEmpty) {
      return storage.data.empleados;
    }
    return storage.data.empleados.where((e) => e.equipoId == equipoId).toList();
  }

  // --- VENTAS ---
  void addVenta(Venta v) {
    storage.data.ventas.insert(0, v);
    storage.saveData();
    notifyListeners();
  }

  void saveVenta(Venta v) {
    int index = storage.data.ventas.indexWhere((x) => x.id == v.id);
    if (index >= 0) {
      storage.data.ventas[index] = v;
    } else {
      storage.data.ventas.insert(0, v);
    }
    storage.saveData();
    notifyListeners();
  }

  void deleteVenta(String id) {
    storage.data.ventas.removeWhere((x) => x.id == id);
    storage.saveData();
    notifyListeners();
  }

  // --- GASTOS ---
  void addGasto(Gasto g) {
    storage.data.gastos.insert(0, g);
    storage.saveData();
    notifyListeners();
  }

  void saveGasto(Gasto g) {
    int index = storage.data.gastos.indexWhere((x) => x.id == g.id);
    if (index >= 0) {
      storage.data.gastos[index] = g;
    } else {
      storage.data.gastos.insert(0, g);
    }
    storage.saveData();
    notifyListeners();
  }

  void deleteGasto(String id) {
    storage.data.gastos.removeWhere((x) => x.id == id);
    storage.saveData();
    notifyListeners();
  }

  // --- TRABAJOS ---
  void addTrabajo(Trabajo t) {
    saveTrabajo(t);
  }

  void saveTrabajo(Trabajo t) {
    int index = storage.data.trabajos.indexWhere((x) => x.id == t.id);
    if (index >= 0) {
      storage.data.trabajos[index] = t;
    } else {
      storage.data.trabajos.insert(0, t);
    }

    // Automatically sync work with Agenda for daily tracking
    final agendaId = 'trabajo_${t.id}';
    final fechaAgenda = t.fecha.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : t.fecha.trim();

    final agendaIndex = storage.data.agenda.indexWhere((a) => a.id == agendaId || a.id == t.id);
    final nuevaVisita = VisitaAgenda(
      id: agendaId,
      cliente: t.cliente,
      fecha: fechaAgenda,
      hora: '09:00 AM',
      tipo: 'Trabajo Realizado',
      direccion: 'Taller / Instalación',
      telefono: '',
      notas: t.descripcion.isNotEmpty ? 'Monto: \$${t.monto.toStringAsFixed(2)} • ${t.descripcion}' : 'Monto: \$${t.monto.toStringAsFixed(2)}',
      estado: 'completado',
      equipoId: t.equipoId,
      monto: t.monto,
    );

    if (agendaIndex >= 0) {
      storage.data.agenda[agendaIndex] = nuevaVisita;
    } else {
      storage.data.agenda.insert(0, nuevaVisita);
    }

    storage.saveData();
    notifyListeners();
  }

  void deleteTrabajo(String id) {
    storage.data.trabajos.removeWhere((x) => x.id == id);
    storage.data.agenda.removeWhere((a) => a.id == 'trabajo_$id' || a.id == id);
    storage.saveData();
    notifyListeners();
  }

  // --- EMPLEADOS Y NÓMINA ---
  void addEmpleado(Empleado e) {
    storage.data.empleados.add(e);
    storage.saveData();
    notifyListeners();
  }

  void deleteEmpleado(String id) {
    storage.data.empleados.removeWhere((x) => x.id == id);
    storage.saveData();
    notifyListeners();
  }

  void savePagoSemanal(PagoSemanal p) {
    int index = storage.data.pagosSemanales.indexWhere(
        (x) => x.empleadoId == p.empleadoId && x.semana == p.semana);
    if (index >= 0) {
      storage.data.pagosSemanales[index] = p;
    } else {
      storage.data.pagosSemanales.add(p);
    }
    storage.saveData();
    notifyListeners();
  }

  void deletePagoSemanal(String empleadoId, String semana) {
    storage.data.pagosSemanales.removeWhere((x) => x.empleadoId == empleadoId && x.semana == semana);
    storage.saveData();
    notifyListeners();
  }

  bool tienePagoSemanal(String empleadoId, String semana) =>
      storage.data.pagosSemanales.any((x) => x.empleadoId == empleadoId && x.semana == semana);

  PagoSemanal getPagoSemanal(String empleadoId, String semana) {
    return storage.data.pagosSemanales.firstWhere(
      (x) => x.empleadoId == empleadoId && x.semana == semana,
      orElse: () => PagoSemanal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        empleadoId: empleadoId,
        semana: semana,
      ),
    );
  }

  // --- AGENDA ---
  void addVisitaAgenda(VisitaAgenda v) {
    storage.data.agenda.insert(0, v);
    storage.saveData();
    notifyListeners();
  }

  void updateVisitaEstado(String id, String estado) {
    int index = storage.data.agenda.indexWhere((x) => x.id == id);
    if (index >= 0) {
      storage.data.agenda[index].estado = estado;
      storage.saveData();
      notifyListeners();
    }
  }

  void updateVisitaEstadoConMonto(String id, String estado, double monto, {String? metodoPago}) {
    int index = storage.data.agenda.indexWhere((x) => x.id == id);
    if (index >= 0) {
      storage.data.agenda[index].estado = estado;
      if (monto >= 0) {
        storage.data.agenda[index].monto = monto;
      }
      if (metodoPago != null && metodoPago.isNotEmpty) {
        storage.data.agenda[index].metodoPago = metodoPago;
      }
      storage.saveData();
      notifyListeners();
    }
  }

  void deleteVisitaAgenda(String id) {
    storage.data.agenda.removeWhere((x) => x.id == id);
    storage.saveData();
    notifyListeners();
  }

  // --- CALCULOS Y ESTADÍSTICAS FILTRADAS POR EQUIPO ---
  double getTotalVentasMonto({String equipoId = 'todos'}) {
    final ventas = getVentasFiltered(equipoId);
    return ventas.fold<double>(0, (sum, v) => sum + v.montoVenta);
  }

  int getTotalVentasCantidad({String equipoId = 'todos'}) {
    return getVentasFiltered(equipoId).length;
  }

  double getTotalTrabajosMonto({String equipoId = 'todos'}) {
    return getTotalTrabajosRealizadosMonto(equipoId: equipoId);
  }

  double getTotalTrabajosRealizadosMonto({String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    final trabajos = getTrabajosFiltered(equipoId);

    double total = 0.0;
    final processedIds = <String>{};

    for (var a in agenda) {
      final st = a.estado.toLowerCase();
      if (st == 'completado' || st == 'realizado') {
        total += a.monto;
        processedIds.add(a.id);
        if (a.id.startsWith('trabajo_')) {
          processedIds.add(a.id.replaceFirst('trabajo_', ''));
        }
      }
    }

    for (var t in trabajos) {
      if (!processedIds.contains(t.id) && !processedIds.contains('trabajo_${t.id}')) {
        total += t.monto;
      }
    }

    return total;
  }

  int getTotalTrabajosCantidad({String equipoId = 'todos'}) {
    return getTrabajosRealizadosCantidad(equipoId: equipoId);
  }

  int getTrabajosRealizadosCantidad({String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    final trabajos = getTrabajosFiltered(equipoId);

    final agendaCompletados = agenda.where((v) {
      final st = v.estado.toLowerCase();
      return st == 'completado' || st == 'realizado';
    }).map((v) => v.id).toSet();

    int countExtraTrabajos = 0;
    for (var t in trabajos) {
      final syncId = 'trabajo_${t.id}';
      if (!agendaCompletados.contains(t.id) && !agendaCompletados.contains(syncId)) {
        countExtraTrabajos++;
      }
    }

    return agendaCompletados.length + countExtraTrabajos;
  }

  double getTotalIngresos({String equipoId = 'todos'}) {
    return getTotalVentasMonto(equipoId: equipoId) + getTotalTrabajosRealizadosMonto(equipoId: equipoId);
  }

  double getTotalGastos({String equipoId = 'todos'}) {
    final gastos = getGastosFiltered(equipoId);
    final ventas = getVentasFiltered(equipoId);

    final gastosDirectos = gastos.fold<double>(0, (sum, g) => sum + g.monto);
    final comprasReventa = ventas.fold<double>(0, (sum, v) => sum + v.costoCompra);
    final nominaNeto = getTotalNominaGastada(equipoId: equipoId);

    return gastosDirectos + comprasReventa + nominaNeto;
  }

  double getTotalNominaGastada({String equipoId = 'todos'}) {
    final empleados = getEmpleadosFiltered(equipoId);
    final empIds = empleados.map((e) => e.id).toSet();
    return storage.data.pagosSemanales
        .where((p) => equipoId == 'todos' || empIds.contains(p.empleadoId))
        .fold<double>(0, (sum, p) => sum + p.calcularNeto());
  }

  double getGananciaNeta({String equipoId = 'todos'}) =>
      getTotalIngresos(equipoId: equipoId) - getTotalGastos(equipoId: equipoId);

  int getVisitasPendientes({String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    return agenda.where((v) => v.estado.toLowerCase() == 'pendiente').length;
  }

  int getTrabajosPagadosEfectivoCantidad({String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    return agenda.where((v) {
      final st = v.estado.toLowerCase();
      final isCompletado = st == 'completado' || st == 'realizado';
      return isCompletado && (v.metodoPago.toLowerCase() == 'efectivo' || v.metodoPago.isEmpty);
    }).length;
  }

  double getTrabajosPagadosEfectivoMonto({String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    return agenda.where((v) {
      final st = v.estado.toLowerCase();
      final isCompletado = st == 'completado' || st == 'realizado';
      return isCompletado && (v.metodoPago.toLowerCase() == 'efectivo' || v.metodoPago.isEmpty);
    }).fold<double>(0, (sum, v) => sum + v.monto);
  }

  int getTrabajosPagadosTransferenciaCantidad({String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    return agenda.where((v) {
      final st = v.estado.toLowerCase();
      final isCompletado = st == 'completado' || st == 'realizado';
      return isCompletado && v.metodoPago.toLowerCase() == 'transferencia';
    }).length;
  }

  double getTrabajosPagadosTransferenciaMonto({String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    return agenda.where((v) {
      final st = v.estado.toLowerCase();
      final isCompletado = st == 'completado' || st == 'realizado';
      return isCompletado && v.metodoPago.toLowerCase() == 'transferencia';
    }).fold<double>(0, (sum, v) => sum + v.monto);
  }

  List<VisitaAgenda> getTrabajosPorMetodoPago(String metodoPago, {String equipoId = 'todos'}) {
    final agenda = getAgendaFiltered(equipoId);
    final list = agenda.where((v) {
      final st = v.estado.toLowerCase();
      final isCompletado = st == 'completado' || st == 'realizado';
      if (!isCompletado) return false;
      if (metodoPago == 'transferencia') {
        return v.metodoPago.toLowerCase() == 'transferencia';
      } else {
        return v.metodoPago.toLowerCase() == 'efectivo' || v.metodoPago.isEmpty;
      }
    }).toList();
    list.sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  // --- MODO ENCARGADO ---
  List<VisitaAgenda> trabajosDelDia(String equipoId, String fecha) {
    final list = getAgendaFiltered(equipoId)
        .where((a) => a.fecha == fecha && a.estado.toLowerCase() != 'cancelado')
        .toList();
    list.sort((a, b) => a.minutosDelDia.compareTo(b.minutosDelDia));
    return list;
  }

  int pendientesEn(String equipoId, String fecha) => getAgendaFiltered(equipoId)
      .where((a) => a.fecha == fecha && a.estado.toLowerCase() == 'pendiente')
      .length;

  /// Guarda una cita nueva o reemplaza la que tenga el mismo id.
  void saveVisitaAgenda(VisitaAgenda v) {
    final index = storage.data.agenda.indexWhere((x) => x.id == v.id);
    if (index >= 0) {
      storage.data.agenda[index] = v;
    } else {
      storage.data.agenda.insert(0, v);
    }
    storage.saveData();
    notifyListeners();
  }

  int indexOfVisita(String id) => storage.data.agenda.indexWhere((x) => x.id == id);

  VisitaAgenda? visitaPorId(String id) => storage.data.agenda.where((x) => x.id == id).firstOrNull;

  /// Cambia solo la nota final y/o las fotos de un trabajo (se guarda al momento).
  void actualizarNotaYFotos(String id, {String? notaFinal, List<String>? fotos}) {
    final v = visitaPorId(id);
    if (v == null) return;
    if (notaFinal != null) v.notaFinal = notaFinal;
    if (fotos != null) {
      v.fotos = List.of(fotos);
      v.marcasFotos.removeWhere((foto, _) => !v.fotos.contains(foto)); // fotos quitadas
    }
    storage.saveData();
    notifyListeners();
  }

  // --- Evidencia: hora y lugar (ver Marca y ubicacion.dart) ---

  void _marcar(String id, void Function(VisitaAgenda v) cambio) {
    final v = visitaPorId(id);
    if (v == null) return;
    cambio(v);
    storage.saveData();
    notifyListeners();
  }

  void marcarLlegada(String id, Marca m) => _marcar(id, (v) => v.llegada = m);
  void marcarSalida(String id, Marca m) => _marcar(id, (v) => v.salida = m);
  void marcarFoto(String id, String fotoId, Marca m) => _marcar(id, (v) => v.marcasFotos[fotoId] = m);

  void guardarDomicilio(String id, double lat, double lng, String direccion) => _marcar(id, (v) {
        v.domLat = lat;
        v.domLng = lng;
        v.domDireccion = direccion;
      });

  /// Para "deshacer" un borrado: regresa la cita a donde estaba.
  void insertVisitaAt(VisitaAgenda v, int index) {
    final i = index.clamp(0, storage.data.agenda.length);
    storage.data.agenda.insert(i, v);
    storage.saveData();
    notifyListeners();
  }

  /// Trabajos y ventas cobrados en una fecha con cierta forma de pago ('efectivo' | 'transferencia').
  List<VisitaAgenda> cobrosDelDia(String equipoId, String fecha, String metodo) => cobrosEntre(equipoId, fecha, fecha, metodo);

  /// Cobros entre dos fechas (yyyy-MM-dd, ambas incluidas), ordenados por día y hora.
  List<VisitaAgenda> cobrosEntre(String equipoId, String desde, String hasta, String metodo) {
    final list = getAgendaFiltered(equipoId).where((a) {
      if (!a.completado || a.fecha.compareTo(desde) < 0 || a.fecha.compareTo(hasta) > 0) return false;
      final esTransferencia = a.metodoPago.toLowerCase() == 'transferencia';
      return metodo == 'transferencia' ? esTransferencia : !esTransferencia;
    }).toList();
    list.sort((a, b) {
      final f = a.fecha.compareTo(b.fecha);
      return f != 0 ? f : a.minutosDelDia.compareTo(b.minutosDelDia);
    });
    return list;
  }

  List<Gasto> gastosEntre(String equipoId, String desde, String hasta) =>
      getGastosFiltered(equipoId).where((g) => g.fecha.compareTo(desde) >= 0 && g.fecha.compareTo(hasta) <= 0).toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));

  List<Gasto> gastosDelDia(String equipoId, String fecha) =>
      getGastosFiltered(equipoId).where((g) => g.fecha == fecha).toList();

  int indexOfGasto(String id) => storage.data.gastos.indexWhere((x) => x.id == id);

  void insertGastoAt(Gasto g, int index) {
    final i = index.clamp(0, storage.data.gastos.length);
    storage.data.gastos.insert(i, g);
    storage.saveData();
    notifyListeners();
  }

  /// Totales de un equipo entre dos fechas (yyyy-MM-dd, ambas incluidas).
  ResumenEquipo resumen(String equipoId, String desde, String hasta) {
    bool enRango(String f) => f.compareTo(desde) >= 0 && f.compareTo(hasta) <= 0;
    final r = ResumenEquipo();
    for (final a in getAgendaFiltered(equipoId)) {
      if (!a.completado || !enRango(a.fecha)) continue;
      if (a.esVenta) {
        r.ventas += a.monto;
      } else {
        r.trabajos += a.monto;
      }
      if (a.metodoPago.toLowerCase() == 'transferencia') {
        r.transferencia += a.monto;
      } else {
        r.efectivo += a.monto;
      }
    }
    // Ventas capturadas con la pantalla anterior de Ventas.
    for (final v in getVentasFiltered(equipoId)) {
      if (enRango(v.fecha)) r.ventas += v.montoVenta;
    }
    for (final g in getGastosFiltered(equipoId)) {
      if (enRango(g.fecha)) r.gastos += g.monto;
    }
    return r;
  }

  double nominaEntre(String desde, String hasta) => storage.data.pagosSemanales
      .where((p) => p.semana.compareTo(desde) >= 0 && p.semana.compareTo(hasta) <= 0)
      .fold<double>(0, (sum, p) => sum + p.calcularNeto());
}

class ResumenEquipo {
  double trabajos = 0;
  double ventas = 0;
  double gastos = 0;
  double efectivo = 0;
  double transferencia = 0;

  double get cobrado => trabajos + ventas;
  double get quedo => cobrado - gastos;
}
