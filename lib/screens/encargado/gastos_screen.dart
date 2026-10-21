import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gasto.dart';
import '../../services/app_engine_service.dart';
import '../../services/auth_service.dart';
import 'ui.dart';

const categoriasGasto = <(String, IconData)>[
  ('Material', Icons.construction_outlined),
  ('Gasolina', Icons.local_gas_station_outlined),
  ('Comida', Icons.restaurant_outlined),
  ('Herramienta', Icons.hardware_outlined),
  ('Refacción', Icons.settings_outlined),
  ('Otro', Icons.more_horiz),
];

IconData iconoDeCategoria(String c) =>
    categoriasGasto.firstWhere((x) => x.$1.toLowerCase() == c.toLowerCase(), orElse: () => categoriasGasto.last).$2;

class GastosEquipoScreen extends StatelessWidget {
  const GastosEquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AppEngineService>();
    final equipo = context.read<AuthService>().currentUser?.equipoId ?? 'equipo1';
    final gastos = engine.gastosDelDia(equipo, fechaKey(hoy()));
    final total = gastos.fold<double>(0, (s, g) => s + g.monto);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('Gastos de hoy', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: EC.texto)),
        Text(diaTexto(hoy()), style: const TextStyle(fontSize: 18, color: EC.textoSuave)),
        const SizedBox(height: 14),
        BotonGrande(
          texto: 'Anotar gasto',
          icono: Icons.add,
          estilo: EstiloBoton.primario,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NuevoGastoScreen(equipoId: equipo))),
        ),
        const SizedBox(height: 14),
        if (gastos.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: EC.superficie, borderRadius: BorderRadius.circular(16)),
            child: const Text('Hoy no has anotado gastos', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, color: EC.textoSuave)),
          ),
        for (final g in gastos) ...[
          Material(
            color: EC.fondo,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: EC.bordeFuerte)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => abrirOpcionesGasto(context, g),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(children: [
                  Icon(iconoDeCategoria(g.categoria), size: 30, color: EC.textoSuave),
                  const SizedBox(width: 12),
                  Expanded(child: Text(g.descripcion.isNotEmpty ? g.descripcion : g.categoria, style: const TextStyle(fontSize: 21, color: EC.texto))),
                  Text(dinero(g.monto), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: EC.peligroTexto)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (gastos.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Total: ${dinero(total)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EC.texto)),
          const SizedBox(height: 6),
          const Text('Toca un gasto para corregirlo o borrarlo.', style: TextStyle(fontSize: 16, color: EC.textoSuave)),
        ],
      ],
    );
  }

}

/// Al tocar un gasto ya registrado: corregirlo (con sus datos escritos) o borrarlo.
void abrirOpcionesGasto(BuildContext context, Gasto g) {
  showModalBottomSheet(
    context: context,
    backgroundColor: EC.fondo,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => EncargadoPage(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(iconoDeCategoria(g.categoria), size: 30, color: EC.textoSuave),
              const SizedBox(width: 10),
              Expanded(
                child: Text(g.descripcion.isNotEmpty ? g.descripcion : g.categoria,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: EC.texto)),
              ),
              Text(dinero(g.monto), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: EC.peligroTexto)),
            ]),
            Text(diaTexto(fechaDeKey(g.fecha)), style: const TextStyle(fontSize: 17, color: EC.textoSuave)),
            const SizedBox(height: 18),
            BotonGrande(
              texto: 'Corregir este gasto',
              icono: Icons.edit_outlined,
              alto: 64,
              estilo: EstiloBoton.acentoSuave,
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => NuevoGastoScreen(equipoId: g.equipoId, existente: g),
                ));
              },
            ),
            const SizedBox(height: 10),
            BotonGrande(
              texto: 'Borrar este gasto',
              icono: Icons.delete_outline,
              alto: 64,
              estilo: EstiloBoton.peligroSuave,
              onTap: () {
                Navigator.of(ctx).pop();
                borrarGastoConConfirmacion(context, g);
              },
            ),
            const SizedBox(height: 10),
            BotonGrande(texto: 'Cerrar', fontSize: 18, alto: 52, onTap: () => Navigator.of(ctx).pop()),
          ]),
        ),
      ),
    ),
  );
}

