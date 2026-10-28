import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_engine_service.dart';
import '../../services/auth_service.dart';
import 'gastos_screen.dart';
import 'trabajos_screen.dart';
import 'ui.dart';

enum DetalleResumen { efectivo, transferencia, gastos }

/// Resumen del equipo, de hoy o de una semana (domingo a sábado). Cada renglón
/// (Efectivo, Transferencia, Gastos) se despliega debajo de sí mismo con su detalle.
class ResumenEquipoScreen extends StatefulWidget {
  const ResumenEquipoScreen({super.key});

  @override
  State<ResumenEquipoScreen> createState() => _ResumenEquipoScreenState();
}

class _ResumenEquipoScreenState extends State<ResumenEquipoScreen> {
  final _abiertos = <DetalleResumen>{};
  bool _semana = false;
  DateTime _inicio = domingoDe(hoy());

  bool get _esEstaSemana => _inicio == domingoDe(hoy());

  /// "hoy", "esta semana" o "esa semana", para los textos.
  String get _cuando => !_semana ? 'hoy' : _esEstaSemana ? 'esta semana' : 'esa semana';

  String get _desde => _semana ? fechaKey(_inicio) : fechaKey(hoy());
  String get _hasta => _semana ? fechaKey(_inicio.add(const Duration(days: 6))) : fechaKey(hoy());

