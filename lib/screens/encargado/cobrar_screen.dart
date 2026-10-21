import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/visita_agenda.dart';
import '../../services/app_engine_service.dart';
import 'ui.dart';

/// Cobrar un trabajo (monto → forma de pago) o registrar una venta rápida
/// sin cita (cliente → precio → forma de pago) cuando [trabajo] es null.
/// Con [corregirVenta], [trabajo] es una venta rápida ya guardada que se corrige con sus datos escritos.
class CobrarScreen extends StatefulWidget {
  final String equipoId;
  final VisitaAgenda? trabajo;
  final bool cambiarCobro;
  final bool corregirVenta;

  const CobrarScreen({
    super.key,
    required this.equipoId,
    this.trabajo,
    this.cambiarCobro = false,
    this.corregirVenta = false,
  });

  @override
  State<CobrarScreen> createState() => _CobrarScreenState();
}

enum _Paso { cliente, monto, forma }

class _CobrarScreenState extends State<CobrarScreen> {
  final _cliente = TextEditingController();
  final _queVendio = TextEditingController();
  late _Paso _paso;
  String _monto = '';
  String? _error;

  bool get _rapida => widget.trabajo == null || widget.corregirVenta;
  String? get _pasoTexto =>
      !_rapida ? null : widget.corregirVenta ? 'Corrigiendo venta · ${_paso.index + 1} de 3' : 'Venta rápida · ${_paso.index + 1} de 3';

  /// Forma de pago ya guardada (se marca al corregir), o null.
  String? get _metodoGuardado => widget.cambiarCobro || widget.corregirVenta ? widget.trabajo?.metodoPago.toLowerCase() : null;

  @override
  void initState() {
    super.initState();
    _paso = _rapida ? _Paso.cliente : _Paso.monto;
    final t = widget.trabajo;
    if (t != null) {
      final inicial = widget.cambiarCobro || widget.corregirVenta ? t.monto : t.montoEstimado;
      if (inicial > 0) _monto = inicial.round().toString();
      if (widget.corregirVenta) {
        _cliente.text = t.cliente;
        _queVendio.text = t.notas;
      }
    }
  }

  @override
  void dispose() {
    _cliente.dispose();
    _queVendio.dispose();
    super.dispose();
  }

