import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/empleado.dart';
import '../models/pago_semanal.dart';
import '../services/app_engine_service.dart';
import 'encargado/ui.dart';

/// Personal y nómina del administrador, con el mismo estilo que Inicio y Agenda.
/// Los pagos se guardan por semana (lunes a domingo).
class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  DateTime _lunes = lunesDe(hoy());

  void _moverSemana(int semanas) => setState(() => _lunes = _lunes.add(Duration(days: 7 * semanas)));

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final empleados = engine.data.empleados;
    final semana = fechaKey(_lunes);
    final esEstaSemana = _lunes == lunesDe(hoy());
    final total = empleados.fold<double>(0, (s, e) => s + engine.getPagoSemanal(e.id, semana).calcularNeto());

    return EncargadoPage(
      child: ColoredBox(
        color: EC.fondo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Personal', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
            Text('Pagos de la semana', style: TextStyle(fontSize: 18, color: EC.textoSuave)),
            const SizedBox(height: 14),
            SelectorConFlechas(
              texto: semanaTexto(_lunes),
              onAnterior: () => _moverSemana(-1),
              onSiguiente: () => _moverSemana(1),
            ),
            if (!esEstaSemana)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _lunes = lunesDe(hoy())),
                  child: const Text('Volver a esta semana', style: TextStyle(fontSize: 17)),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total a pagar esta semana', style: TextStyle(fontSize: 18, color: EC.textoSuave)),
                  Text(dinero(total), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: EC.texto)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            BotonGrande(
              texto: 'Agregar empleado',
              icono: Icons.person_add_alt_1_outlined,
              estilo: EstiloBoton.primario,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NuevoEmpleadoScreen())),
            ),
            const SizedBox(height: 14),
            if (empleados.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
                child: Text('Todavía no hay empleados', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: EC.textoSuave)),
              ),
            for (final e in empleados) ...[
              _TarjetaEmpleado(
                empleado: e,
                pago: engine.getPagoSemanal(e.id, semana),
                pagado: engine.tienePagoSemanal(e.id, semana),
                onPago: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PagoSemanalScreen(empleado: e, lunes: _lunes),
                )),
                onQuitar: () => _quitar(e),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  void _quitar(Empleado e) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => PantallaBorrar(
        pregunta: '¿Quitar a ${e.nombre}?',
        detalle: 'Sale de la lista de personal. Sus pagos anteriores se conservan en los reportes.',
        onBorrar: () {
          final engine = ctx.read<AppEngineService>();
          final index = engine.data.empleados.indexWhere((x) => x.id == e.id);
          engine.deleteEmpleado(e.id);
          Navigator.of(ctx).pushReplacement(MaterialPageRoute(
            builder: (_) => PantallaListo(
              titulo: 'Quitado',
              mensaje: e.nombre,
              onDeshacer: () {
                engine.data.empleados.insert(index.clamp(0, engine.data.empleados.length), e);
                engine.storage.saveData();
              },
            ),
          ));
        },
      ),
    ));
  }
}

class _TarjetaEmpleado extends StatelessWidget {
  final Empleado empleado;
  final PagoSemanal pago;
  final bool pagado;
  final VoidCallback onPago;
  final VoidCallback onQuitar;

  const _TarjetaEmpleado({
    required this.empleado,
    required this.pago,
    required this.pagado,
    required this.onPago,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final e = empleado;
    final puesto = e.puesto.isEmpty ? 'Técnico' : e.puesto;
    final equipo = nombreEquipo(e.equipoId);
    final detalle = puesto.contains(equipo) ? puesto : '$puesto · $equipo';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: EC.bordeFuerte)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: EC.acentoFondo,
              child: Text(e.nombre.isNotEmpty ? e.nombre[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EC.acentoTexto)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.nombre, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: EC.texto)),
                  Text(detalle, style: TextStyle(fontSize: 16, color: EC.textoSuave)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: [
              DatoMonto(etiqueta: 'Base', valor: dinero(pago.pagoBase)),
              DatoMonto(etiqueta: 'Extras', valor: dinero(pago.extraTrabajos + pago.ayudaEspecial)),
              DatoMonto(
                etiqueta: 'Préstamo',
                valor: pago.descuentoPrestamo > 0 ? '−${dinero(pago.descuentoPrestamo)}' : dinero(0),
                color: pago.descuentoPrestamo > 0 ? EC.peligroTexto : EC.texto,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text(pagado ? 'Neto a pagar' : 'Sin pago registrado',
                  style: TextStyle(fontSize: 18, color: EC.textoSuave)),
            ),
            Text(dinero(pago.calcularNeto()), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: EC.texto)),
          ]),
          const SizedBox(height: 12),
          BotonGrande(
            texto: pagado ? 'Cambiar pago' : 'Registrar pago',
            icono: Icons.payments_outlined,
            estilo: pagado ? EstiloBoton.normal : EstiloBoton.primario,
            alto: 56,
            onTap: onPago,
          ),
          const SizedBox(height: 8),
          BotonGrande(
            texto: 'Quitar de la lista',
            icono: Icons.person_remove_outlined,
            estilo: EstiloBoton.peligroSuave,
            fontSize: 17,
            alto: 50,
            onTap: onQuitar,
          ),
        ],
      ),
    );
  }
}

class NuevoEmpleadoScreen extends StatefulWidget {
  const NuevoEmpleadoScreen({super.key});

  @override
  State<NuevoEmpleadoScreen> createState() => _NuevoEmpleadoScreenState();
}