  void _alternar(DetalleResumen d) => setState(() => _abiertos.contains(d) ? _abiertos.remove(d) : _abiertos.add(d));

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final equipo = context.read<AuthService>().currentUser?.equipoId ?? 'equipo1';
    final r = engine.resumen(equipo, _desde, _hasta);
    final cuando = _cuando;
    // Si se gastó más de lo que se cobró, sale negativo y se pinta en rojo como los gastos.
    final quedo = r.efectivo + r.transferencia - r.gastos;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(_semana ? 'Resumen de la semana' : 'Resumen de hoy',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
        if (!_semana) Text(diaTexto(hoy()), style: TextStyle(fontSize: 18, color: EC.textoSuave)),
        const SizedBox(height: 12),
        _selectorPeriodo(),
        if (_semana) ...[
          const SizedBox(height: 10),
          SelectorConFlechas(
            texto: semanaTexto(_inicio),
            onAnterior: () => setState(() => _inicio = _inicio.subtract(const Duration(days: 7))),
            onSiguiente: _esEstaSemana ? null : () => setState(() => _inicio = _inicio.add(const Duration(days: 7))),
          ),
          if (!_esEstaSemana)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _inicio = domingoDe(hoy())),
                child: const Text('Volver a esta semana', style: TextStyle(fontSize: 17)),
              ),
            ),
        ],
        const SizedBox(height: 14),
        _seccion(DetalleResumen.efectivo, Icons.payments_outlined, 'Efectivo', dinero(r.efectivo), equipo),
        _seccion(DetalleResumen.transferencia, Icons.account_balance_outlined, 'Transferencia', dinero(r.transferencia), equipo),
        _seccion(DetalleResumen.gastos, Icons.receipt_long_outlined, 'Gastos', r.gastos > 0 ? '−${dinero(r.gastos)}' : dinero(0), equipo,
            color: EC.peligroTexto),
        Text('Toca un renglón para ver el detalle.', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Lo que quedó $cuando', style: TextStyle(fontSize: 20, color: EC.textoSuave)),
            Text(dinero(quedo),
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: quedo < 0 ? EC.peligroTexto : EC.texto)),
          ]),
        ),
        if (r.ventas > 0) ...[
          const SizedBox(height: 10),
          Text('De lo cobrado, ${dinero(r.ventas)} fueron ventas.', style: TextStyle(fontSize: 17, color: EC.textoSuave)),
        ],
      ],
    );
  }

  Widget _selectorPeriodo() {
    Widget opcion(bool semana, String texto, IconData icono) {
      final activa = _semana == semana;
      return Expanded(
        child: Material(
          color: activa ? EC.fondo : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: activa ? EC.bordeFuerte : Colors.transparent),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _semana = semana;
              if (semana) _inicio = domingoDe(hoy());
            }),
            child: SizedBox(
              height: 54,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icono, size: 22, color: activa ? EC.texto : EC.textoSuave),
                const SizedBox(width: 8),
                Text(texto,
                    style: TextStyle(fontSize: 19, fontWeight: activa ? FontWeight.w700 : FontWeight.w400, color: activa ? EC.texto : EC.textoSuave)),
              ]),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        opcion(false, 'Hoy', Icons.today_outlined),
        const SizedBox(width: 4),
        opcion(true, 'Semana', Icons.date_range_outlined),
      ]),
    );
  }

  Widget _seccion(DetalleResumen detalle, IconData icono, String texto, String valor, String equipo, {Color? color}) {
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
                  Expanded(child: Text(texto, style: TextStyle(fontSize: 21, color: EC.texto))),
                  Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color ?? EC.texto)),
                  AnimatedRotation(
                    turns: abierto ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, size: 30, color: EC.textoSuave),
                  ),
                ]),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: abierto ? _detalle(detalle, equipo) : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista que se despliega debajo del renglón. En la vista de semana se agrupa por día.
  Widget _detalle(DetalleResumen detalle, String equipo) {
    final engine = context.read<AppEngineService>();
    final esGastos = detalle == DetalleResumen.gastos;
    final filas = <Widget>[];
    String? diaAnterior;

    void encabezadoDia(String fecha, double totalDia) {
      if (!_semana || fecha == diaAnterior) return;
      diaAnterior = fecha;
      filas.add(Padding(
        padding: EdgeInsets.fromLTRB(4, filas.isEmpty ? 2 : 10, 4, 6),
        child: Row(children: [
          Expanded(
            child: Text(_nombreDia(fecha), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EC.texto)),
          ),
          Text(esGastos ? '−${dinero(totalDia)}' : dinero(totalDia),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: esGastos ? EC.peligroTexto : EC.textoSuave)),
        ]),
      ));
    }

    if (esGastos) {
      final gastos = engine.gastosEntre(equipo, _desde, _hasta);
      for (final g in gastos) {
        encabezadoDia(g.fecha, gastos.where((x) => x.fecha == g.fecha).fold<double>(0, (s, x) => s + x.monto));
        filas.add(_fila(
          icono: iconoDeCategoria(g.categoria),
          arriba: g.descripcion.isNotEmpty ? g.descripcion : g.categoria,
          abajo: g.descripcion.isNotEmpty && g.descripcion != g.categoria ? g.categoria : '',
          monto: '−${dinero(g.monto)}',
          color: EC.peligroTexto,
          onTap: () => abrirOpcionesGasto(context, g),
        ));
      }
    } else {
      final cobros = engine.cobrosEntre(equipo, _desde, _hasta, detalle.name);
      for (final t in cobros) {
        encabezadoDia(t.fecha, cobros.where((x) => x.fecha == t.fecha).fold<double>(0, (s, x) => s + x.monto));
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

    final cuando = _cuando;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: EC.superficie, border: Border(top: BorderSide(color: EC.borde))),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                esGastos
                    ? 'No hay gastos $cuando'
                    : 'No hay cobros ${detalle == DetalleResumen.efectivo ? 'en efectivo' : 'por transferencia'} $cuando',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: EC.textoSuave),
              ),
            )
          else ...[
            ...filas,
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                esGastos ? 'Toca un gasto para corregirlo o borrarlo.' : 'Toca un cobro para ver sus opciones.',
                style: TextStyle(fontSize: 15, color: EC.textoSuave),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _nombreDia(String fecha) {
    final d = fechaDeKey(fecha);
    final dif = diasEntre(hoy(), d);
    final nombre = '${diasLargos[d.weekday - 1]} ${d.day}';
    final capital = '${nombre[0].toUpperCase()}${nombre.substring(1)}';
    return dif == 0 ? 'Hoy, $nombre' : dif == -1 ? 'Ayer, $nombre' : capital;
  }

  Widget _fila({
    required IconData icono,
    required String arriba,
    required String abajo,
    required String monto,
    required VoidCallback onTap,
    Color? color,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: EC.fondo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: EC.borde)),
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
                    Text(arriba, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: EC.texto)),
                    if (abajo.isNotEmpty) Text(abajo, style: TextStyle(fontSize: 15, color: EC.textoSuave)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(monto, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color ?? EC.texto)),
              ]),
            ),
          ),
        ),
      );
}
