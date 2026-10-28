import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_engine_service.dart';
import '../services/storage_service.dart';
import 'encargado/ui.dart';

/// Reportes del administrador: resumen del mes por equipo y archivo para Excel.
class RespaldosScreen extends StatefulWidget {
  const RespaldosScreen({super.key});

  @override
  State<RespaldosScreen> createState() => _RespaldosScreenState();
}

class _RespaldosScreenState extends State<RespaldosScreen> {
  DateTime _mes = DateTime(hoy().year, hoy().month);

  void _moverMes(int delta) => setState(() => _mes = DateTime(_mes.year, _mes.month + delta));

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final desde = fechaKey(_mes);
    final hasta = fechaKey(DateTime(_mes.year, _mes.month + 1, 0));
    final nombreMes = '${meses[_mes.month - 1][0].toUpperCase()}${meses[_mes.month - 1].substring(1)} ${_mes.year}';
    final esMesActual = !_mes.isBefore(DateTime(hoy().year, hoy().month));
    final nomina = engine.nominaEntre(desde, hasta);
    double quedo = 0;

    final tarjetas = <Widget>[];
    for (final e in ['equipo1', 'equipo2']) {
      final r = engine.resumen(e, desde, hasta);
      quedo += r.quedo;
      tarjetas.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: EC.bordeFuerte)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.groups_outlined, color: EC.textoSuave),
              const SizedBox(width: 8),
              Text(nombreEquipo(e), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
            ]),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.3,
              children: [
                DatoMonto(etiqueta: 'Trabajos', valor: dinero(r.trabajos)),
                DatoMonto(etiqueta: 'Ventas', valor: dinero(r.ventas)),
                DatoMonto(etiqueta: 'Gastos', valor: dinero(r.gastos), color: EC.peligroTexto),
                DatoMonto(etiqueta: 'Quedó', valor: dinero(r.quedo)),
              ],
            ),
          ],
        ),
      ));
    }

    return EncargadoPage(
      child: ColoredBox(
        color: EC.fondo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Reportes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
            Text('Así cerró el mes', style: TextStyle(fontSize: 18, color: EC.textoSuave)),
            const SizedBox(height: 14),
            SelectorConFlechas(
              texto: nombreMes,
              onAnterior: () => _moverMes(-1),
              onSiguiente: esMesActual ? null : () => _moverMes(1),
            ),
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
                  _linea('Quedó (cobrado − gastos)', dinero(quedo)),
                  _linea('Pago a trabajadores', nomina > 0 ? '−${dinero(nomina)}' : dinero(0),
                      color: nomina > 0 ? EC.peligroTexto : null),
                  const Divider(height: 20),
                  _linea('Ganancia del mes', dinero(quedo - nomina), grande: true),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Archivo para Excel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
            const SizedBox(height: 4),
            Text(
              'Trae el detalle del mes: ventas, gastos, trabajos, agenda y pagos al personal. '
              'Lo puedes mandar por WhatsApp o correo y abrirlo en Excel.',
              style: TextStyle(fontSize: 17, color: EC.textoSuave, height: 1.35),
            ),
            const SizedBox(height: 12),
            BotonGrande(
              texto: 'Compartir reporte de $nombreMes',
              icono: Icons.ios_share,
              estilo: EstiloBoton.primario,
              onTap: () => _compartir(context.read<StorageService>(), nombreMes),
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

  void _compartir(StorageService storage, String nombreMes) {
    final csv = storage.exportMonthlyCsv(_mes.year, _mes.month);
    Clipboard.setData(ClipboardData(text: csv));
    SharePlus.instance.share(
      ShareParams(
        text: csv,
        subject: 'Reporte Ay Oy $nombreMes.csv',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte copiado y listo para compartir', style: TextStyle(fontSize: 17)),
        backgroundColor: EC.exito,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