class _NuevoEmpleadoScreenState extends State<NuevoEmpleadoScreen> {
  final _nombre = TextEditingController();
  final _puesto = TextEditingController();
  String _equipo = 'equipo1';
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _puesto.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_nombre.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el nombre');
      return;
    }
    final engine = context.read<AppEngineService>();
    final e = Empleado(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombre.text.trim(),
      puesto: _puesto.text.trim(),
      equipoId: _equipo,
    );
    engine.addEmpleado(e);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PantallaListo(
        titulo: 'Agregado',
        mensaje: '${e.nombre}\n${nombreEquipo(e.equipoId)}',
        onDeshacer: () => engine.deleteEmpleado(e.id),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return EncargadoPage(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Encabezado(titulo: 'Nuevo empleado', onAtras: () => Navigator.of(context).pop()),
                  const SizedBox(height: 16),
                  CampoGrande(
                    etiqueta: 'Nombre',
                    controller: _nombre,
                    ejemplo: 'Pedro Canul',
                    mayusculas: TextCapitalization.words,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  TextoError(_error),
                  const SizedBox(height: 18),
                  CampoGrande(etiqueta: 'Puesto', opcional: '(opcional)', controller: _puesto, ejemplo: 'Instalador'),
                  const SizedBox(height: 18),
                  Text('¿En qué equipo trabaja?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: EC.texto)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: BotonGrande(texto: 'Equipo 1', alto: 56, seleccionado: _equipo == 'equipo1', onTap: () => setState(() => _equipo = 'equipo1'))),
                    const SizedBox(width: 10),
                    Expanded(child: BotonGrande(texto: 'Equipo 2', alto: 56, seleccionado: _equipo == 'equipo2', onTap: () => setState(() => _equipo = 'equipo2'))),
                  ]),
                  const SizedBox(height: 28),
                  BotonGrande(texto: 'Guardar', icono: Icons.check, estilo: EstiloBoton.exito, onTap: _guardar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PagoSemanalScreen extends StatefulWidget {
  final Empleado empleado;
  final DateTime lunes;

  const PagoSemanalScreen({super.key, required this.empleado, required this.lunes});

  @override
  State<PagoSemanalScreen> createState() => _PagoSemanalScreenState();
}

class _PagoSemanalScreenState extends State<PagoSemanalScreen> {
  late final PagoSemanal _anterior;
  late final bool _existia;
  late final TextEditingController _base;
  late final TextEditingController _extras;
  late final TextEditingController _motivoExtras;
  late final TextEditingController _ayuda;
  late final TextEditingController _prestamo;

  String get _semana => fechaKey(widget.lunes);

  String _texto(double v) => v == 0 ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());
  double _valor(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    final engine = context.read<AppEngineService>();
    _existia = engine.tienePagoSemanal(widget.empleado.id, _semana);
    _anterior = engine.getPagoSemanal(widget.empleado.id, _semana);
    _base = TextEditingController(text: _texto(_anterior.pagoBase));
    _extras = TextEditingController(text: _texto(_anterior.extraTrabajos));
    _motivoExtras = TextEditingController(text: _anterior.motivoExtra);
    _ayuda = TextEditingController(text: _texto(_anterior.ayudaEspecial));
    _prestamo = TextEditingController(text: _texto(_anterior.descuentoPrestamo));
  }

  @override
  void dispose() {
    for (final c in [_base, _extras, _motivoExtras, _ayuda, _prestamo]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _neto => _valor(_base) + _valor(_extras) + _valor(_ayuda) - _valor(_prestamo);

  void _guardar() {
    final engine = context.read<AppEngineService>();
    final copiaAnterior = PagoSemanal.fromJson(_anterior.toJson());
    final p = PagoSemanal(
      id: _anterior.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : _anterior.id,
      empleadoId: widget.empleado.id,
      semana: _semana,
      pagoBase: _valor(_base),
      extraTrabajos: _valor(_extras),
      motivoExtra: _motivoExtras.text.trim(),
      ayudaEspecial: _valor(_ayuda),
      motivoAyuda: _anterior.motivoAyuda,
      descuentoPrestamo: _valor(_prestamo),
      motivoPrestamo: _anterior.motivoPrestamo,
    );
    engine.savePagoSemanal(p);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PantallaListo(
        titulo: _existia ? 'Pago cambiado' : 'Pago registrado',
        mensaje: '${widget.empleado.nombre}\n${dinero(p.calcularNeto())} · ${semanaTexto(widget.lunes).toLowerCase()}',
        onDeshacer: () => _existia
            ? engine.savePagoSemanal(copiaAnterior)
            : engine.deletePagoSemanal(widget.empleado.id, _semana),
      ),
    ));
  }

  Widget _campoDinero(String etiqueta, TextEditingController c, {String? opcional}) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: CampoGrande(
          etiqueta: etiqueta,
          opcional: opcional,
          controller: c,
          ejemplo: '0',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return EncargadoPage(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Encabezado(
                    titulo: 'Pago de ${widget.empleado.nombre}',
                    paso: semanaTexto(widget.lunes),
                    onAtras: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 16),
                  _campoDinero('Pago base', _base),
                  _campoDinero('Extras por trabajos', _extras, opcional: '(si hubo)'),
                  if (_valor(_extras) > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CampoGrande(etiqueta: '¿Por qué los extras?', opcional: '(opcional)', controller: _motivoExtras, ejemplo: 'Instalación en domingo'),
                    ),
                  _campoDinero('Ayuda especial', _ayuda, opcional: '(si hubo)'),
                  _campoDinero('Préstamo a descontar', _prestamo, opcional: '(si hubo)'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(child: Text('Neto a pagar', style: TextStyle(fontSize: 20, color: EC.textoSuave))),
                      Text(dinero(_neto), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: EC.texto)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  BotonGrande(texto: 'Guardar pago', icono: Icons.check, estilo: EstiloBoton.exito, onTap: _guardar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
