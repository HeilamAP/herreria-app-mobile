import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/marca.dart';
import '../../models/visita_agenda.dart';
import '../../services/app_engine_service.dart';
import '../../services/ubicacion.dart';
import 'ui.dart';

String _horaDe(DateTime d) => '${horaTexto(d.hour * 60 + d.minute)} ${parteDelDia(d.hour).replaceFirst('de la ', '')}';

String _metros(double m) => m < 1000 ? '${(m / 10).round() * 10} m' : '${(m / 1000).toStringAsFixed(1)} km';

/// Tiempo real (no redondeado a medias horas como en el horario): "1 h 12 min".
String _tiempo(int min) => min < 60 ? '$min min' : '${min ~/ 60} h${min % 60 == 0 ? '' : ' ${min % 60} min'}';

/// "Llegué": guarda la hora y el lugar de llegada. Después muestra a qué hora llegaron.
class BotonLlegue extends StatefulWidget {
  final VisitaAgenda trabajo;
  const BotonLlegue({super.key, required this.trabajo});

  @override
  State<BotonLlegue> createState() => _BotonLlegueState();
}

class _BotonLlegueState extends State<BotonLlegue> {
  late Marca? _llegada = widget.trabajo.llegada;
  bool _ocupado = false;

  Future<void> _marcar() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final engine = context.read<AppEngineService>();
    final marca = await tomarMarca(engine, widget.trabajo.id);
    engine.marcarLlegada(widget.trabajo.id, marca);
    if (mounted) {
      setState(() {
        _llegada = marca;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final llegada = _llegada;
    if (llegada != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EC.exitoFondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EC.exitoBorde),
        ),
        child: Row(children: [
          Icon(Icons.where_to_vote_outlined, color: EC.exitoTexto, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Llegaste a las ${_horaDe(llegada.hora)}',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: EC.exitoTexto)),
          ),
        ]),
      );
    }
    return BotonGrande(
      texto: _ocupado ? 'Guardando tu ubicación…' : 'Llegué',
      icono: _ocupado ? Icons.hourglass_top : Icons.where_to_vote_outlined,
      estilo: EstiloBoton.acentoSuave,
      onTap: _ocupado ? null : _marcar,
    );
  }
}

/// Lo que ve el administrador: a qué hora llegaron y terminaron, y si las marcas
/// (llegada, cobro y fotos) se hicieron en el domicilio.
class EvidenciaTrabajo extends StatelessWidget {
  final VisitaAgenda trabajo;
  const EvidenciaTrabajo({super.key, required this.trabajo});

  @override
  Widget build(BuildContext context) {
    final t = trabajo;
    final marcas = <(String, Marca)>[
      if (t.llegada != null) ('La llegada', t.llegada!),
      if (t.salida != null) ('El cobro', t.salida!),
      for (final f in t.fotos)
        if (t.marcasFotos[f] != null) ('Una foto', t.marcasFotos[f]!),
    ];
    if (marcas.isEmpty) return const SizedBox.shrink();

    final filas = <Widget>[];
    void fila(IconData icono, Color color, String texto, [String? detalle]) => filas.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icono, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(texto, style: TextStyle(fontSize: 17, color: EC.texto)),
                if (detalle != null) Text(detalle, style: TextStyle(fontSize: 15, color: EC.textoSuave)),
              ]),
            ),
          ]),
        ));

    // Horas
    final llegada = t.llegada, salida = t.salida;
    if (llegada != null || salida != null) {
      final partes = [
        if (llegada != null) 'Llegaron ${_horaDe(llegada.hora)}',
        if (salida != null) 'Cobraron ${_horaDe(salida.hora)}',
      ];
      final dur = llegada != null && salida != null ? salida.hora.difference(llegada.hora).inMinutes : null;
      fila(Icons.schedule, EC.textoSuave, partes.join(' · '),
          dur != null && dur >= 0 ? '${_tiempo(dur)} en el trabajo' : null);
    }

    // Ubicación falsa: lo más grave.
    final falsas = marcas.where((m) => m.$2.falsa).toList();
    if (falsas.isNotEmpty) {
      fila(Icons.gpp_bad_outlined, EC.peligroTexto, 'Se usó una app para falsear la ubicación',
          '${falsas.map((m) => m.$1.toLowerCase()).toSet().join(', ')}. Revisa con el equipo.');
    }

    final conGps = marcas.where((m) => m.$2.conGps && !m.$2.falsa).toList();
    final sinGps = marcas.length - conGps.length - falsas.length;
    if (!t.domicilioUbicado) {
      if (conGps.isNotEmpty) {
        fila(Icons.location_searching, EC.textoSuave, 'No se pudo comparar con la dirección',
            'La dirección no se encontró en el mapa (o no había internet).');
      }
    } else {
      final lejos = <(String, double)>[];
      var enCasa = 0;
      for (final m in conGps) {
        final d = distanciaAlDomicilio(t, m.$2)!;
        if (d <= radioDomicilioM) {
          enCasa++;
        } else if (d > avisoLejosM) {
          lejos.add((m.$1, d));
        }
      }
      for (final l in lejos) {
        fila(Icons.wrong_location_outlined, EC.peligroTexto, '${l.$1} se marcó a ${_metros(l.$2)} del domicilio',
            'Revisa con el equipo antes de darla por buena.');
      }
      if (enCasa > 0) {
        fila(Icons.where_to_vote_outlined, EC.exitoTexto,
            enCasa == conGps.length ? 'Todo se marcó en el domicilio' : '$enCasa de ${conGps.length} marcas en el domicilio',
            'A menos de ${radioDomicilioM.round()} m de la dirección del trabajo');
      }
    }
    if (sinGps > 0) {
      fila(Icons.location_disabled_outlined, EC.textoSuave,
          sinGps == 1 ? '1 marca sin ubicación' : '$sinGps marcas sin ubicación', 'Sin permiso o sin señal de GPS; solo tienen la hora.');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.verified_outlined, size: 22, color: EC.textoSuave),
          const SizedBox(width: 8),
          Text('Evidencia', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: EC.texto)),
        ]),
        const SizedBox(height: 4),
        ...filas,
      ]),
    );
  }
}
