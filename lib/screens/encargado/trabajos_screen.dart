import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/visita_agenda.dart';
import '../../services/app_engine_service.dart';
import '../../services/auth_service.dart';
import 'agendar_screen.dart';
import 'cobrar_screen.dart';
import 'ui.dart';

/// Lista de trabajos por día. Para el encargado muestra solo su equipo;
/// para el administrador agrega un filtro por equipo.
class TrabajosDiaScreen extends StatefulWidget {
  final bool admin;
  const TrabajosDiaScreen({super.key, this.admin = false});

  @override
  State<TrabajosDiaScreen> createState() => _TrabajosDiaScreenState();
}

class _TrabajosDiaScreenState extends State<TrabajosDiaScreen> {
  static const _anchoDia = 92.0;
  static const _separacionDia = 8.0;

  DateTime _dia = hoy();
  String _filtroEquipo = 'todos';
  final _tiraDias = ScrollController();

  @override
  void dispose() {
    _tiraDias.dispose();
    super.dispose();
  }

  /// Mueve la tira de días para que el día elegido quede a la vista.
  void _mostrarDiaEnTira(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tiraDias.hasClients) return;
      final destino = (index * (_anchoDia + _separacionDia) - _anchoDia).clamp(0.0, _tiraDias.position.maxScrollExtent);
      _tiraDias.animateTo(destino, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  String get _equipoConsulta =>
      widget.admin ? _filtroEquipo : (context.read<AuthService>().currentUser?.equipoId ?? 'equipo1');

  /// Equipo con el que se crean trabajos nuevos.
  String get _equipoNuevo => widget.admin
      ? (_filtroEquipo == 'todos' ? 'equipo1' : _filtroEquipo)
      : (context.read<AuthService>().currentUser?.equipoId ?? 'equipo1');

  void _irADia(DateTime d) {
    if (!mounted) return;
    setState(() => _dia = soloDia(d));
    final index = diasEntre(hoy(), _dia);
    _mostrarDiaEnTira(index >= 0 && index < 14 ? index : 0);
  }

  void _agendar() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AgendarScreen(
        equipoId: _equipoNuevo,
        elegirEquipo: widget.admin,
        diaInicial: _dia.isBefore(hoy()) ? null : _dia,
        onDiaGuardado: _irADia,
      ),
    ));
  }

  void _ventaRapida() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CobrarScreen(equipoId: _equipoNuevo),
    )).then((_) => _irADia(hoy()));
  }

  Future<void> _verCalendario() async {
    final engine = context.read<AppEngineService>();
    final equipo = _equipoConsulta;
    final elegido = await Navigator.of(context).push<DateTime>(MaterialPageRoute(
      builder: (_) => EncargadoPage(
        child: Scaffold(
          body: SafeArea(
            child: Builder(
              builder: (ctx) => ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Encabezado(titulo: '¿Qué día quieres ver?', onAtras: () => Navigator.of(ctx).pop()),
                  const SizedBox(height: 12),
                  CalendarioMes(
                    seleccionado: _dia,
                    pendientes: (d) => engine.pendientesEn(equipo, fechaKey(d)),
                    onDia: (d) => Navigator.of(ctx).pop(d),
                  ),
                  const SizedBox(height: 12),
                  const Text('Toca un día para ver sus trabajos.', style: TextStyle(fontSize: 17, color: EC.textoSuave)),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    if (elegido != null) _irADia(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final equipo = _equipoConsulta;
    final h = hoy();
    final lista = engine.trabajosDelDia(equipo, fechaKey(_dia));
    final dias = [for (var i = 0; i < 14; i++) h.add(Duration(days: i))];
    if (!dias.contains(_dia)) dias.insert(0, _dia);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (widget.admin) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final e in ['todos', 'equipo1', 'equipo2'])
                ChoiceChip(
                  label: Text(e == 'todos' ? 'Todos los equipos' : nombreEquipo(e), style: const TextStyle(fontSize: 16)),
                  selected: _filtroEquipo == e,
                  onSelected: (_) => setState(() => _filtroEquipo = e),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 74,
          child: ListView.separated(
            controller: _tiraDias,
            scrollDirection: Axis.horizontal,
            itemCount: dias.length,
            separatorBuilder: (_, _) => const SizedBox(width: _separacionDia),
            itemBuilder: (_, i) {
              final d = dias[i];
              final dif = diasEntre(h, d);
              final n = engine.pendientesEn(equipo, fechaKey(d));
              final arriba = dif == 0 ? 'Hoy' : dif == 1 ? 'Mañana' : '${diasCortos[d.weekday - 1]} ${d.day}';
              final abajo = n > 0 ? '$n pend.' : (dif < 2 ? '${d.day} ${meses[d.month - 1].substring(0, 3)}' : meses[d.month - 1].substring(0, 3));
              return SizedBox(
                width: _anchoDia,
                child: BotonGrande(
                  texto: arriba,
                  subtitulo: abajo,
                  fontSize: 16,
                  alto: 72,
                  padding: 4,
                  seleccionado: d == _dia,
                  onTap: () => _irADia(d),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        BotonGrande(
          texto: 'Ver otro día en el calendario',
          icono: Icons.calendar_month_outlined,
          fontSize: 18,
          alto: 54,
          onTap: _verCalendario,
        ),
        const SizedBox(height: 14),
        Text(diaTexto(_dia), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EC.texto)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BotonGrande(
                texto: 'Agendar',
                icono: Icons.edit_calendar_outlined,
                vertical: true,
                fontSize: 18,
                alto: 84,
                estilo: EstiloBoton.primario,
                onTap: _agendar,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BotonGrande(
                texto: 'Vendí algo ahora',
                icono: Icons.shopping_cart_outlined,
                vertical: true,
                fontSize: 18,
                alto: 84,
                estilo: EstiloBoton.acentoSuave,
                onTap: _ventaRapida,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (lista.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
            child: const Text('No hay trabajos este día', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: EC.textoSuave)),
          ),
        for (final t in lista) ...[
          _TarjetaTrabajo(
            trabajo: t,
            mostrarEquipo: widget.admin && _filtroEquipo == 'todos',
            onCobrar: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CobrarScreen(equipoId: t.equipoId, trabajo: t),
            )),
            onOpciones: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OpcionesTrabajoScreen(trabajo: t, elegirEquipo: widget.admin, onDiaGuardado: _irADia),
            )),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TarjetaTrabajo extends StatelessWidget {
  final VisitaAgenda trabajo;
  final bool mostrarEquipo;
  final VoidCallback onCobrar;
  final VoidCallback onOpciones;

  const _TarjetaTrabajo({required this.trabajo, required this.mostrarEquipo, required this.onCobrar, required this.onOpciones});

  Future<void> _abrir(BuildContext context, Uri uri, String faltante) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _aviso(context, 'No se pudo abrir. $faltante');
  }

  void _aviso(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: const TextStyle(fontSize: 18)), behavior: SnackBarBehavior.floating),
      );

  @override
  Widget build(BuildContext context) {
    final t = trabajo;
    final minutos = t.minutosDelDia;
    final equipoTxt = mostrarEquipo ? ' · ${nombreEquipo(t.equipoId)}' : '';

    if (t.completado) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EC.exitoFondo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EC.exitoBorde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.check_circle, color: EC.exitoTexto, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${horaTexto(minutos)} · ${t.cliente}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.exitoTexto)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              '${t.tipo}${t.notas.isNotEmpty ? ' · ${t.notas}' : ''}$equipoTxt\n'
              'Cobrado ${dinero(t.monto)} · ${t.metodoPago.toLowerCase() == 'transferencia' ? 'Transferencia' : 'Efectivo'}',
              style: const TextStyle(fontSize: 18, color: EC.exitoTexto, height: 1.35),
            ),
            const SizedBox(height: 10),
            BotonGrande(texto: 'Cambiar o borrar', icono: Icons.edit_outlined, fontSize: 17, alto: 50, onTap: onOpciones),
          ],
        ),
      );
    }

    final puedeCobrar = !fechaDeKey(t.fecha).isAfter(hoy());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EC.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EC.bordeFuerte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(horaTexto(minutos), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: EC.texto)),
              const SizedBox(width: 6),
              Text(parteDelDia(minutos ~/ 60).replaceFirst('de la ', ''),
                  style: const TextStyle(fontSize: 16, color: EC.textoSuave)),
              const Spacer(),
              Icon(iconoDeTipo(t.tipo), size: 20, color: t.esVenta ? EC.acento : EC.textoSuave),
              const SizedBox(width: 4),
              Flexible(
                child: Text(t.tipo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, color: t.esVenta ? EC.acentoTexto : EC.textoSuave, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${t.cliente}$equipoTxt', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EC.texto)),
          if (t.notas.isNotEmpty) Text(t.notas, style: const TextStyle(fontSize: 18, color: EC.texto)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.place_outlined, size: 20, color: EC.textoSuave),
            const SizedBox(width: 4),
            Expanded(
              child: Text(t.direccion.isEmpty ? 'Sin dirección' : t.direccion,
                  style: const TextStyle(fontSize: 17, color: EC.textoSuave)),
            ),
          ]),
          if (t.montoEstimado > 0) ...[
            const SizedBox(height: 4),
            Text('Cobrar aprox. ${dinero(t.montoEstimado)}', style: const TextStyle(fontSize: 19, color: EC.texto, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BotonGrande(
                  texto: 'Llamar',
                  icono: Icons.phone_outlined,
                  vertical: true,
                  fontSize: 17,
                  alto: 66,
                  onTap: () => t.telefono.trim().isEmpty
                      ? _aviso(context, 'Este trabajo no tiene teléfono.')
                      : _abrir(context, Uri(scheme: 'tel', path: t.telefono.replaceAll(RegExp(r'[^0-9+]'), '')), ''),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BotonGrande(
                  texto: 'Cómo llegar',
                  icono: Icons.map_outlined,
                  vertical: true,
                  fontSize: 17,
                  alto: 66,
                  onTap: () => t.direccion.trim().isEmpty
                      ? _aviso(context, 'Este trabajo no tiene dirección.')
                      : _abrir(
                          context,
                          Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': t.direccion}),
                          '',
                        ),
                ),
              ),
            ],
          ),
          if (puedeCobrar) ...[
            const SizedBox(height: 10),
            BotonGrande(
              texto: t.esVenta ? 'Ya vendí y cobré' : 'Terminé y cobré',
              icono: Icons.check,
              estilo: EstiloBoton.exito,
              onTap: onCobrar,
            ),
          ],
          const SizedBox(height: 10),
          BotonGrande(texto: 'Cambiar o borrar', icono: Icons.edit_outlined, fontSize: 17, alto: 52, onTap: onOpciones),
        ],
      ),
    );
  }
}

