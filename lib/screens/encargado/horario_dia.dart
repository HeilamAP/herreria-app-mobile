import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/visita_agenda.dart';
import 'ui.dart';

/// Vista de horario de un día (8 am a 6 pm) con una columna por equipo.
/// Cada trabajo ocupa el alto de lo que dura; tocar un hueco permite agendar a esa hora.
class HorarioDia extends StatefulWidget {
  final List<VisitaAgenda> trabajos;
  final List<String> equipos;
  final String? equipoPropio;
  final bool esHoy;
  final ValueChanged<VisitaAgenda> onTrabajo;
  final void Function(String equipo, int minuto) onHueco;

  const HorarioDia({
    super.key,
    required this.trabajos,
    required this.equipos,
    required this.equipoPropio,
    required this.esHoy,
    required this.onTrabajo,
    required this.onHueco,
  });

  static const inicio = 8 * 60;
  static const fin = 18 * 60;

  @override
  State<HorarioDia> createState() => _HorarioDiaState();
}

class _HorarioDiaState extends State<HorarioDia> {
  static const _pxHora = 76.0;
  static const _anchoHoras = 52.0;
  static const _margenArriba = 10.0;
  static const _separacion = 6.0;

  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    // Mueve la línea de "ahora" cada minuto.
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && widget.esHoy) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  double _y(int minuto) => _margenArriba + (minuto - HorarioDia.inicio) / 60 * _pxHora;

  String _etiquetaHora(int h) => h == 12 ? '12 pm' : h < 12 ? '$h am' : '${h - 12} pm';

  bool _dentro(VisitaAgenda t) => t.finMinutos > HorarioDia.inicio && t.minutosDelDia < HorarioDia.fin;

  @override
  Widget build(BuildContext context) {
    final antes = widget.trabajos.where((t) => !_dentro(t) && t.minutosDelDia < HorarioDia.inicio).toList();
    final despues = widget.trabajos.where((t) => !_dentro(t) && t.minutosDelDia >= HorarioDia.fin).toList();
    final altoTotal = _y(HorarioDia.fin) + 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (antes.isNotEmpty) _fueraDeHorario('Antes de las 8 am', antes),
        // Nombres de las columnas
        Padding(
          padding: const EdgeInsets.only(left: _anchoHoras, bottom: 4),
          child: Row(children: [
            for (final e in widget.equipos) ...[
              if (e != widget.equipos.first) const SizedBox(width: _separacion),
              Expanded(
                child: Text(
                  e == widget.equipoPropio ? '${nombreEquipo(e)} (tú)' : nombreEquipo(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _colores(e).$3),
                ),
              ),
            ],
          ]),
        ),
        SizedBox(
          height: altoTotal,
          child: LayoutBuilder(builder: (context, c) {
            final n = widget.equipos.length;
            final anchoCol = (c.maxWidth - _anchoHoras - _separacion * (n - 1)) / n;
            double xCol(int i) => _anchoHoras + i * (anchoCol + _separacion);

            final hijos = <Widget>[];
            // Líneas de cada hora y media hora
            for (var m = HorarioDia.inicio; m <= HorarioDia.fin; m += 30) {
              final enPunto = m % 60 == 0;
              hijos.add(Positioned(
                top: _y(m),
                left: _anchoHoras - 4,
                right: 0,
                child: Container(height: enPunto ? 1 : 0.5, color: enPunto ? EC.borde : EC.superficie),
              ));
              if (enPunto) {
                hijos.add(Positioned(
                  top: _y(m) - 10,
                  left: 0,
                  width: _anchoHoras - 8,
                  child: Text(_etiquetaHora(m ~/ 60),
                      textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, color: EC.textoSuave, fontWeight: FontWeight.w600)),
                ));
              }
            }
            // Zona tocable de cada columna (para agendar en un hueco)
            for (var i = 0; i < n; i++) {
              final equipo = widget.equipos[i];
              hijos.add(Positioned(
                top: _y(HorarioDia.inicio),
                left: xCol(i),
                width: anchoCol,
                height: _y(HorarioDia.fin) - _y(HorarioDia.inicio),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final media = (d.localPosition.dy / _pxHora * 2).floor();
                    final minuto = (HorarioDia.inicio + media * 30).clamp(HorarioDia.inicio, HorarioDia.fin - 30);
                    widget.onHueco(equipo, minuto);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: i.isOdd ? const Color(0x08000000) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ));
            }
            // Bloques de trabajos
            for (var i = 0; i < n; i++) {
              final equipo = widget.equipos[i];
              final delEquipo = widget.trabajos.where((t) => t.equipoId == equipo && _dentro(t)).toList();
              for (final c in _carriles(delEquipo)) {
                final t = c.trabajo;
                final ini = math.max(t.minutosDelDia, HorarioDia.inicio);
                final finT = math.min(t.finMinutos, HorarioDia.fin);
                final anchoCarril = (anchoCol - 3 * (c.total - 1)) / c.total;
                hijos.add(Positioned(
                  top: _y(ini) + 1,
                  left: xCol(i) + c.carril * (anchoCarril + 3),
                  width: anchoCarril,
                  height: math.max(_y(finT) - _y(ini) - 3, 34),
                  child: _bloque(t),
                ));
              }
            }
            // Línea de la hora actual
            if (widget.esHoy) {
              final ahora = DateTime.now();
              final m = ahora.hour * 60 + ahora.minute;
              if (m >= HorarioDia.inicio && m <= HorarioDia.fin) {
                hijos.add(Positioned(
                  top: _y(m) - 1,
                  left: _anchoHoras - 6,
                  right: 0,
                  child: IgnorePointer(
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: EC.peligro, shape: BoxShape.circle)),
                      Expanded(child: Container(height: 2, color: EC.peligro)),
                    ]),
                  ),
                ));
              }
            }
            return Stack(clipBehavior: Clip.none, children: hijos);
          }),
        ),
        if (despues.isNotEmpty) _fueraDeHorario('Después de las 6 pm', despues),
        const SizedBox(height: 6),
        const Text('Toca un espacio libre para agendar a esa hora.', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
      ],
    );
  }

  /// (fondo, borde, texto) para un trabajo según el equipo.
  (Color, Color, Color) _colores(String equipo) => equipo == widget.equipoPropio || (widget.equipoPropio == null && equipo == 'equipo1')
      ? (EC.acentoFondo, EC.acento, EC.acentoTexto)
      : (const Color(0xFFE1F5EE), const Color(0xFF1D9E75), const Color(0xFF085041));

  Widget _bloque(VisitaAgenda t) {
    var (fondo, borde, texto) = _colores(t.equipoId);
    if (t.completado) (fondo, borde, texto) = (EC.exitoFondo, EC.exitoBorde, EC.exitoTexto);
    return Material(
      color: fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: borde)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onTrabajo(t),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: LayoutBuilder(builder: (context, c) {
            final corto = c.maxHeight < 50;
            final titulo = Text.rich(
              TextSpan(children: [
                if (t.completado) const WidgetSpan(child: Padding(padding: EdgeInsets.only(right: 3), child: Icon(Icons.check_circle, size: 15, color: EC.exitoTexto))),
                TextSpan(text: '${horaTexto(t.minutosDelDia)} ', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (corto) TextSpan(text: t.cliente),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, color: texto),
            );
            if (corto) return Align(alignment: Alignment.centerLeft, child: titulo);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              titulo,
              Text(t.cliente,
                  maxLines: c.maxHeight > 90 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: texto, height: 1.15)),
              if (c.maxHeight > 74)
                Text(t.tipo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: texto)),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _fueraDeHorario(String titulo, List<VisitaAgenda> lista) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EC.textoSuave)),
          const SizedBox(height: 4),
          for (final t in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(height: 46, child: _bloque(t)),
            ),
        ]),
      );

  /// Reparte en carriles los trabajos que se enciman, para que se vean lado a lado.
  List<_Carril> _carriles(List<VisitaAgenda> lista) {
    final ordenados = [...lista]..sort((a, b) => a.minutosDelDia.compareTo(b.minutosDelDia));
    final resultado = <_Carril>[];
    var grupo = <_Carril>[];
    var finesCarril = <int>[];
    var finGrupo = -1;

    void cerrarGrupo() {
      for (final c in grupo) {
        c.total = finesCarril.length;
      }
      resultado.addAll(grupo);
      grupo = [];
      finesCarril = [];
    }

    for (final t in ordenados) {
      if (grupo.isNotEmpty && t.minutosDelDia >= finGrupo) cerrarGrupo();
      var carril = finesCarril.indexWhere((f) => f <= t.minutosDelDia);
      if (carril == -1) {
        finesCarril.add(t.finMinutos);
        carril = finesCarril.length - 1;
      } else {
        finesCarril[carril] = t.finMinutos;
      }
      grupo.add(_Carril(t, carril));
      finGrupo = math.max(finGrupo, t.finMinutos);
    }
    cerrarGrupo();
    return resultado;
  }
}

class _Carril {
  final VisitaAgenda trabajo;
  final int carril;
  int total = 1;
  _Carril(this.trabajo, this.carril);
}
