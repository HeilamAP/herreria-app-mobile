import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_engine_service.dart';
import '../services/auth_service.dart';
import 'encargado/gastos_screen.dart';
import 'encargado/ui.dart';

/// Inicio del administrador: una tarjeta por equipo con trabajos, ventas, gastos y lo que quedó.
class AdminInicioScreen extends StatefulWidget {
  const AdminInicioScreen({super.key});

  @override
  State<AdminInicioScreen> createState() => _AdminInicioScreenState();
}

class _AdminInicioScreenState extends State<AdminInicioScreen> {
  String _periodo = 'semana'; // hoy | semana | mes

  (String, String, String) _rango() {
    final h = hoy();
    return switch (_periodo) {
      'hoy' => (fechaKey(h), fechaKey(h), 'Así va el día'),
      'mes' => (fechaKey(DateTime(h.year, h.month, 1)), fechaKey(DateTime(h.year, h.month + 1, 0)), 'Así va el mes'),
      _ => (
          fechaKey(h.subtract(Duration(days: h.weekday - 1))),
          fechaKey(h.add(Duration(days: 7 - h.weekday))),
          'Así va la semana',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final nombre = context.read<AuthService>().currentUser?.nombre.split(' ').first ?? '';
    final (desde, hasta, subtitulo) = _rango();
    final hoyKey = fechaKey(hoy());
    final nomina = engine.nominaEntre(desde, hasta);
    double totalQuedo = 0;

    final tarjetas = <Widget>[];
    for (final e in ['equipo1', 'equipo2']) {
      final r = engine.resumen(e, desde, hasta);
      totalQuedo += r.quedo;
      final encargado = engine.data.usuarios.where((u) => u.equipoId == e && !u.isAdmin).map((u) => u.nombre).firstOrNull ?? '';
      final pendientes = engine.pendientesEn(e, hoyKey);
      tarjetas.add(_TarjetaEquipo(
        titulo: '${nombreEquipo(e)}${encargado.isNotEmpty ? ' · $encargado' : ''}',
        resumen: r,
        pendientesHoy: pendientes,
        // El administrador puede anotar gastos de cualquier equipo y sin límite.
        onAnotarGasto: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NuevoGastoScreen(equipoId: e))),
      ));
      tarjetas.add(const SizedBox(height: 14));
    }

    return EncargadoPage(
      child: ColoredBox(
        color: EC.fondo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Hola, $nombre', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
            Text(subtitulo, style: TextStyle(fontSize: 18, color: EC.textoSuave)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final p in [('hoy', 'Hoy'), ('semana', 'Esta semana'), ('mes', 'Este mes')])
                ChoiceChip(
                  label: Text(p.$2, style: const TextStyle(fontSize: 16)),
                  selected: _periodo == p.$1,
                  onSelected: (_) => setState(() => _periodo = p.$1),
                ),
            ]),
            const SizedBox(height: 14),
            ...tarjetas,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Los dos equipos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: EC.texto)),
                  const SizedBox(height: 8),
                  _linea('Quedó (cobrado − gastos)', dinero(totalQuedo), color: totalQuedo < 0 ? EC.peligroTexto : null),
                  _linea('Pago a trabajadores', nomina > 0 ? '−${dinero(nomina)}' : dinero(0),
                      color: nomina > 0 ? EC.peligroTexto : null),
                  const Divider(height: 20),
                  _linea('Ganancia', dinero(totalQuedo - nomina),
                      grande: true, color: totalQuedo - nomina < 0 ? EC.peligroTexto : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linea(String texto, String valor, {Color? color, bool grande = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(texto, style: TextStyle(fontSize: grande ? 19 : 17, color: EC.textoSuave))),
          Text(valor, style: TextStyle(fontSize: grande ? 26 : 19, fontWeight: FontWeight.w700, color: color ?? EC.texto)),
        ]),
      );
}

class _TarjetaEquipo extends StatelessWidget {
  final String titulo;
  final ResumenEquipo resumen;
  final int pendientesHoy;
  final VoidCallback onAnotarGasto;

  const _TarjetaEquipo({required this.titulo, required this.resumen, required this.pendientesHoy, required this.onAnotarGasto});

  @override
  Widget build(BuildContext context) {
    Widget dato(String etiqueta, double valor, {Color? color}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: TextStyle(fontSize: 15, color: EC.textoSuave)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(dinero(valor), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color ?? EC.texto)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: EC.bordeFuerte)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.groups_outlined, color: EC.textoSuave),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto))),
          ]),
          Text(
            pendientesHoy == 0 ? 'Sin trabajos pendientes hoy' : '$pendientesHoy pendiente${pendientesHoy == 1 ? '' : 's'} hoy',
            style: TextStyle(fontSize: 16, color: EC.textoSuave),
          ),
          const SizedBox(height: 10),
          // Dos filas de dos cuadros; el alto se ajusta al texto para que el monto nunca se corte.
          Row(children: [
            Expanded(child: dato('Trabajos', resumen.trabajos)),
            const SizedBox(width: 8),
            Expanded(child: dato('Ventas', resumen.ventas)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: dato('Gastos', resumen.gastos, color: EC.peligroTexto)),
            const SizedBox(width: 8),
            Expanded(child: dato('Quedó', resumen.quedo, color: resumen.quedo < 0 ? EC.peligroTexto : null)),
          ]),
          const SizedBox(height: 12),
          BotonGrande(texto: 'Anotar gasto', icono: Icons.receipt_long_outlined, alto: 54, fontSize: 18, onTap: onAnotarGasto),
        ],
      ),
    );
  }
}
