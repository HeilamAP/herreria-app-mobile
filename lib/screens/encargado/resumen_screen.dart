import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_engine_service.dart';
import '../../services/auth_service.dart';
import 'gastos_screen.dart';
import 'trabajos_screen.dart';
import 'ui.dart';

enum DetalleResumen { efectivo, transferencia, gastos }

class ResumenEquipoScreen extends StatelessWidget {
  const ResumenEquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final equipo = context.read<AuthService>().currentUser?.equipoId ?? 'equipo1';
    final dia = fechaKey(hoy());
    final r = engine.resumen(equipo, dia, dia);

    Widget fila(DetalleResumen detalle, IconData icono, String texto, String valor, {Color color = EC.texto}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: EC.fondo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: EC.bordeFuerte)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetalleResumenScreen(detalle: detalle))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Row(children: [
                  Icon(icono, size: 28, color: EC.textoSuave),
                  const SizedBox(width: 12),
                  Expanded(child: Text(texto, style: const TextStyle(fontSize: 21, color: EC.texto))),
                  Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
                  const Icon(Icons.chevron_right, size: 30, color: EC.textoSuave),
                ]),
              ),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('Resumen de hoy', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
        Text(diaTexto(hoy()), style: const TextStyle(fontSize: 18, color: EC.textoSuave)),
        const SizedBox(height: 16),
        fila(DetalleResumen.efectivo, Icons.payments_outlined, 'Efectivo', dinero(r.efectivo)),
        fila(DetalleResumen.transferencia, Icons.account_balance_outlined, 'Transferencia', dinero(r.transferencia)),
        fila(DetalleResumen.gastos, Icons.receipt_long_outlined, 'Gastos', r.gastos > 0 ? '−${dinero(r.gastos)}' : dinero(0),
            color: EC.peligroTexto),
        const Text('Toca un renglón para ver el detalle.', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lo que quedó hoy', style: TextStyle(fontSize: 20, color: EC.textoSuave)),
            Text(dinero(r.efectivo + r.transferencia - r.gastos),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: EC.texto)),
          ]),
        ),
        if (r.ventas > 0) ...[
          const SizedBox(height: 10),
          Text('De lo cobrado, ${dinero(r.ventas)} fueron ventas.', style: const TextStyle(fontSize: 17, color: EC.textoSuave)),
        ],
      ],
    );
  }
}

/// Detalle de un renglón del Resumen de hoy: los cobros en efectivo, por transferencia o los gastos.
class DetalleResumenScreen extends StatelessWidget {
  final DetalleResumen detalle;
  const DetalleResumenScreen({super.key, required this.detalle});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final equipo = context.read<AuthService>().currentUser?.equipoId ?? 'equipo1';
    final dia = fechaKey(hoy());
    final esGastos = detalle == DetalleResumen.gastos;

    final titulo = switch (detalle) {
      DetalleResumen.efectivo => 'Cobrado en efectivo',
      DetalleResumen.transferencia => 'Cobrado por transferencia',
      DetalleResumen.gastos => 'Gastos de hoy',
    };
    final cobros = esGastos ? const [] : engine.cobrosDelDia(equipo, dia, detalle.name);
    final gastos = esGastos ? engine.gastosDelDia(equipo, dia) : const [];
    final total = esGastos
        ? gastos.fold<double>(0, (s, g) => s + g.monto)
        : cobros.fold<double>(0, (s, t) => s + t.monto);
    final vacio = esGastos ? gastos.isEmpty : cobros.isEmpty;

    Widget renglon({required IconData icono, required String arriba, required String abajo, required String monto, required VoidCallback onTap, Color color = EC.texto}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: EC.fondo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: EC.bordeFuerte)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(icono, size: 28, color: EC.textoSuave),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(arriba, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
                      if (abajo.isNotEmpty) Text(abajo, style: const TextStyle(fontSize: 16, color: EC.textoSuave)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(monto, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                ]),
              ),
            ),
          ),
        );

    return EncargadoPage(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Encabezado(titulo: titulo, paso: diaTexto(hoy()), onAtras: () => Navigator.of(context).pop()),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          esGastos
                              ? '${gastos.length} ${gastos.length == 1 ? 'gasto' : 'gastos'}'
                              : '${cobros.length} ${cobros.length == 1 ? 'cobro' : 'cobros'}',
                          style: const TextStyle(fontSize: 19, color: EC.textoSuave),
                        ),
                      ),
                      Text(esGastos && total > 0 ? '−${dinero(total)}' : dinero(total),
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: esGastos ? EC.peligroTexto : EC.texto)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  if (vacio)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        esGastos ? 'Hoy no has anotado gastos' : 'Hoy no hay cobros ${detalle == DetalleResumen.efectivo ? 'en efectivo' : 'por transferencia'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 19, color: EC.textoSuave),
                      ),
                    ),
                  for (final t in cobros)
                    renglon(
                      icono: iconoDeTipo(t.tipo),
                      arriba: t.cliente,
                      abajo: '${horaTexto(t.minutosDelDia)} ${parteDelDia(t.minutosDelDia ~/ 60)} · ${t.tipo}'
                          '${t.notas.isNotEmpty ? ' · ${t.notas}' : ''}',
                      monto: dinero(t.monto),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => OpcionesTrabajoScreen(trabajo: t, elegirEquipo: true),
                      )),
                    ),
                  for (final g in gastos)
                    renglon(
                      icono: iconoDeCategoria(g.categoria),
                      arriba: g.descripcion.isNotEmpty ? g.descripcion : g.categoria,
                      abajo: g.descripcion.isNotEmpty && g.descripcion != g.categoria ? g.categoria : '',
                      monto: '−${dinero(g.monto)}',
                      color: EC.peligroTexto,
                      onTap: () => borrarGastoConConfirmacion(context, g),
                    ),
                  if (!vacio)
                    Text(
                      esGastos ? 'Toca un gasto si quieres borrarlo.' : 'Toca un cobro para cambiarlo o borrarlo.',
                      style: const TextStyle(fontSize: 16, color: EC.textoSuave),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