/// "¿Qué quieres hacer?" con un trabajo: mover, cambiar datos, cambiar el cobro o borrar.
class OpcionesTrabajoScreen extends StatelessWidget {
  final VisitaAgenda trabajo;
  final bool elegirEquipo;
  final ValueChanged<DateTime>? onDiaGuardado;

  const OpcionesTrabajoScreen({super.key, required this.trabajo, this.elegirEquipo = false, this.onDiaGuardado});

  @override
  Widget build(BuildContext context) {
    final t = trabajo;
    final nav = Navigator.of(context);
    final cosa = t.esVenta ? 'esta venta' : 'este trabajo';

    void abrirAgendar({required bool soloFecha}) => nav.pushReplacement(MaterialPageRoute(
          builder: (_) => AgendarScreen(
            equipoId: t.equipoId,
            existente: t,
            soloCambiarFecha: soloFecha,
            elegirEquipo: elegirEquipo,
            onDiaGuardado: onDiaGuardado,
          ),
        ));

    return EncargadoPage(
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Encabezado(titulo: '¿Qué quieres hacer?', onAtras: () => nav.pop()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.cliente, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: EC.texto)),
                    Text(
                      '${t.tipo} · ${diaTexto(fechaDeKey(t.fecha))} · ${horaTexto(t.minutosDelDia)}'
                      '${t.completado ? '\nCobrado ${dinero(t.monto)}' : ''}',
                      style: const TextStyle(fontSize: 18, color: EC.textoSuave, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (t.completado)
                BotonGrande(
                  texto: 'Cambiar el cobro',
                  icono: Icons.payments_outlined,
                  alto: 78,
                  onTap: () => nav.pushReplacement(MaterialPageRoute(
                    builder: (_) => CobrarScreen(equipoId: t.equipoId, trabajo: t, cambiarCobro: true),
                  )),
                )
              else
                BotonGrande(
                  texto: 'Cambiar día u hora',
                  icono: Icons.edit_calendar_outlined,
                  alto: 78,
                  onTap: () => abrirAgendar(soloFecha: true),
                ),
              const SizedBox(height: 12),
              BotonGrande(texto: 'Cambiar los datos', icono: Icons.edit_outlined, alto: 78, onTap: () => abrirAgendar(soloFecha: false)),
              const SizedBox(height: 12),
              BotonGrande(
                texto: 'Borrar $cosa',
                icono: Icons.delete_outline,
                alto: 78,
                estilo: EstiloBoton.peligroSuave,
                onTap: () => nav.pushReplacement(MaterialPageRoute(
                  builder: (ctx) => PantallaBorrar(
                    pregunta: '¿Borrar ${t.esVenta ? 'la venta' : 'el trabajo'} de ${t.cliente}?',
                    detalle: '${t.tipo} · ${diaTexto(fechaDeKey(t.fecha))}'
                        '${t.completado ? '\nTambién se borra el cobro de ${dinero(t.monto)}' : ''}',
                    onBorrar: () {
                      final engine = ctx.read<AppEngineService>();
                      final index = engine.indexOfVisita(t.id);
                      final respaldo = t.copia();
                      engine.deleteVisitaAgenda(t.id);
                      Navigator.of(ctx).pushReplacement(MaterialPageRoute(
                        builder: (_) => PantallaListo(
                          titulo: 'Borrado',
                          mensaje: '${t.cliente} · ${t.tipo}',
                          onDeshacer: () => engine.insertVisitaAt(respaldo, index),
                        ),
                      ));
                    },
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