  void _atras() {
    final inicio = _rapida ? _Paso.cliente : _Paso.monto;
    if (_paso == inicio) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _paso = _Paso.values[_paso.index - 1];
        _error = null;
      });
    }
  }

  void _guardar(String metodo) {
    final engine = context.read<AppEngineService>();
    final monto = double.parse(_monto);
    final formaTxt = metodo == 'transferencia' ? 'transferencia' : 'efectivo';

    if (_rapida) {
      final ahora = DateTime.now();
      // Al corregir se conserva la misma venta (fecha y hora originales); si no, se crea una nueva.
      final v = (widget.corregirVenta ? widget.trabajo!.copia() : null) ??
          VisitaAgenda(
            id: ahora.millisecondsSinceEpoch.toString(),
            cliente: '',
            fecha: fechaKey(ahora),
            hora: VisitaAgenda.horaDeMinutos(ahora.hour * 60 + ahora.minute),
            tipo: 'Venta',
            direccion: '',
            telefono: '',
            notas: '',
            estado: 'completado',
            equipoId: widget.equipoId,
            duracionMin: 30,
          );
      v
        ..cliente = _cliente.text.trim()
        ..notas = _queVendio.text.trim()
        ..monto = monto
        ..metodoPago = metodo;
      engine.saveVisitaAgenda(v);
      _terminar(
        widget.corregirVenta ? 'Venta corregida' : 'Venta guardada',
        'Venta de ${dinero(monto)} a ${v.cliente}\nen $formaTxt',
        (ctx) => CobrarScreen(equipoId: v.equipoId, trabajo: v, corregirVenta: true),
      );
      return;
    }

    final actualizado = widget.trabajo!.copia()
      ..estado = 'completado'
      ..monto = monto
      ..metodoPago = metodo;
    engine.saveVisitaAgenda(actualizado);
    _terminar(
      widget.cambiarCobro ? 'Cobro cambiado' : 'Cobrado',
      '${dinero(monto)} en $formaTxt\n${actualizado.cliente}',
      (ctx) => CobrarScreen(equipoId: actualizado.equipoId, trabajo: actualizado, cambiarCobro: true),
    );
  }

  /// Muestra "Guardado" con la opción de corregir: reabre esta pantalla con los datos ya escritos.
  void _terminar(String titulo, String mensaje, Widget Function(BuildContext) pantallaCorregir) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PantallaListo(
        titulo: titulo,
        mensaje: mensaje,
        onCorregir: (ctx) => Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: pantallaCorregir)),
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
              children: switch (_paso) {
                _Paso.cliente => _pasoCliente(),
                _Paso.monto => _pasoMonto(),
                _Paso.forma => _pasoForma(),
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _pasoCliente() => [
        Encabezado(titulo: '¿A quién le vendiste?', paso: _pasoTexto, onAtras: _atras),
        const SizedBox(height: 16),
        CampoGrande(
          etiqueta: 'Nombre del cliente',
          controller: _cliente,
          ejemplo: 'Ana Pech',
          mayusculas: TextCapitalization.words,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        TextoError(_error),
        const SizedBox(height: 18),
        CampoGrande(etiqueta: '¿Qué vendiste?', opcional: '(opcional)', controller: _queVendio, ejemplo: 'Control remoto'),
        const SizedBox(height: 24),
        BotonGrande(
          texto: 'Siguiente',
          icono: Icons.arrow_forward,
          estilo: EstiloBoton.primario,
          onTap: () {
            if (_cliente.text.trim().isEmpty) {
              setState(() => _error = 'Escribe el nombre del cliente');
              return;
            }
            setState(() => _paso = _Paso.monto);
          },
        ),
      ];

  List<Widget> _pasoMonto() {
    final t = widget.trabajo;
    final esVenta = _rapida || (t?.esVenta ?? false);
    final titulo = esVenta ? '¿En cuánto se lo vendiste?' : '¿Cuánto te pagó ${t!.cliente.split(' ').first}?';
    final prellenado = t != null && !widget.cambiarCobro && !widget.corregirVenta && t.montoEstimado > 0;
    return [
      Encabezado(titulo: titulo, paso: _pasoTexto, onAtras: _atras),
      if (prellenado)
        const Text('Ya pusimos lo que agendaste. Cámbialo si cobraste otra cantidad.',
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
      BotonGrande(
        texto: 'Siguiente',
        icono: Icons.arrow_forward,
        estilo: EstiloBoton.primario,
        onTap: () {
          if ((int.tryParse(_monto) ?? 0) <= 0) {
            setState(() => _error = 'Escribe la cantidad');
            return;
          }
          setState(() => _paso = _Paso.forma);
        },
      ),
    ];
  }

  List<Widget> _pasoForma() => [
        Encabezado(titulo: '¿Cómo te pagó?', paso: _pasoTexto, onAtras: _atras),
        const SizedBox(height: 6),
        Text(dinero(int.parse(_monto)), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: EC.texto)),
        const SizedBox(height: 18),
        BotonGrande(
          texto: 'Efectivo',
          icono: Icons.payments_outlined,
          vertical: true,
          fontSize: 26,
          alto: 124,
          seleccionado: _metodoGuardado != null && _metodoGuardado != 'transferencia',
          onTap: () => _guardar('efectivo'),
        ),
        const SizedBox(height: 14),
        BotonGrande(
          texto: 'Transferencia',
          icono: Icons.account_balance_outlined,
          vertical: true,
          fontSize: 26,
          alto: 124,
          seleccionado: _metodoGuardado == 'transferencia',
          onTap: () => _guardar('transferencia'),
        ),
      ];
}
