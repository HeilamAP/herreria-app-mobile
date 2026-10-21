import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_engine_service.dart';
import '../../services/auth_service.dart';
import 'gastos_screen.dart';
import 'trabajos_screen.dart';
import 'ui.dart';

enum DetalleResumen { efectivo, transferencia, gastos }

/// Resumen de hoy. Cada renglón (Efectivo, Transferencia, Gastos) se despliega
/// debajo de sí mismo para mostrar su detalle.
class ResumenEquipoScreen extends StatefulWidget {
  const ResumenEquipoScreen({super.key});

  @override
  State<ResumenEquipoScreen> createState() => _ResumenEquipoScreenState();
}

class _ResumenEquipoScreenState extends State<ResumenEquipoScreen> {
  final _abiertos = <DetalleResumen>{};

  void _alternar(DetalleResumen d) => setState(() => _abiertos.contains(d) ? _abiertos.remove(d) : _abiertos.add(d));

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final equipo = context.read<AuthService>().currentUser?.equipoId ?? 'equipo1';
    final dia = fechaKey(hoy());
    final r = engine.resumen(equipo, dia, dia);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('Resumen de hoy', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
        Text(diaTexto(hoy()), style: const TextStyle(fontSize: 18, color: EC.textoSuave)),
        const SizedBox(height: 16),
        _seccion(DetalleResumen.efectivo, Icons.payments_outlined, 'Efectivo', dinero(r.efectivo), equipo, dia),
        _seccion(DetalleResumen.transferencia, Icons.account_balance_outlined, 'Transferencia', dinero(r.transferencia), equipo, dia),
        _seccion(DetalleResumen.gastos, Icons.receipt_long_outlined, 'Gastos', r.gastos > 0 ? '−${dinero(r.gastos)}' : dinero(0), equipo, dia,
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

  Widget _seccion(DetalleResumen detalle, IconData icono, String texto, String valor, String equipo, String dia,
      {Color color = EC.texto}) {
    final abierto = _abiertos.contains(detalle);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: EC.fondo,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: abierto ? EC.acento : EC.bordeFuerte, width: abierto ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _alternar(detalle),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Row(children: [
                  Icon(icono, size: 28, color: EC.textoSuave),
                  const SizedBox(width: 12),
                  Expanded(child: Text(texto, style: const TextStyle(fontSize: 21, color: EC.texto))),
                  Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
                  AnimatedRotation(
                    turns: abierto ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right, size: 30, color: EC.textoSuave),
                  ),
                ]),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: abierto ? _detalle(detalle, equipo, dia) : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista que se despliega debajo del renglón: los cobros o los gastos del día.
  Widget _detalle(DetalleResumen detalle, String equipo, String dia) {
    final engine = context.read<AppEngineService>();
    final esGastos = detalle == DetalleResumen.gastos;
    final filas = <Widget>[];

    if (esGastos) {
      for (final g in engine.gastosDelDia(equipo, dia)) {
        filas.add(_fila(
          icono: iconoDeCategoria(g.categoria),
          arriba: g.descripcion.isNotEmpty ? g.descripcion : g.categoria,
          abajo: g.descripcion.isNotEmpty && g.descripcion != g.categoria ? g.categoria : '',
          monto: '−${dinero(g.monto)}',
          color: EC.peligroTexto,
          onTap: () => borrarGastoConConfirmacion(context, g),
        ));
      }
    } else {
      for (final t in engine.cobrosDelDia(equipo, dia, detalle.name)) {
        filas.add(_fila(
          icono: iconoDeTipo(t.tipo),
          arriba: t.cliente,
          abajo: '${horaTexto(t.minutosDelDia)} ${parteDelDia(t.minutosDelDia ~/ 60)} · ${t.tipo}'
              '${t.notas.isNotEmpty ? ' · ${t.notas}' : ''}',
          monto: dinero(t.monto),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OpcionesTrabajoScreen(trabajo: t, elegirEquipo: true),
          )),
        ));
      }
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: EC.superficie, border: Border(top: BorderSide(color: EC.borde))),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                esGastos
                    ? 'Hoy no has anotado gastos'
                    : 'Hoy no hay cobros ${detalle == DetalleResumen.efectivo ? 'en efectivo' : 'por transferencia'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: EC.textoSuave),
              ),
            )
          else ...[
            ...filas,
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                esGastos ? 'Toca un gasto si quieres borrarlo.' : 'Toca un cobro para cambiarlo o borrarlo.',
                style: const TextStyle(fontSize: 15, color: EC.textoSuave),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fila({
    required IconData icono,
    required String arriba,
    required String abajo,
    required String monto,
    required VoidCallback onTap,
    Color color = EC.texto,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: EC.fondo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: EC.borde)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(icono, size: 26, color: EC.textoSuave),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(arriba, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: EC.texto)),
                    if (abajo.isNotEmpty) Text(abajo, style: const TextStyle(fontSize: 15, color: EC.textoSuave)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(monto, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              ]),
            ),
          ),
        ),
      );
}