/// Pregunta si se borra el gasto y deja "deshacer" en la pantalla de confirmación.
void borrarGastoConConfirmacion(BuildContext context, Gasto g) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => PantallaBorrar(
        pregunta: '¿Borrar este gasto?',
        detalle: '${g.descripcion.isNotEmpty ? g.descripcion : g.categoria} · ${dinero(g.monto)}',
        onBorrar: () {
          final engine = ctx.read<AppEngineService>();
          final index = engine.indexOfGasto(g.id);
          engine.deleteGasto(g.id);
          Navigator.of(ctx).pushReplacement(MaterialPageRoute(
            builder: (_) => PantallaListo(
              titulo: 'Borrado',
              mensaje: '${g.categoria} · ${dinero(g.monto)}',
              onDeshacer: () => engine.insertGastoAt(g, index),
            ),
          ));
        },
      ),
    ));
}

/// Anotar un gasto (categoría → monto). Con [existente] se corrige un gasto ya
/// guardado: abre en el monto con la categoría elegida y guarda encima.
class NuevoGastoScreen extends StatefulWidget {
  final String equipoId;
  final Gasto? existente;
  const NuevoGastoScreen({super.key, required this.equipoId, this.existente});

  @override
  State<NuevoGastoScreen> createState() => _NuevoGastoScreenState();
}

class _NuevoGastoScreenState extends State<NuevoGastoScreen> {
  String? _categoria;
  String? _ultimaCategoria; // se marca al regresar a elegir categoría
  String _monto = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.existente;
    if (g != null) {
      _categoria = _ultimaCategoria = g.categoria;
      _monto = g.monto.round().toString();
    }
  }

  void _atras() {
    if (_categoria == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _categoria = null;
        _error = null;
      });
    }
  }

  void _guardar() {
    if ((int.tryParse(_monto) ?? 0) <= 0) {
      setState(() => _error = 'Escribe la cantidad');
      return;
    }
    final engine = context.read<AppEngineService>();
    final previo = widget.existente;
    final g = Gasto(
      id: previo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: previo?.fecha ?? fechaKey(hoy()),
      descripcion: _categoria!,
      categoria: _categoria!,
      monto: double.parse(_monto),
      equipoId: previo?.equipoId ?? widget.equipoId,
    );
    engine.saveGasto(g);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PantallaListo(
        titulo: previo == null ? 'Guardado' : 'Gasto corregido',
        mensaje: '${dinero(g.monto)} en ${g.categoria.toLowerCase()}',
        onCorregir: (ctx) => Navigator.of(ctx).pushReplacement(MaterialPageRoute(
          builder: (_) => NuevoGastoScreen(equipoId: g.equipoId, existente: g),
        )),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return EncargadoPage(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _atras();
        },
        child: Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: _categoria == null
                  ? [
                      Encabezado(
                        titulo: '¿En qué gastaste?',
                        paso: widget.existente != null ? 'Corrigiendo gasto' : null,
                        onAtras: _atras,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          for (final c in categoriasGasto)
                            BotonGrande(
                              texto: c.$1,
                              icono: c.$2,
                              vertical: true,
                              seleccionado: _ultimaCategoria == c.$1,
                              onTap: () => setState(() => _categoria = _ultimaCategoria = c.$1),
                            ),
                        ],
                      ),
                    ]
                  : [
                      Encabezado(
                        titulo: '¿Cuánto gastaste en ${_categoria!.toLowerCase()}?',
                        paso: widget.existente != null ? 'Corrigiendo gasto' : null,
                        onAtras: _atras,
                      ),
                      if (widget.existente != null)
                        const Text('Para cambiar la categoría, toca la flecha de atrás.',
                            style: TextStyle(fontSize: 17, color: EC.textoSuave)),
                      const SizedBox(height: 12),
                      TecladoMonto(
                        valor: _monto,
                        onChanged: (v) => setState(() {
                          _monto = v;
                          _error = null;
                        }),
                      ),
                      TextoError(_error),
                      const SizedBox(height: 20),
                      BotonGrande(texto: 'Guardar gasto', icono: Icons.check, estilo: EstiloBoton.primario, onTap: _guardar),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
